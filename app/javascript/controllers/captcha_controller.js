import { Controller } from "@hotwired/stimulus"

// Login CAPTCHA: "New image" loads a fresh challenge (which replaces the old one on the server).
//
//   <div data-controller="captcha" data-captcha-url-value="/login/captcha">
//     <img data-captcha-target="image">
//     <button data-action="captcha#refresh">New image</button>
//     <input data-captcha-target="input">
//   </div>
export default class extends Controller {
  static targets = ["image", "input"]
  static values = { url: String }

  refresh() {
    // A unique query string stops the browser from reusing the cached image
    this.imageTarget.src = `${this.urlValue}?v=${Date.now()}`
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}
