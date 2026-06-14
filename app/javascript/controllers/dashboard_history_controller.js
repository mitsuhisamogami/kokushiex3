import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dashboard-history"
export default class extends Controller {
  static targets = ["chart", "tab", "table"]

  connect() {
    this.currentPanel = "table"
    this.showCurrentPanel()
  }

  switch(event) {
    this.currentPanel = event.currentTarget.dataset.panel
    this.showCurrentPanel()
  }

  showCurrentPanel() {
    this.tableTarget.classList.toggle("hidden", this.currentPanel !== "table")
    this.chartTarget.classList.toggle("hidden", this.currentPanel !== "chart")
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
