import { Controller } from "stimulus"
import I18n from "i18n-js";

export default class extends Controller {
  static targets = [ 'addNewTooltip' ]

  call(event) {
    let target = event.currentTarget.dataset.target

    event.currentTarget.classList.add('disabled')

    let rows = document.querySelectorAll(`[id='collapsable-${target}']`)

    this.addNewTooltipTarget.setAttribute(
      'data-original-title',
      I18n.t('views.remunerations.salary_payment_drafts.licenses.disabled_add')
    )
    document.getElementById(`hidden-form-${target}`).classList.remove('hidden')
  }
}
