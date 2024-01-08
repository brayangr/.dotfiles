import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'lastSalaryInput', 'addNewTooltip' ]

  call(event) {
    debugger
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

    if (collapse) {
      document.getElementById(`hidden-form-${target}`).classList.add('hidden')
    } else {
      document.getElementById(`hidden-form-${target}`).classList.remove('hidden')
    }

    if (collapse) {
      event.currentTarget.classList.remove('fa-chevron-up')
      event.currentTarget.classList.add('fa-chevron-down')
    } else {
      event.currentTarget.classList.add('fa-chevron-up')
      event.currentTarget.classList.remove('fa-chevron-down')
    }
  }
}
