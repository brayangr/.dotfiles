import { Controller } from 'stimulus'
import AutoNumeric from 'autonumeric'

export default class extends Controller {
  static values = { querySelector: String }

  connect() {
    console.log("asdf")
    console.log(this.querySelectorValue)
    const autoNumericInput = document.querySelector(this.querySelectorValue)
    console.log(autoNumericInput)
    new AutoNumeric(
      this.querySelectorValue,
      $.parseAutonumericData(JSON.parse(autoNumericInput.dataset.autonumeric))
    )
  }
}
