import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = ['submitButton', 'priceInput']

  enableSubmitButton(event) {
    console.log(AutoNumeric.getAutoNumericElement(event.target).getNumber())
  }
}
