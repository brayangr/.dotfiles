import { Controller } from "stimulus"
import AutoNumeric from "autonumeric"

export default class extends Controller {
  static values = { lastSalaryPayment: Number }
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'lastSalaryInput', 'addNewTooltip' ]

  submit(){
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
      this.formTarget.requestSubmit()
    }
  }

  setLastSalary() {
    if (this.lastSalaryInputTarget.value == '') {
      AutoNumeric.getAutoNumericElement(this.lastSalaryInputTarget).set(this.lastSalaryPaymentValue)
    }
  }

  enableSubmit() {
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
      this.disabledButtonTarget.classList.remove('hidden')
      this.enabledButtonTarget.classList.add('hidden')
    }
  }
}
