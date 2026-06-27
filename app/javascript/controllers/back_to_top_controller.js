import { Controller } from "@hotwired/stimulus"

export default class BackToTopController extends Controller {
  scroll(event) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
