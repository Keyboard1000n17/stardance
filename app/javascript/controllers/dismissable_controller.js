import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { cookie: String };

  dismiss() {
    if (this.cookieValue) {
      document.cookie = `${this.cookieValue}=1; path=/; max-age=${60 * 60 * 24 * 365}`;
    }
    this.element.remove();
  }
}
