import { Controller } from "@hotwired/stimulus"

// A question appended below the fold would answer where nobody is looking.
export default class ScrollIntoViewController extends Controller {
  connect() {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.element.scrollIntoView({ block: "start", behavior: reduce ? "auto" : "smooth" })
  }
}
