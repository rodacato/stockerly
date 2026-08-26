# Records that one provider's number replaced another's on a row that already
# existed.
#
# ADR-016 stores only the winner, and accepts that on the condition that
# replacements are not silent: knowing how often sources disagree is the
# evidence that decides whether storing every opinion is worth it. Without this,
# that question can never be answered from the data.
module SourceChange
  def self.record(row, new_source)
    return if row.source.blank? || row.source == new_source

    SystemLog.create!(
      module_name: "sync",
      task_name: "Source change: #{row.class.name} #{row.date}",
      error_message: "#{row.source} → #{new_source}",
      severity: :warning
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid
    # Provenance bookkeeping must never break the write it observes
  end
end
