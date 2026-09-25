import { Controller } from "@hotwired/stimulus"

// Loads all accounts from the /user API and shows them in the Admin Panel table,
// with the last 3 characters of each password masked.
//
//   <div data-controller="admin-users" data-admin-users-url-value="/user">
//     <tbody data-admin-users-target="body"></tbody>
//     <p data-admin-users-target="status"></p>
//   </div>
export default class extends Controller {
  static targets = ["body", "status"]
  static values = { url: String }

  connect() {
    this.load()
  }

  async load() {
    this.showStatus("Loading users…")

    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`the server replied ${response.status}`)

      const users = await response.json()
      this.bodyTarget.replaceChildren(...users.map((user) => this.row(user)))
      this.showStatus(users.length === 0 ? "No users found." : `${users.length} users`)
    } catch (error) {
      this.bodyTarget.replaceChildren()
      this.showStatus(`Could not load users: ${error.message}`, true)
    }
  }

  // One <tr> per user. Values are set with textContent, so they are never interpreted as HTML.
  row(user) {
    const tr = document.createElement("tr")
    for (const value of [user.id, user.myuser, this.mask(user.mypassword)]) {
      const td = document.createElement("td")
      td.className = "border border-black px-3 py-2"
      td.textContent = value ?? ""
      tr.append(td)
    }
    return tr
  }

  // "secret-1" => "secre***". Passwords of 3 characters or fewer are fully masked.
  mask(password) {
    if (!password) return ""
    const hidden = Math.min(3, password.length)
    return password.slice(0, password.length - hidden) + "*".repeat(hidden)
  }

  showStatus(message, isError = false) {
    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("text-red-600", isError)
    this.statusTarget.classList.toggle("text-gray-500", !isError)
  }
}
