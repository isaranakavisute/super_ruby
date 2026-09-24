import { Controller } from "@hotwired/stimulus"

// Shows or hides the text of a password field when the eye button is clicked.
//
//   <div data-controller="password-visibility">
//     <input type="password" data-password-visibility-target="input">
//     <button type="button" data-action="password-visibility#toggle">
//       <svg data-password-visibility-target="showIcon">…</svg>
//       <svg data-password-visibility-target="hideIcon" class="hidden">…</svg>
//     </button>
//   </div>
export default class extends Controller {
  static targets = ["input", "button", "showIcon", "hideIcon"]

  toggle() {
    const visible = this.inputTarget.type === "password"

    this.inputTarget.type = visible ? "text" : "password"
    this.showIconTarget.classList.toggle("hidden", visible)
    this.hideIconTarget.classList.toggle("hidden", !visible)
    this.buttonTarget.setAttribute("aria-pressed", visible)
    this.buttonTarget.setAttribute("aria-label", visible ? "Hide password" : "Show password")

    // Keep the cursor in the field so the user can carry on typing
    this.inputTarget.focus()
  }
}
