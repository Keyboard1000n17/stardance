import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "tooltip" ];
  static values = { text: String };

  copy(event) {
    event.preventDefault();
    const text = this.textValue;

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard
        .writeText(text)
        .then(() => this.#showCopied())
        .catch(() => {
          this.#fallback(text);
          this.#showCopied();
        });
    } else {
      this.#fallback(text);
      this.#showCopied();
    }
  }

  #showCopied() {
    if (this.hasTooltipTarget) {
      const originalText = this.tooltipTarget.textContent;
      this.tooltipTarget.textContent = "Copied!";
      setTimeout(() => {
        this.tooltipTarget.textContent = originalText;
      }, 1500);
    }
  }

  #fallback(text) {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.cssText = "position:fixed;opacity:0";
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    ta.remove();
  }
}
