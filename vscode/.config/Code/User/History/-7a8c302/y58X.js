import { Controller } from 'stimulus';
import I18n from 'i18n-js';

export default class extends Controller {
  static targets = [
    'description',
    'endDate',
    'title',
    'submitButton',
    'saveButton',
    'hideButton',
    'questionsBlock',
    'publishSurvey',
    'countingMethod',
    'saveDataSurvey',
    'noSaveDataSurvey'
  ];
  static values = {
    surveyId: Number,
    published: Boolean,
   };

  connect() {
    this.addListenerToReturn();
    this.addListenersToMandatoryInputs();
    this.messageOnLeftPage();
    $('#cancel_edit_survey, #submit_edit_survey').on(
      'hidden.bs.modal',
      function (event) {
        window.onbeforeunload = function () {
          return 'message?';
        };
      }
    );
  }

  messageOnLeftPage() {
    window.onbeforeunload = function () {
      return 'message?';
    };
  }

  toggleHideButton() {
    if (this.questionsBlockTarget.style.display === '') {
      this.questionsBlockTarget.style.display = 'none';
      this.hideButtonTarget.textContent = I18n.t('views.commons.show');
    } else {
      this.questionsBlockTarget.style.display = '';
      this.hideButtonTarget.textContent = I18n.t('views.commons.hide');
    }
  }

  showQuestionsBlock() {
    if (this.questionsBlockTarget.style.display === 'none') {
      this.questionsBlockTarget.style.display = '';
      this.hideButtonTarget.textContent = I18n.t('views.commons.hide');
    }
  }

  showCancelModal() {
    $('#cancel_edit_survey').modal('show');
    window.onbeforeunload = null;
  }

  async showSubmitModal() {
    if (this.getEmptyMandatoryInputs().length == 0) {
      $('#submit_edit_survey').modal('show');
      window.onbeforeunload = null;
    } else {
      this.checkInputs();
    }
  }

  checkInputs() {
    this.getEmptyMandatoryInputs().forEach((input) => {
      let type = '';
      if (input.classList.contains('option-text-field')) {
        type = 'option';
      } else if (input.classList.contains('date_selector')) {
        type = 'endDate';
      }

      this.checkMandatoryInput(input, type);
    });
  }

  getEmptyMandatoryInputs() {
    const questionOptions = [...this.getQuestionOptionsInput()].filter(
        (input) => input.value == ''
      ),
      titleEndate = [this.titleTarget, this.endDateTarget].filter(
        (input) => input.value == ''
      );
    return [...questionOptions, ...titleEndate];
  }

  checkMandatoryInput(input, type) {
    const errorHtml = `
    <div class='mandatory-message'>${I18n.t('common.mandatory_field')}</div>
    `;
    let nextElementSibling =
      type === 'option' || type === 'endDate'
        ? input.form.nextElementSibling
        : input.nextElementSibling;

    if (input.value) {
      input.classList.remove('mandatory-field');

      if (nextElementSibling && nextElementSibling.classList.contains('mandatory-message')) {
        nextElementSibling.remove();
      }
    } else {
      input.classList.add('mandatory-field');

      if (nextElementSibling && !nextElementSibling.classList.contains('mandatory-message')) {
        type === 'option' || type === 'endDate'
          ? input.form.insertAdjacentHTML('afterend', errorHtml)
          : input.insertAdjacentHTML('afterend', errorHtml);
      } else if ( nextElementSibling == null){
        input.form.insertAdjacentHTML('afterend', errorHtml)
      }
    }
  }

  addListenerToReturn() {
    let returnButton = document.getElementById('returnButton');
    returnButton.addEventListener('click', (e) => {
      e.preventDefault();
      this.showCancelModal();
    });
  }

  addListenersToMandatoryInputs() {
    this.getQuestionOptionsInput().forEach((input) => {
      input.addEventListener('blur', () => {
        let type = input.classList.contains('option-text-field')
          ? 'option'
          : 'question';
        this.checkMandatoryInput(input, type);
      });
    });

    [this.titleTarget, this.endDateTarget].forEach((input) => {
      input.addEventListener('blur', () => {
        let type = input.classList.contains('date_selector')
          ? 'endDate'
          : 'title';
        this.checkMandatoryInput(input, type);
      });
    });
  }

  getQuestionOptionsInput() {
    return document.querySelectorAll(
      '.question-text-field, .option-text-field'
    );
  }

  async saveSurvey() {
    this.saveButtonTarget.classList.add('disabled');
    this.submitButtonTarget.classList.add('disabled');
    this.saveDataSurveyTarget.classList.add('disabled');
    this.noSaveDataSurveyTarget.classList.add('disabled');
    const surveyId = this.surveyIdValue;

    await this.saveDataSurvey(surveyId);

    window.onbeforeunload = null;

    window.location.href = this.publishedValue ? '/votaciones' : '/votaciones?search%5Bpublished%5D=false';
  }

  async publishForm(e) {
    e.preventDefault();
    await this.saveDataSurvey(this.surveyIdValue);
    this.publishSurveyTarget.submit();
  }

  async saveDataSurvey(surveyId) {
    const fetchPromises = [];

    // Save title
    let title = this.titleTarget.value;
    fetchPromises.push(this.submitForm(title, null, surveyId, 'title'));

    // Save description
    let description = this.descriptionTarget.value;
    fetchPromises.push(
      this.submitForm(description, null, surveyId, 'description')
    );

    // Save end date
    let endDate = this.endDateTarget.value;
    fetchPromises.push(this.submitForm(endDate, null, surveyId, 'end_date'));

    // Save questions titles
    let questions = document.querySelectorAll('.question-text-field');
    questions.forEach((q) => {
      let questionIndex = +q.getAttribute('data-id'),
        value = q.value;
      fetchPromises.push(
        this.submitForm(value, questionIndex, surveyId, 'question')
      );
    });

    // Save options value
    let options = document.querySelectorAll('.option-text-field');
    options.forEach((o) => {
      let optionIndex = +o.getAttribute('data-id'),
        value = o.value;
      fetchPromises.push(
        this.submitForm(value, optionIndex, surveyId, 'option')
      );
    });

    // Save counting method
    let countingMethod = this.countingMethodTarget.checked;
    fetchPromises.push(
      this.submitForm(countingMethod ? 'property_users_in_charge_weighted' : 'all_property_users_not_weighted', null, surveyId, "counting_method")
    );

    await Promise.all(fetchPromises);
  }

  async submitForm(textValue, fieldId, surveyId, type) {
    return new Promise((resolve) => {
      this.timeout = setTimeout(async () => {
        await fetch(`/votaciones/${surveyId}/save_options_title`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document
              .querySelector('meta[name="csrf-token"]')
              .getAttribute('content'),
          },
          body: JSON.stringify({
            fieldId,
            type,
            textValue,
          }),
        }).then(() => {
          resolve();
        });
      });
    });
  }
}
