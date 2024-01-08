import { Controller } from 'stimulus'
import AutoNumeric from 'autonumeric'

export default class extends Controller {
  static values = { querySelector: String }
  connect() {
    const autoNumericInput = document.querySelector(this.querySelectorValue)
    new AutoNumeric(
      this.querySelectorValue,
      $.parseAutonumericData(JSON.parse(autoNumericInput.dataset.autonumeric))
    )
  }
}
