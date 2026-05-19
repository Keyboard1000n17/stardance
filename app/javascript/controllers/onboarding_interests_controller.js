import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submit"];

  connect() {
    this.refresh();
  }

  refresh() {
    if (!this.hasSubmitTarget) return;
    const anyChecked =
      this.element.querySelectorAll("input[type=checkbox]:checked").length > 0;
    this.submitTarget.disabled = !anyChecked;
    this.submitTarget.classList.toggle(
      "special-action-btn--disabled",
      !anyChecked,
    );
  }
}
