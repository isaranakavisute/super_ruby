import { Controller } from "@hotwired/stimulus"

// Loads all accounts from the /user API and shows them in the Admin Panel table,
// with the last 3 characters of each password masked. Each row has a "Reset Password" button
// and a pencil button that opens an edit dialog.
//
//   <div data-controller="admin-users" data-admin-users-url-value="/user"
//        data-admin-users-reset-url-value="/admin/users/__ID__/reset_password"
//        data-admin-users-reset-password-value="123456"
//        data-admin-users-update-url-value="/admin/users/__ID__">
//     <tbody data-admin-users-target="body"></tbody>
//     <p data-admin-users-target="status"></p>
//     <dialog data-admin-users-target="dialog">…</dialog>
//   </div>
export default class extends Controller {
  static targets = [
    "body", "status",
    "dialog", "editId", "editUsername", "usernameError", "passwordError", "dialogError", "saveButton"
  ]
  static values = { url: String, resetUrl: String, resetPassword: String, updateUrl: String }

  connect() {
    this.users = new Map()
    this.load()
  }

  async load() {
    this.showStatus("Loading users…")

    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`the server replied ${response.status}`)

      const users = await response.json()
      users.forEach((user) => this.users.set(user.id, user))
      this.bodyTarget.replaceChildren(...users.map((user) => this.row(user)))
      this.showStatus(users.length === 0 ? "No users found." : `${users.length} users`)
    } catch (error) {
      this.bodyTarget.replaceChildren()
      this.showStatus(`Could not load users: ${error.message}`, true)
    }
  }

  // Called by a row's "Reset Password" button (data-action="admin-users#resetPassword")
  async resetPassword({ params: { id, username }, currentTarget: button }) {
    if (!confirm(`Reset the password for ${username} to ${this.resetPasswordValue}?`)) return

    button.disabled = true
    button.textContent = "Resetting…"

    try {
      const response = await this.send(this.resetUrlValue.replace("__ID__", id), "POST")
      if (!response.ok) throw new Error(`the server replied ${response.status}`)

      const user = await response.json()
      this.replaceRow(user)
      this.showStatus(`Password for ${user.myuser} has been reset.`)
    } catch (error) {
      button.disabled = false
      button.textContent = "Reset Password"
      this.showStatus(`Could not reset the password for ${username}: ${error.message}`, true)
    }
  }

  // Called by a row's pencil button (data-action="admin-users#edit"): fill in the dialog and open it
  edit({ params: { id } }) {
    const user = this.users.get(id)
    this.editingId = id

    this.editIdTarget.textContent = user.id
    this.editUsernameTarget.value = user.myuser ?? ""
    this.passwordInput.value = user.mypassword ?? ""
    this.passwordInput.type = "password"
    this.clearErrors()

    this.dialogTarget.showModal()
    this.editUsernameTarget.focus()
  }

  closeEditor() {
    this.dialogTarget.close()
  }

  // Called when the dialog's form is submitted (Save button or Enter)
  async save(event) {
    event.preventDefault()
    this.clearErrors()
    this.saveButtonTarget.disabled = true

    try {
      const response = await this.send(this.updateUrlValue.replace("__ID__", this.editingId), "PATCH", {
        myuser: this.editUsernameTarget.value,
        mypassword: this.passwordInput.value
      })

      if (response.status === 422) {
        this.showErrors((await response.json()).errors)
      } else if (!response.ok) {
        throw new Error(`the server replied ${response.status}`)
      } else {
        const user = await response.json()
        this.replaceRow(user)
        this.closeEditor()
        this.showStatus(`${user.myuser} has been saved.`)
      }
    } catch (error) {
      this.showError(this.dialogErrorTarget, `Could not save: ${error.message}`)
    } finally {
      this.saveButtonTarget.disabled = false
    }
  }

  // One <tr> per user. Values are set with textContent, so they are never interpreted as HTML.
  row(user) {
    const tr = document.createElement("tr")
    tr.dataset.userId = user.id
    for (const value of [user.id, user.myuser, this.mask(user.mypassword)]) {
      tr.append(this.cell(value ?? ""))
    }

    const actions = document.createElement("div")
    actions.className = "flex items-center justify-center gap-2"
    actions.append(this.resetButton(user), this.editButton(user))
    tr.append(this.cell(actions, "text-center"))

    return tr
  }

  resetButton(user) {
    const button = document.createElement("button")
    button.type = "button"
    button.textContent = "Reset Password"
    button.className = "cursor-pointer rounded border border-black px-2 py-1 text-xs font-semibold hover:bg-gray-100 disabled:cursor-wait disabled:opacity-50"
    button.dataset.action = "admin-users#resetPassword"
    button.dataset.adminUsersIdParam = user.id
    button.dataset.adminUsersUsernameParam = user.myuser
    return button
  }

  editButton(user) {
    const button = document.createElement("button")
    button.type = "button"
    button.title = "Edit"
    button.setAttribute("aria-label", `Edit ${user.myuser}`)
    button.className = "cursor-pointer rounded border border-black p-1 hover:bg-gray-100"
    button.dataset.action = "admin-users#edit"
    button.dataset.adminUsersIdParam = user.id
    button.innerHTML = PENCIL_ICON
    return button
  }

  cell(content, extraClass = "") {
    const td = document.createElement("td")
    td.className = `border border-black px-3 py-2 ${extraClass}`.trim()
    td.append(content)
    return td
  }

  replaceRow(user) {
    this.users.set(user.id, user)
    this.bodyTarget.querySelector(`tr[data-user-id="${user.id}"]`)?.replaceWith(this.row(user))
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

  // errors: { myuser: ["Username is already taken"], mypassword: [...] }
  showErrors(errors) {
    const { myuser = [], mypassword = [], ...other } = errors
    this.showError(this.usernameErrorTarget, myuser.join(". "))
    this.showError(this.passwordErrorTarget, mypassword.join(". "))
    this.showError(this.dialogErrorTarget, Object.values(other).flat().join(". "))
  }

  showError(element, message) {
    element.textContent = message
    element.classList.toggle("hidden", !message)
  }

  clearErrors() {
    [this.usernameErrorTarget, this.passwordErrorTarget, this.dialogErrorTarget].forEach((element) => this.showError(element, ""))
  }

  get passwordInput() {
    return this.dialogTarget.querySelector("input[name=mypassword]")
  }

  send(url, method, body) {
    return fetch(url, {
      method,
      headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": this.csrfToken },
      body: body && JSON.stringify(body)
    })
  }

  // Rails rejects POST/PATCH requests without the page's CSRF token (from <%= csrf_meta_tags %> in the layout)
  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}

const PENCIL_ICON = `<svg class="size-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor"
  stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
  <path d="M17 3a2.85 2.85 0 0 1 4 4L7.5 20.5 2 22l1.5-5.5Z" /><path d="m15 5 4 4" /></svg>`
