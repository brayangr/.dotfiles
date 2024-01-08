import { Controller } from "stimulus"
import I18n from "i18n-js";

export default class extends Controller {
  static targets = [ 'form', 'daysInput', 'startDateInput',
                     'endDateInput', 'reasonInput']

  submit(){
    debugger
    if (this.daysInputTarget.value != '' && this.startDateInputTarget.value != ''
      && this.endDateInputTarget.value != '') {
    this.formTarget.requestSubmit()
    }
  }
}
