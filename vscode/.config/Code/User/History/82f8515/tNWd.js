import { Controller } from 'stimulus'
import I18n from "i18n-js";

export default class extends Controller {
  static values = { id: Number, isRecurrent: Boolean }
  static targets = ['fileInput']

  toggleActions() {
    const actions = document.getElementById(`actions-${this.idValue}`)
    const uploadFile = document.getElementById(`upload-file-action-${this.idValue}`)

    if (actions.classList.contains('hidden')) {
      uploadFile.classList.add('hidden')
      actions.classList.remove('hidden')
    } else {
      uploadFile.classList.remove('hidden')
      actions.classList.add('hidden')
    }
  }

  setDestroyModalData() {
    const modal = document.getElementById('destroy-advance-modal')

    modal.querySelector('#text-message').innerHTML = this.modalText()
    modal.querySelector('#destroy-advance-btn').href = Routes.remuneration_advance_path({ id: this.idValue })
  }

  modalText() {
    if (this.isRecurrentValue) {
      return I18n.t('views.remunerations.advances.modals.destroy.recurrent')
    }

    return I18n.t('views.remunerations.advances.modals.destroy.not_recurrent')
  }

  setNotRecurrentModalData() {
    const modal = document.getElementById('set-not-recurrent-modal')

    modal.querySelector('#set-not-recurrent-btn').href =
      Routes.set_not_recurrent_remuneration_advance_path({ id: this.idValue })
  }
}
