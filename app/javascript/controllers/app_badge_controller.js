import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="app-badge"
//
// Puts the unread count on the installed app's icon. Only the OS shows this,
// so a browser tab is a no-op — and clearing at zero matters as much as
// setting, or the badge outlives the notifications it counted.
export default class AppBadgeController extends Controller {
  static values = { count: Number }

  countValueChanged(count) {
    if (!("setAppBadge" in navigator)) return

    const applied = count > 0 ? navigator.setAppBadge(count) : navigator.clearAppBadge()
    applied?.catch(() => {})
  }
}
