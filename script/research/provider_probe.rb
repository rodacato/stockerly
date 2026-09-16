#!/usr/bin/env ruby
# frozen_string_literal: true

# Read-only probes that establish what a provider actually serves — the
# exception ADR-027 carves out of "production is the only instance that spends
# quota". Credentials come from .env or the shell and are redacted from every
# recorded request and response. Output lands in tmp/probes/.
#
#   ruby script/research/provider_probe.rb alpaca

require "net/http"
require "json"
require "uri"
require "time"
require "fileutils"

ROOT = File.expand_path("../..", __dir__)
OUT_DIR = File.join(ROOT, "tmp/probes")

def load_dotenv
  path = File.join(ROOT, ".env")
  return unless File.exist?(path)

  File.readlines(path).each do |line|
    next if line.strip.empty? || line.strip.start_with?("#")
    key, value = line.split("=", 2)
    next if key.nil? || value.nil?
    ENV[key.strip] ||= value.strip.gsub(/\A["']|["']\z/, "")
  end
end

load_dotenv

SECRETS = ENV.values_at("ALPACA_KEY_ID", "ALPACA_SECRET_KEY", "DATABURSATIL_TOKEN").compact.reject(&:empty?)

def redact(text)
  SECRETS.reduce(text.to_s) { |acc, secret| acc.gsub(secret, "«REDACTED»") }
end

def require_env(*names)
  missing = names.reject { |n| ENV[n].to_s.strip.length.positive? }
  return if missing.empty?

  abort "Missing env: #{missing.join(', ')}\nSet them in .env (gitignored) or export them, then re-run."
end

Probe = Struct.new(:name, :question, :url, :headers, keyword_init: true)

def run(probe)
  uri = URI(probe.url)
  request = Net::HTTP::Get.new(uri)
  (probe.headers || {}).each { |k, v| request[k] = v }
  request["Accept"] = "application/json"
  request["User-Agent"] = "stockerly-probe/1.0"

  started = Time.zone.now
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", read_timeout: 20) do |http|
    http.request(request)
  end

  body = response.body.to_s
  {
    name: probe.name,
    question: probe.question,
    url: redact(probe.url),
    status: response.code.to_i,
    elapsed_ms: ((Time.zone.now - started) * 1000).round,
    body_bytes: body.bytesize,
    notable_headers: response.each_header.to_h.select { |k, _| k.downcase.match?(/ratelimit|retry-after|x-request-id/) },
    body_sample: redact(body[0, 1500])
  }
rescue StandardError => e
  { name: probe.name, question: probe.question, url: redact(probe.url), error: "#{e.class}: #{redact(e.message)}" }
end

# Verified against docs.alpaca.markets 2026-08-26: feed defaults to `sip`, and
# a Basic key gets SIP delayed by 15 minutes rather than a different venue.
def alpaca_probes
  require_env("ALPACA_KEY_ID", "ALPACA_SECRET_KEY")

  auth = { "APCA-API-KEY-ID" => ENV["ALPACA_KEY_ID"], "APCA-API-SECRET-KEY" => ENV["ALPACA_SECRET_KEY"] }
  host = "https://data.alpaca.markets"
  window_end = (Time.now.utc - (2 * 86_400)).strftime("%Y-%m-%d")
  window_start = (Time.now.utc - (10 * 86_400)).strftime("%Y-%m-%d")

  [
    Probe.new(name: "bars_daily_sip", question: "Does a Basic key get consolidated daily bars for several symbols in one call?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL,MSFT,NVDA&timeframe=1Day&start=#{window_start}&end=#{window_end}&feed=sip&limit=1000", headers: auth),
    Probe.new(name: "bars_daily_no_feed", question: "Docs say feed already defaults to sip. Identical payload to bars_daily_sip, or not?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL,MSFT,NVDA&timeframe=1Day&start=#{window_start}&end=#{window_end}&limit=1000", headers: auth),
    Probe.new(name: "bars_daily_iex", question: "The IEX venue: does the response say which feed served it?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL,MSFT,NVDA&timeframe=1Day&start=#{window_start}&end=#{window_end}&feed=iex&limit=1000", headers: auth),
    Probe.new(name: "bars_inside_15min_wall", question: "The last 10 minutes, inside the 15-minute wall: error, empty array, or clamped data?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL&timeframe=1Min&start=#{(Time.now.utc - 600).iso8601}&end=#{Time.now.utc.iso8601}&feed=sip", headers: auth),
    Probe.new(name: "bars_split_raw", question: "AAPL 4:1 split of 2020-08-31, unadjusted (adjustment defaults to raw).",
              url: "#{host}/v2/stocks/bars?symbols=AAPL&timeframe=1Day&start=2020-08-26&end=2020-09-03&feed=sip", headers: auth),
    Probe.new(name: "bars_split_adjusted", question: "Same window with adjustment=all — does Alpaca hand us adjusted series natively?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL&timeframe=1Day&start=2020-08-26&end=2020-09-03&feed=sip&adjustment=all", headers: auth),
    Probe.new(name: "bars_pagination", question: "Does limit=2 across 3 symbols return a next_page_token?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL,MSFT,NVDA&timeframe=1Day&start=#{window_start}&end=#{window_end}&feed=sip&limit=2", headers: auth),
    Probe.new(name: "latest_bar", question: "Is there ANY current-price path for a Basic key, or is 15-min-delayed the floor?",
              url: "#{host}/v2/stocks/AAPL/bars/latest?feed=sip", headers: auth),
    Probe.new(name: "snapshots", question: "Same question via snapshots — 403, or delayed data?",
              url: "#{host}/v2/stocks/snapshots?symbols=AAPL&feed=sip", headers: auth),
    Probe.new(name: "news", question: "Is news free on Basic?",
              url: "#{host}/v1beta1/news?symbols=AAPL&limit=5", headers: auth),
    Probe.new(name: "corporate_actions", question: "Are dividends and splits free on Basic?",
              url: "#{host}/v1/corporate-actions?symbols=AAPL&types=cash_dividend,forward_split&start=2020-01-01&end=#{window_end}&limit=50", headers: auth),
    Probe.new(name: "history_2016", question: "Does history really reach 2016?",
              url: "#{host}/v2/stocks/bars?symbols=AAPL&timeframe=1Day&start=2016-01-04&end=2016-01-08&feed=sip", headers: auth),
    Probe.new(name: "mx_walmex", question: "Confirm zero BMV coverage rather than assuming it.",
              url: "#{host}/v2/stocks/bars?symbols=WALMEX,WALMEX.MX&timeframe=1Day&start=#{window_start}&end=#{window_end}&feed=sip", headers: auth),
    Probe.new(name: "index_spx", question: "Confirm indices are absent.",
              url: "#{host}/v2/stocks/bars?symbols=SPX,SPY&timeframe=1Day&start=#{window_start}&end=#{window_end}&feed=sip", headers: auth)
  ]
end

# The corporate-actions sample above truncates before forward_splits.
def alpaca_splits_probes
  require_env("ALPACA_KEY_ID", "ALPACA_SECRET_KEY")
  auth = { "APCA-API-KEY-ID" => ENV["ALPACA_KEY_ID"], "APCA-API-SECRET-KEY" => ENV["ALPACA_SECRET_KEY"] }
  host = "https://data.alpaca.markets"

  [
    Probe.new(name: "splits_aapl", question: "AAPL 4:1 of 2020-08-31 — what are the split fields called?",
              url: "#{host}/v1/corporate-actions?symbols=AAPL&types=forward_split&start=2020-01-01&end=2021-01-01", headers: auth),
    Probe.new(name: "splits_nvda", question: "NVDA 10:1 of 2024-06-10 — confirm the shape holds on a second issuer.",
              url: "#{host}/v1/corporate-actions?symbols=NVDA&types=forward_split&start=2024-01-01&end=2025-01-01", headers: auth)
  ]
end

# Auth is ?token= only (header auth is rejected); `concepto` picks the fields,
# so payload size — and credit cost — is the caller's to choose.
DB_BASE = "https://api.databursatil.com"
DB_CONCEPTO_ALL = "u,p,a,x,n,c,m,v,o,i,f"

def databursatil_discovery_probes
  require_env("DATABURSATIL_TOKEN")
  token = ENV["DATABURSATIL_TOKEN"]

  [
    Probe.new(name: "auth_query_token", question: "Confirm ?token= is the accepted auth shape.",
              url: "#{DB_BASE}/v2/cotizaciones?token=#{token}&concepto=u&emisora_serie=GFNORTEO&bolsa=BMV", headers: {}),
    Probe.new(name: "auth_bad_token", question: "What does an INVALID token look like? Needed to tell auth failure from quota failure.",
              url: "#{DB_BASE}/v2/cotizaciones?token=invalid-on-purpose&concepto=u&emisora_serie=GFNORTEO&bolsa=BMV", headers: {})
  ]
end

# The unfiltered /v2/emisoras catalogue is 2.23 MB, ~2,181 credits in one call,
# so it is deliberately left out of every set.
def databursatil_probes
  require_env("DATABURSATIL_TOKEN")
  auth = "token=#{ENV['DATABURSATIL_TOKEN']}"

  [
    Probe.new(name: "creditos_check", question: "The remaining credit balance.",
              url: "#{DB_BASE}/v2/creditos?#{auth}", headers: {}),
    Probe.new(name: "intradia_fixed", question: "Five-minute intraday bars for one BMV issuer.",
              url: "#{DB_BASE}/v2/intradia?#{auth}&emisora_serie=GFNORTEO&bolsa=BMV&inicio=2026-08-25&final=2026-08-25&intervalo=5m", headers: {}),
    Probe.new(name: "historicos_concepto", question: "Does concepto unlock OHLC on daily history, or only [close, importe]?",
              url: "#{DB_BASE}/v2/historicos?#{auth}&emisora_serie=GFNORTEO&inicio=2026-08-01&final=2026-08-10&concepto=#{DB_CONCEPTO_ALL}", headers: {}),
    Probe.new(name: "financieros_emisora", question: "Statements keyed by emisora (GFNORTE), not by serie.",
              url: "#{DB_BASE}/v2/financieros?#{auth}&emisora=GFNORTE&periodo=1T_2026&financieros=posicion", headers: {}),
    Probe.new(name: "financieros_periodo_alt", question: "The same statements with the alternative period format.",
              url: "#{DB_BASE}/v2/financieros?#{auth}&emisora=GFNORTE&periodo=2026-1&financieros=posicion", headers: {}),
    Probe.new(name: "descargas_older", question: "Does the guber download (government bonds, CETES) serve a recent date?",
              url: "#{DB_BASE}/v2/descargas?#{auth}&archivo=guber&fecha=2026-08-20", headers: {}),
    Probe.new(name: "indices_freshness", question: "How fresh is the IPC the index feed returns?",
              url: "#{DB_BASE}/v2/indices?#{auth}", headers: {})
  ]
end

# Yahoo's symbol is WALMEX.MX, DataBursatil's is the BMV serie WALMEX*; whether
# the serie is optional decides the mapping.
def databursatil_symbol_probes
  require_env("DATABURSATIL_TOKEN")
  auth = "token=#{ENV['DATABURSATIL_TOKEN']}"

  [
    Probe.new(name: "serie_omitted", question: "Does WALMEX without its * serie resolve, or come back empty?",
              url: "#{DB_BASE}/v2/cotizaciones?#{auth}&concepto=u&emisora_serie=WALMEX&bolsa=BMV", headers: {}),
    Probe.new(name: "serie_present", question: "Control: the same issuer with its serie.",
              url: "#{DB_BASE}/v2/cotizaciones?#{auth}&concepto=u&emisora_serie=WALMEX*&bolsa=BMV", headers: {}),
    Probe.new(name: "serie_suffixed_issuer", question: "GFNORTEO already carries its serie in the ticker — does it behave the same?",
              url: "#{DB_BASE}/v2/cotizaciones?#{auth}&concepto=u&emisora_serie=GFNORTE&bolsa=BMV", headers: {}),
    Probe.new(name: "naftrac", question: "NAFTRAC tracks the IPC and would stand in for the index nobody serves.",
              url: "#{DB_BASE}/v2/cotizaciones?#{auth}&concepto=u,c,v,f&emisora_serie=NAFTRACISHRS&bolsa=BMV", headers: {})
  ]
end

def databursatil_catalog_probes
  require_env("DATABURSATIL_TOKEN")
  auth = "token=#{ENV['DATABURSATIL_TOKEN']}"

  [
    Probe.new(name: "emisoras_filter_emisora", question: "Does the catalogue accept &emisora=? If yes, 2,181 credits become ~1.",
              url: "#{DB_BASE}/v2/emisoras?#{auth}&emisora=GFNORTE", headers: {}),
    Probe.new(name: "emisoras_filter_serie", question: "Same question with the serie key.",
              url: "#{DB_BASE}/v2/emisoras?#{auth}&emisora_serie=GFNORTEO", headers: {}),
    Probe.new(name: "descargas_much_older", question: "guber for an older date, to tell recency from absence.",
              url: "#{DB_BASE}/v2/descargas?#{auth}&archivo=guber&fecha=2026-06-30", headers: {})
  ]
end

# A wide range costs many KiB, which separates "1 credit per request" from
# "1 credit per KiB" — the latter, rounded up, on 2026-08-26.
def databursatil_credits_probes
  require_env("DATABURSATIL_TOKEN")
  auth = "token=#{ENV['DATABURSATIL_TOKEN']}"

  [
    Probe.new(name: "credits_a", question: "Baseline.",
              url: "#{DB_BASE}/v2/creditos?#{auth}", headers: {}),
    Probe.new(name: "historicos_wide", question: "A year of daily closes — should be many KiB. Note its body_bytes.",
              url: "#{DB_BASE}/v2/historicos?#{auth}&emisora_serie=GFNORTEO&inicio=2025-08-01&final=2026-08-01", headers: {}),
    Probe.new(name: "credits_b", question: "DISCRIMINATOR: delta of ~2 means per-request. Delta near body_bytes/1024 means per-KiB.",
              url: "#{DB_BASE}/v2/creditos?#{auth}", headers: {})
  ]
end

target = ARGV[0]
probes =
  case target
  when "alpaca" then alpaca_probes
  when "alpaca-splits" then alpaca_splits_probes
  when "databursatil-discover" then databursatil_discovery_probes
  when "databursatil" then databursatil_probes
  when "databursatil-credits" then databursatil_credits_probes
  when "databursatil-catalog" then databursatil_catalog_probes
  when "databursatil-symbols" then databursatil_symbol_probes
  else abort "Usage: ruby script/research/provider_probe.rb [alpaca|alpaca-splits|databursatil-discover|databursatil|databursatil-credits|databursatil-catalog|databursatil-symbols]"
  end

results = probes.map do |probe|
  result = run(probe)
  status = result[:error] ? "ERR" : result[:status]
  puts format("%-26s %-4s %8s bytes  %s", probe.name, status, result[:body_bytes] || "-", result[:question])
  sleep 0.4
  result
end

path = File.join(OUT_DIR, "#{target}-#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}.json")
FileUtils.mkdir_p(OUT_DIR)
File.write(path, JSON.pretty_generate(results))
puts "\nWrote #{path}"
puts "Secrets redacted: #{SECRETS.any? ? 'yes' : 'NONE FOUND — check the output before sharing'}"
