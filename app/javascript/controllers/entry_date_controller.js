import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  useToday() {
    const today = new Date()
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    const formatted = `${String(today.getDate()).padStart(2, "0")} ${months[today.getMonth()]} ${today.getFullYear()}`
    this.inputTarget.value = formatted
  }
}
