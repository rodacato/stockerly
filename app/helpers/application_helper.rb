module ApplicationHelper
  include Pagy::Frontend

  def app_nav_active?(path)
    current_page?(path) ? "text-primary bg-primary/10" : "text-slate-600 dark:text-slate-300 hover:text-primary hover:bg-slate-50 dark:hover:bg-slate-800"
  end

  def admin_nav_active?(path)
    current_page?(path) ? "bg-primary text-white" : "text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800"
  end
end
