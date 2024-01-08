import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['submitButton']

  enableSubmitButton(event) {
    if (AutoNumeric.getAutoNumericElement(event.target).getNumber() > 0) {
      this.submitButtonTarget.disabled = false
    } else {
      this.submitButtonTarget.disabled = true
    }
  }
}
