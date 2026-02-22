class SystemLog < ApplicationRecord
  enum :severity, { success: 0, error: 1, warning: 2 }

  validates :task_name,   presence: true
  validates :module_name, presence: true

  scope :recent,     -> { order(created_at: :desc) }
  scope :errors,     -> { where(severity: :error) }
  scope :last_24h,   -> { where("created_at >= ?", 24.hours.ago) }
  scope :by_module,  ->(mod) { where(module_name: mod) if mod.present? }
end
