import { Controller } from "stimulus"
import I18n from "i18n-js";

export default class extends Controller {
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'reasonInput']

  submit(){
    if (this.daysInputTarget.value != '' && this.startDateInputTarget.value != ''
      && this.endDateInputTarget.value != '' && this.reasonInputTarget.value != '') {
      this.formTarget.requestSubmit()
    }
  }

  enableSubmit() {
    if (this.daysInputTarget.value != '' && this.startDateInputTarget.value != ''
      && this.endDateInputTarget.value != '' && this.reasonInputTarget.value != '') {
      let disabledButton = document.getElementById('salary-payment-disabled-button')
      let enabledButton = document.getElementById('salary-payment-enabled-button')

      enabledButton.classList.remove('hidden')
      disabledButton.classList.add('hidden')
    }
  }
}
