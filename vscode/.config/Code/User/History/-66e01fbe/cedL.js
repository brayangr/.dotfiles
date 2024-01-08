import { Controller } from 'stimulus'
import AutoNumeric from 'autonumeric'

export default class extends Controller {
  static values = { querySelector: String }
  static targets = ['input'];

  connect() {
    let autoNumericInput;

    debugger
    if (this.querySelectorValue != null) {
      autoNumericInput = document.querySelector(this.querySelectorValue)
    } else {
      autoNumericInput = this.inputTarget
    }

    new AutoNumeric(
      this.querySelectorValue,
      $.parseAutonumericData(JSON.parse(autoNumericInput.dataset.autonumeric))
    )
  }
}
