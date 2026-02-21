import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="calendar-nav"
export default class extends Controller {
  static targets = ["label"]
  static values = { months: Array }

  connect() {
    this.currentIndex = 0
    this.monthNames = this.hasMonthsValue ? this.monthsValue : [
      "January 2024", "February 2024", "March 2024", "April 2024",
      "May 2024", "June 2024", "July 2024", "August 2024",
      "September 2024", "October 2024", "November 2024", "December 2024"
    ]
  }

  previous() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.updateLabel()
    }
  }

  next() {
    if (this.currentIndex < this.monthNames.length - 1) {
      this.currentIndex++
      this.updateLabel()
    }
  }

  updateLabel() {
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.monthNames[this.currentIndex]
    }
  }
}
