import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['submitButton', 'priceInput']

  enableSubmitButton(event) {
    if (AutoNumeric.getAutoNumericElement(event.target).getNumber() > 0) {
      debugger
    }
  }
}
