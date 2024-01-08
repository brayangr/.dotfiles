import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ 'disabledButton', 'enabledButton' ]

  call(event){
    let tab = event.currentTarget.dataset.tab;
    let form = null
    switch (tab) {
      case 'worked_days':
        form = this.workedDaysTab(event)
        break;
    }

    form.requestSubmit()
  }

  workedDaysTab(event){
    let id = event.currentTarget.id.split('-').pop();
    let bono_days = document.getElementById(`bono-days-${id}`);
    if (bono_days != event.currentTarget && bono_days != null) bono_days.value = event.currentTarget.value;

    return document.getElementById(`form-${id}`);
  }

  extraHoursTab(event){
    let id = event.currentTarget.id.split('-').pop();

    return document.getElementById(`form-${id}`);
  }

  enableSubmit() {
    this.disabledButtonTarget.classList.remove('hidden')
    this.enabledButtonTarget.classList.add('hidden')
  }
}
