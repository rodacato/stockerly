module Admin
  module AssetsHelper
    ASSET_TYPE_LABELS = {
      "stock"        => "accion",
      "etf"          => "etf",
      "crypto"       => "cripto",
      "fixed_income" => "renta fija",
      "index"        => "indice"
    }.freeze

    # Cool-down windows for the "última sync" color coding, per mockup:
    # fresh < 2h, stale 2-24h (warning), cold > 24h (negative).
    STALE_AFTER = 2.hours
    COLD_AFTER  = 24.hours

    def admin_asset_type_label(asset)
      ASSET_TYPE_LABELS[asset.asset_type] || asset.asset_type
    end

    def admin_asset_status_key(asset)
      case asset.sync_status
      when "active"     then :active
      when "disabled"   then :paused
      when "sync_issue" then :error
      else                   :active
      end
    end

    def admin_asset_status_label(key)
      { active: "Activo", paused: "Pausado", error: "Error" }[key]
    end

    def admin_asset_status_pill_classes(key)
      {
        active: "bg-emerald-500/12 text-emerald-700 dark:text-emerald-300",
        paused: "bg-amber-500/14 text-amber-700 dark:text-amber-300",
        error:  "bg-rose-500/12 text-rose-700 dark:text-rose-300"
      }[key]
    end

    # Returns [text, color_classes] for the última-sync cell.
    def admin_asset_last_sync(asset)
      ts = asset.price_updated_at
      return [ "sin sincronizar", "text-amber-600 dark:text-amber-400 font-medium" ] if ts.nil?

      age = Time.current - ts
      label = humanize_age(age)

      tier_classes =
        if age >= COLD_AFTER
          "text-rose-600 dark:text-rose-400 font-medium"
        elsif age >= STALE_AFTER
          "text-amber-600 dark:text-amber-400 font-medium"
        else
          "text-slate-700 dark:text-slate-200"
        end

      [ label, tier_classes ]
    end

    # Lookup the last-failure tuple [message, timestamp] for an asset from a
    # pre-built hash keyed by symbol. The hash is computed once by ListAssets
    # so each page render runs at most one SQL query (no N+1).
    def admin_asset_last_failure_reason(asset, failure_reasons)
      return nil unless asset.sync_issue?
      failure_reasons[asset.symbol]
    end

    def admin_assets_filter_active?(key, slug, default: "todos")
      (params[key].presence || default) == slug
    end

    # Tailwind utility for the fallback badge — pulled from the existing
    # _asset_badge component so the admin table matches the user-facing
    # market list (#132).
    def admin_asset_badge_bg(asset)
      if asset.asset_type_crypto?
        "bg-amber-500 text-white"
      elsif asset.asset_type_etf?
        "bg-indigo-600 text-white"
      elsif asset.asset_type_fixed_income?
        "bg-teal-600 text-white"
      else
        "bg-slate-900 dark:bg-slate-700 text-white"
      end
    end

    private

    def humanize_age(seconds)
      s = seconds.to_i
      return "hace #{s} s"        if s < 60
      return "hace #{s / 60} min" if s < 3_600
      return "hace #{s / 3_600} h" if s < 86_400
      "hace #{s / 86_400} d"
    end
  end
end
