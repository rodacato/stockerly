class TradeImportsController < AuthenticatedController
  # Two steps, one form. `preview` runs the importer with dry_run so the batch
  # can be refused or counted without writing; `create` runs the same rows for
  # real. The CSV rides along in a hidden field rather than the session — the
  # batch is a few KB and a stateless confirm cannot go stale.
  def new
  end

  def preview
    return render :new, status: :unprocessable_content if rows.blank?

    case Trading::UseCases::ImportTrades.call(user: current_user, rows: rows, dry_run: true)
    in Dry::Monads::Success(report)
      @report = report
      render :preview
    in Dry::Monads::Failure[ reason, details ]
      @reason = reason
      @details = details
      render :preview, status: :unprocessable_content
    end
  end

  def create
    return redirect_to new_trade_import_path, alert: t(".vacio") if rows.blank?

    case Trading::UseCases::ImportTrades.call(user: current_user, rows: rows, dry_run: false)
    in Dry::Monads::Success(report)
      redirect_to portfolio_path, notice: t(".listo", count: report[:imported])
    in Dry::Monads::Failure[ _reason, _details ]
      redirect_to new_trade_import_path, alert: t(".rechazado")
    end
  end

  private

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
      uploaded.respond_to?(:read) ? uploaded.read : params[:contenido].to_s
    end
  end
end
