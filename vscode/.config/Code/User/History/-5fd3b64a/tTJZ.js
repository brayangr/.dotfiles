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

  showNewLicense(event) {
    let target = event.currentTarget.dataset.target
    debugger
    event.currentTarget.classList.add('disabled')
    this.addNewTooltipTarget.setAttribute('data-original-title', 'no se nah')
    document.getElementById(target).classList.remove('hidden')
  }

  toggleRow(event) {
    let target = event.currentTarget.dataset.target
    let rows = document.querySelectorAll(`[id='collapsable-${target}']`)
    let collapse =  event.currentTarget.classList.contains('fa-chevron-up')

    for (let i = 0; i < rows.length; i++ ) {
      if (collapse) {
        rows[i].classList.add('hidden')
      } else {
        rows[i].classList.remove('hidden')
      }
    }

    document.getElementById(`hidden-form-${target}`).classList.add('hidden')

    if (collapse) {
      event.currentTarget.classList.remove('fa-chevron-up')
      event.currentTarget.classList.add('fa-chevron-down')
    } else {
      event.currentTarget.classList.add('fa-chevron-up')
      event.currentTarget.classList.remove('fa-chevron-down')
    }
  }

  setLastSalary() {
    if (this.lastSalaryInputTarget.value == '') {
      AutoNumeric.getAutoNumericElement(this.lastSalaryInputTarget).set(this.lastSalaryPaymentValue)
    }
  }
}
