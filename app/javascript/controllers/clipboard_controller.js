import { Controller } from "@hotwired/stimulus"

export default class ClipboardController extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()
    try {
      await navigator.clipboard.writeText(this.textValue)
    } catch (err) {
      console.error("Clipboard write failed", err)
    }
  }
}
