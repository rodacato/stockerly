module ApplicationHelper
  def app_nav_active?(path)
    current_page?(path) ? "text-primary bg-primary/10" : "text-slate-600 dark:text-slate-300 hover:text-primary hover:bg-slate-50 dark:hover:bg-slate-800"
  end
end
