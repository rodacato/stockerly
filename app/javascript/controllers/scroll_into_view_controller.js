import { Controller } from "@hotwired/stimulus"

// A question appended below the fold would answer where nobody is looking.
export default class ScrollIntoViewController extends Controller {
  connect() {
    this.element.scrollIntoView({ block: "start", behavior: "smooth" })
  }
}
