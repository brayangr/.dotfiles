import { Controller } from "stimulus"
import AutoNumeric from "autonumeric"

export default class extends Controller {
  static values = { lastSalaryPayment: Number }
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'lastSalaryInput', 'addNewTooltip',
                     'disabledButtonTarget' ]

  submit(){
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
      this.formTarget.requestSubmit()
    }
  }

  setLastSalary() {
    if (this.lastSalaryInputTarget.value == '' && this.lastSalaryPaymentValue > 0) {
      AutoNumeric.getAutoNumericElement(this.lastSalaryInputTarget).set(this.lastSalaryPaymentValue)
    }
  }

  enableSubmit() {
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
      let button = document.getElementById('salary-payment-button')
      button.classList.remove('hidden')
      button.classList.add('hidden')
    }
  }
}
