import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  scroll(event) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
