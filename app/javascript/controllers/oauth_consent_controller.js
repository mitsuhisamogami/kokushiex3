import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "button"]

  connect() {
    this.update()
  }

  update() {
    const enabled = this.checkboxTarget.checked

    this.buttonTargets.forEach((button) => {
      button.disabled = !enabled
      button.classList.toggle("cursor-not-allowed", !enabled)
      button.classList.toggle("opacity-50", !enabled)
    })
  }
}
