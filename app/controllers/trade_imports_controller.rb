class TradeImportsController < AuthenticatedController
  # Two steps, one form. `preview` runs the importer with dry_run so the batch
  # can be refused or counted without writing; `create` runs the same rows for
  # real. The CSV rides along in a hidden field rather than the session — the
  # batch is a few KB and a stateless confirm cannot go stale.
  def new
  end

  def preview
    return render :new, status: :unprocessable_content if rows.blank?

    case Trading::UseCases::ImportTrades.call(user: current_user, rows: rows, dry_run: true, skip_unknown: skip_unknown?)
    in Dry::Monads::Success(report)
      @report = report
      render :preview
    in Dry::Monads::Failure[ reason, details ]
      @reason = reason
      @details = details
      @catalogued = catalogued(details)
      @blocked_rows, @importable_rows = split_by_symbol(details)
      render :preview, status: :unprocessable_content
    end
  end

  def create
    return redirect_to new_trade_import_path, alert: t(".vacio") if rows.blank?

    case Trading::UseCases::ImportTrades.call(user: current_user, rows: rows, dry_run: false, skip_unknown: skip_unknown?)
    in Dry::Monads::Success(report)
      redirect_to portfolio_path, notice: t(".listo", count: report[:imported])
    in Dry::Monads::Failure[ _reason, _details ]
      redirect_to new_trade_import_path, alert: t(".rechazado")
    end
  end

  # Adding the catalogue entries the file needs, so the same file can be
  # imported on the next pass. It redirects back to the picker rather than
  # re-previewing: the provider half lands asynchronously, so a preview run now
  # would report symbols that are still on their way.
  def track_missing
    case Administration::UseCases::Assets::TrackMissingSymbols.call(
      symbols: params[:symbols], user: current_user,
      renames: params[:renames]&.to_unsafe_h || {}, delisted: params[:delisted] || []
    )
    in Dry::Monads::Success(report)
      redirect_to new_trade_import_path, notice: alta_notice(report)
    in Dry::Monads::Failure
      redirect_to new_trade_import_path, alert: t(".ninguno")
    end
  end

  private

  # Which of the missing symbols the bundled catalogue already describes. The
  # row says so because the two halves cost differently: one is free, the other
  # spends a provider call and may not come back with anything.
  # Opt-in, and it has to survive the confirm step: the preview that showed
  # what would be dropped and the commit that drops it must agree.
  # How much of the file the refusal is actually holding, so the offer to
  # import the rest can name a number instead of a promise.
  def split_by_symbol(details)
    unknown = Array(details).map(&:upcase).to_set
    blocked = rows.count { |row| unknown.include?(row[:asset_symbol].to_s.upcase) }

    [ blocked, rows.size - blocked ]
  end

  def skip_unknown?
    params[:skip_unknown].present?
  end

  def catalogued(details)
    Administration::Domain::AssetCatalog.find_by_symbols(Array(details)).pluck(:symbol).to_set
  end

  # Full keys, not lazy lookups: this is a helper, and a lazy key here resolves
  # against the method name rather than the action that called it.
  def alta_notice(report)
    created = report[:created].size
    pending = report[:pending].size
    return t("trade_imports.track_missing.alta_en_camino", count: created, pending: pending) if pending.positive?

    t("trade_imports.track_missing.alta", count: created)
  end

  # An uploaded file arrives as ASCII-8BIT, so every symbol parsed out of it is
  # a binary string -- and binary is what String#parameterize refuses to
  # transliterate. Pasted text is already UTF-8, which is why only uploads
  # broke. scrub keeps a file with one bad byte from taking the whole batch.
  def decode(text)
    text.force_encoding(Encoding::UTF_8).scrub
  end

  def rows
    @rows ||= Trading::Domain::CsvRows.call(text: csv_text)
  rescue Trading::Domain::CsvRows::MissingHeader => e
    @error = e.message
    []
  end

  # Held on the instance because the preview renders it back into a hidden
  # field: an upload has no params to resubmit, so the confirm step would
  # otherwise have nothing to import.
  def csv_text
    @csv_text ||= begin
      uploaded = params[:archivo]
      uploaded.respond_to?(:read) ? decode(uploaded.read) : params[:contenido].to_s
    end
  end
end
