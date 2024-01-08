import { Controller } from "stimulus"
import AutoNumeric from "autonumeric"

export default class extends Controller {
  static values = { lastSalaryPayment: Number }
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'lastSalaryInput', 'addNewTooltip' ]

  submit(){
    let lastSalaryValue = AutoNumeric.getAutoNumericElement(this.lastSalaryInputTarget).getNumber()
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
      this.formTarget.requestSubmit()
    }
  }

  setLastSalary() {
    if (this.lastSalaryInputTarget.value == '' && this.lastSalaryPaymentValue > 0) {
      AutoNumeric.getAutoNumericElement(this.lastSalaryInputTarget).set(this.lastSalaryPaymentValue)
      this.enableSubmit()
    }
  }

  enableSubmit() {
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
      let disabledButton = document.getElementById('salary-payment-disabled-button')
      let enabledButton = document.getElementById('salary-payment-enabled-button')

      enabledButton.classList.remove('hidden')
      disabledButton.classList.add('hidden')
    }
  }
}
