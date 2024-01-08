import { Controller } from "stimulus"
import AutoNumeric from "autonumeric"
import I18n from "i18n-js";

export default class extends Controller {
  static values = { lastSalaryPayment: Number }
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'addNewTooltip' ]

  submit(){
    if (this.daysInputTarget.value != '' && this.lastSalaryInputTarget.value != ''
        && this.startDateInputTarget.value != '' && this.endDateInputTarget.value != '') {
    this.formTarget.requestSubmit()
    }
  }
}
