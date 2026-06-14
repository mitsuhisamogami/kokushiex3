import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="results-display"
export default class extends Controller {
  static targets = ["errata", "report", "tab"]

  connect() {
    this.currentPanel = "report"
    this.showCurrentPanel()
  }

  switch(event) {
    this.currentPanel = event.currentTarget.dataset.panel
    this.showCurrentPanel()
  }

  showCurrentPanel() {
    this.reportTarget.classList.toggle("hidden", this.currentPanel !== "report")
    this.errataTarget.classList.toggle("hidden", this.currentPanel !== "errata")
    this.updateTabs()
  }

  updateTabs() {
    this.tabTargets.forEach((tab) => {
      const selected = tab.dataset.panel === this.currentPanel

      tab.classList.toggle("border-blue-700", selected)
      tab.classList.toggle("text-blue-700", selected)
      tab.classList.toggle("border-transparent", !selected)
      tab.classList.toggle("text-gray-500", !selected)
    })
  }
}
