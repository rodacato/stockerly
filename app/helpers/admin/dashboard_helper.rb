module Admin
  module DashboardHelper
    MOD_LABELS = {
      "sync"         => "Sincronización",
      "integrations" => "Integraciones",
      "auth"         => "Autenticación",
      "users"        => "Usuarios",
      "invitations"  => "Invitaciones",
      "system"       => "Sistema",
      "admin"        => "Administración",
      "alerts"       => "Alertas"
    }.freeze

    # "21 MAY 2026 · 14:32" — absolute, mono-friendly.
    def admin_absolute_ts(time)
      return "—" unless time
      t = time.in_time_zone("America/Mexico_City")
      "#{t.day.to_s.rjust(2, '0')} #{DatetimeEsHelper::MONTHS_ES[t.month - 1]} #{t.year} · #{t.strftime('%H:%M')}"
    end

    # "hace 12 min" / "hace 2 h" / "hace 3 d" — relative, lower-case.
    def admin_relative_ts(time)
      return "nunca" unless time
      seconds = (Time.current - time).to_i
      return "hace #{seconds} s" if seconds < 60
      return "hace #{seconds / 60} min" if seconds < 3600
      return "hace #{seconds / 3600} h" if seconds < 86_400
      "hace #{seconds / 86_400} d"
    end

    def admin_module_label(mod)
      MOD_LABELS[mod.to_s] || mod.to_s
    end

    def admin_severity_dot_class(sev)
      case sev.to_s
      when "error" then "bg-rose-500 ring-2 ring-rose-500/20"
      when "warning" then "bg-amber-500 ring-2 ring-amber-500/20"
      else "bg-slate-400/70"
      end
    end

    # Returns { fg:, bg:, label: } classes for a data-source status pill.
    def admin_source_state_pill(state)
      case state.to_s
      when "active"
        { fg: "text-emerald-700 dark:text-emerald-400", bg: "bg-emerald-500/15", label: "Activa" }
      when "error"
        { fg: "text-rose-700 dark:text-rose-400",       bg: "bg-rose-500/15",    label: "Error" }
      when "paused"
        { fg: "text-slate-500 dark:text-slate-400",     bg: "bg-slate-200/60 dark:bg-slate-700/50", label: "Pausada" }
      when "stale"
        { fg: "text-amber-700 dark:text-amber-400",     bg: "bg-amber-500/15",   label: "Sin respuesta" }
      else
        { fg: "text-slate-500 dark:text-slate-400",     bg: "bg-slate-200/60 dark:bg-slate-700/50", label: "Sin sincronizar" }
      end
    end

    # Maps an Integration#connection_status to a source-state symbol used by
    # the dashboard source-card grid.
    def admin_integration_state(integration, sync_status: nil)
      return :paused if integration.respond_to?(:enabled?) && integration.respond_to?(:enabled) && integration.enabled == false
      case integration.connection_status
      when "connected" then sync_status == :stale ? :stale : :active
      when "syncing"   then :active
      when "disconnected" then :error
      else :stale
      end
    end
  end
end
