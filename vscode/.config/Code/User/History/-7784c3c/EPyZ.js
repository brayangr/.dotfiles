import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ 'form', 'descriptionInput', 'amountInput' ]

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
