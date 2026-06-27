import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
//
// Theme picker for /profile. Three modes:
//   - "light"  → force light (html *removes* the .dark class)
//   - "dark"   → force dark  (html *adds* the .dark class)
//   - "system" → follow prefers-color-scheme (default)
//
// Persists the choice under localStorage["stockerly.theme"]. The very
// early application.html.erb head script reads the same key on first
// paint so reloads don't FOUC. No server round-trip — theme is a pure
// client preference.
export default class ThemeController extends Controller {
  static targets = ["option"]
  static values = { storageKey: { type: String, default: "stockerly.theme" } }

  connect() {
    this.render(this.currentMode)
    this.mediaQuery = globalThis.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQueryListener = () => {
      if (this.currentMode === "system") this.applyMode("system")
    }
    this.mediaQuery.addEventListener("change", this.mediaQueryListener)
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.mediaQueryListener)
  }

  select(event) {
    const mode = event.currentTarget.dataset.themeMode
    if (!["light", "dark", "system"].includes(mode)) return
    localStorage.setItem(this.storageKeyValue, mode)
    this.render(mode)
  }

  render(mode) {
    this.applyMode(mode)
    this.optionTargets.forEach((opt) => {
      const isActive = opt.dataset.themeMode === mode
      opt.dataset.themeActive = isActive ? "true" : "false"
    })
  }

  applyMode(mode) {
    const wantsDark = mode === "dark" ||
      (mode === "system" && globalThis.matchMedia("(prefers-color-scheme: dark)").matches)
    document.documentElement.classList.toggle("dark", wantsDark)
  }

  get currentMode() {
    return localStorage.getItem(this.storageKeyValue) || "system"
  }
}
