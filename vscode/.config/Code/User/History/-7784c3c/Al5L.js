import { Controller } from "stimulus"
// import AutoNumeric from "autonumeric"

export default class extends Controller {
  static targets = [ 'form', 'descriptionInput', 'amountInput' ]

  submit() {
    // let amountValue = AutoNumeric.getAutoNumericElement(this.amountInputTarget).getNumber()

    if (this.descriptionInputTarget.value != '' && this.amountInputTarget != '') {
      this.formTarget.requestSubmit()
    }
  }

  enableSubmit() {
    if (this.descriptionInputTarget.value != '' && this.amountInputTarget.value != '') {
      let disabledButton = document.getElementById('salary-payment-disabled-button')
      let enabledButton = document.getElementById('salary-payment-enabled-button')

      enabledButton.classList.remove('hidden')
      disabledButton.classList.add('hidden')
    }
  }
}
