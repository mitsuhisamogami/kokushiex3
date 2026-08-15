import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tab"
export default class extends Controller {
  static targets = ["year", "tag", "yearButton", "tagButton"]
  connect() {
    console.log("Tab_Controller connected")
    console.log(this.element)
  }

  switchingExamTypes() {
    this.yearTarget.classList.toggle('hidden');
    this.tagTarget.classList.toggle('hidden');
    this.syncActiveButton();
  }

  showYearTypes() {
    this.yearTarget.classList.remove('hidden');
    this.tagTarget.classList.add('hidden');
    this.activateButton(this.yearButtonTarget);
    this.deactivateButton(this.tagButtonTarget);
  }

  showTagTypes() {
    this.yearTarget.classList.add('hidden');
    this.tagTarget.classList.remove('hidden');
    this.activateButton(this.tagButtonTarget);
    this.deactivateButton(this.yearButtonTarget);
  }

  activateButton(button) {
    button.classList.add('bg-blue-950', 'text-white', 'border-blue-950');
    button.classList.remove('bg-slate-100', 'text-slate-700', 'border-slate-200');
  }

  deactivateButton(button) {
    button.classList.add('bg-slate-100', 'text-slate-700', 'border-slate-200');
    button.classList.remove('bg-blue-950', 'text-white', 'border-blue-950');
  }

  syncActiveButton() {
    if (this.yearTarget.classList.contains('hidden')) {
      this.activateButton(this.tagButtonTarget);
      this.deactivateButton(this.yearButtonTarget);
    } else {
      this.activateButton(this.yearButtonTarget);
      this.deactivateButton(this.tagButtonTarget);
    }
  }
}
