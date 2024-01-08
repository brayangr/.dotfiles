import { Controller } from 'stimulus'

export default class extends Controller {
  static values = { querySelector: String }
  connect() {
    debugger
    const autoNumericInput = document.querySelector(this.querySelectorValue)
    new AutoNumeric(
      this.querySelectorValue,
      $.parseAutonumericData(JSON.parse(autoNumericInput.dataset.autonumeric))
    )
  }
}
