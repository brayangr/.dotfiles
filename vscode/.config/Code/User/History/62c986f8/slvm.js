import { Controller } from "stimulus";
import I18n from "i18n-js";

export default class extends Controller {
  static targets = ['radioButton',
                    'requirements1',
                    'requirements2',
                    'requirements3',
                    'submitBtn']

  show() {
    const radioButtons = this.radioButtonTargets
    let option = radioButtons.find(button => button.checked == true)
    const hash_of_requirements = { option_1: this.requirements1Target,
                                   option_2: this.requirements2Target,
                                   option_3: this.requirements3Target }

    this.collapseShow(hash_of_requirements[option.value])
    this.enable_submit_button()
    this.change_the_title_submit_button(option.value)
  }

  collapseShow(element) {
    this.collapseCloseAll()
    element.classList.toggle('show')
  }

  collapseCloseAll() {
    const requirements = [this.requirements1Target,
                          this.requirements2Target,
                          this.requirements3Target]

    requirements.map(requirement => requirement.classList.remove("show"))
  }

  enable_submit_button() {
    const button = this.submitBtnTarget
    button.disabled = false
  }

  change_the_title_submit_button(option) {
    const button = this.submitBtnTarget

    if (option == 'option_3'){
      button.value = I18n.t('views.upselling.stp.send_to_waiting_list')
    } else if (button.value != I18n.t('views.upselling.stp.send_requirements') ) {
      button.value = I18n.t('views.upselling.stp.send_requirements')
    }
  }
}
