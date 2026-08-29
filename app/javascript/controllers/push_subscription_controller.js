import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-subscription"
//
// Three things have to line up before this switch means anything: a service
// worker, a granted permission, and a subscription the server can encrypt to.
// The switch owns all three, so the row can never read "on" while the browser
// has revoked the permission behind it.
export default class PushSubscriptionController extends Controller {
  static targets = ["knob", "track", "status"]
  static values = { vapidKey: String, url: String, preferencesUrl: String }

  connect() {
    this.sync()
  }

  async sync() {
    if (!this.supported) return this.block(this.installable ? "installable" : "unsupported")
    if (Notification.permission === "denied") return this.block("denied")

    const registration = await navigator.serviceWorker.ready
    this.render(Boolean(await registration.pushManager.getSubscription()))
  }

  async toggle() {
    if (this.blocked) return

    const turningOn = !this.trackTarget.classList.contains("bg-primary")
    this.render(turningOn)

    try {
      await (turningOn ? this.subscribe() : this.unsubscribe())
      await this.persistPreference(turningOn)
    } catch (_error) {
      this.render(!turningOn)
      if (Notification.permission === "denied") this.block("denied")
    }
  }

  async subscribe() {
    if (await Notification.requestPermission() !== "granted") throw new Error("permission")

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: decodeKey(this.vapidKeyValue)
    })

    await this.send(this.urlValue, "POST", {
      push_subscription: {
        endpoint: subscription.endpoint,
        p256dh_key: encodeKey(subscription.getKey("p256dh")),
        auth_key: encodeKey(subscription.getKey("auth"))
      }
    })
  }

  async unsubscribe() {
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.getSubscription()
    if (!subscription) return

    await subscription.unsubscribe()
    await this.send(this.urlValue, "DELETE", { endpoint: subscription.endpoint })
    navigator.clearAppBadge?.()
  }

  persistPreference(enabled) {
    return this.send(this.preferencesUrlValue, "PATCH", { push: enabled })
  }

  async send(url, method, body) {
    const response = await fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content,
        "Accept": "application/json"
      },
      body: JSON.stringify(body)
    })

    if (!response.ok) throw new Error(response.status)
    return response
  }

  block(reason) {
    this.blocked = true
    this.render(false)
    this.statusTarget.textContent = this.statusTarget.dataset[reason]
    this.statusTarget.hidden = false
  }

  render(on) {
    this.trackTarget.classList.toggle("bg-primary", on)
    this.trackTarget.classList.toggle("bg-bg-muted", !on)
    this.knobTarget.classList.toggle("translate-x-5", on)
    this.knobTarget.classList.toggle("translate-x-0", !on)
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in globalThis && "Notification" in globalThis
  }

  // iOS hands PushManager to an installed app and to nothing else, so the same
  // missing API means "add it to your home screen" there and "this browser
  // cannot" everywhere else. Saying which is the whole point — the channel
  // failing silently on the primary device is what closed this idea before.
  get installable() {
    return !globalThis.matchMedia("(display-mode: standalone)").matches && !navigator.standalone
  }
}

// The VAPID key travels as base64url and the browser wants raw bytes.
function decodeKey(base64url) {
  const padded = base64url.replace(/-/g, "+").replace(/_/g, "/").padEnd(
    base64url.length + (4 - base64url.length % 4) % 4, "="
  )
  return Uint8Array.from(atob(padded), (char) => char.charCodeAt(0))
}

function encodeKey(buffer) {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}
