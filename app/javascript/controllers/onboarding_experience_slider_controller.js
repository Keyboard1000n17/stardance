import { Controller } from "@hotwired/stimulus";

const LEVELS = [
  {
    value: "none",
    title: "I'm new",
    description:
      "You've never really coded or built anything — and that's awesome! We'll start from the basics.",
  },
  {
    value: "little",
    title: "A little bit",
    description:
      "You've done some school stuff or followed a tutorial, but never built something on your own.",
  },
  {
    value: "some",
    title: "A project or two",
    description:
      "You've shipped something on your own :) We'll show you cool new stuff to try next.",
  },
  {
    value: "experienced",
    title: "Always building",
    description:
      "You're constantly making things. We'll connect you to deeper resources and harder challenges.",
  },
];

export default class extends Controller {
  static targets = ["slider", "hidden", "title", "description", "submit"];

  connect() {
    this._setSubmitEnabled(false);
    this._touched = false;
    this._startJiggle();
  }

  disconnect() {
    this._stopJiggle();
  }

  // Triggered by user input on the slider (drag, click, arrow keys).
  touch() {
    const idx = parseInt(this.sliderTarget.value, 10) || 0;
    const step = LEVELS[idx] || LEVELS[0];

    this.hiddenTarget.value = step.value;
    this.titleTarget.textContent = step.title;
    this.descriptionTarget.textContent = step.description;

    const ratio = idx / (LEVELS.length - 1);
    this.element.style.setProperty("--slider-fill", ratio);

    this._setSubmitEnabled(true);

    if (!this._touched) {
      this._touched = true;
      this._stopJiggle();
    }
  }

  _startJiggle() {
    const jiggle = () => {
      if (this._touched) return;
      this.sliderTarget.classList.remove("jiggle");
      void this.sliderTarget.offsetWidth;
      this.sliderTarget.classList.add("jiggle");
      this._jiggleTimer = setTimeout(jiggle, 1000 + Math.random() * 500);
    };
    jiggle();
  }

  _stopJiggle() {
    if (this._jiggleTimer) {
      clearTimeout(this._jiggleTimer);
      this._jiggleTimer = null;
    }
    this.sliderTarget.classList.remove("jiggle");
  }

  _setSubmitEnabled(enabled) {
    if (!this.hasSubmitTarget) return;
    this.submitTarget.disabled = !enabled;
    this.submitTarget.classList.toggle("action-btn--disabled", !enabled);
  }
}
