import { Controller } from 'stimulus';

export default class extends Controller {
  static monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  static monthShortNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  changeValue(event) {
    const element = event.currentTarget;
    const dateValue = element.getAttribute('data-date');
    const dropdown = element.closest('.dropdown');
    this.updateValues(dropdown, dateValue)
  }

  updateValues(dropdown, date) {
    const selectorName = dropdown.querySelector('.selected-value');
    const selector = dropdown.closest('.date-selector');
    const formValue = selector.querySelector("input[type='hidden']");
    const changeEvent = new Event('change');
    const optional = selector.querySelectorAll("input[type='hidden']")[1].value;

    if (optional == 'true' && date == ''){
      selectorName.value = date;
      formValue.value = date;
    } else {
      selectorName.value = this.formatDate(date);
      formValue.value = date;
    }
    this.removeCalendar(dropdown)
    formValue.dispatchEvent(changeEvent);
  }

  showCalendar(event) {
    const element = event.currentTarget
    const dropdown = element.closest('.dropdown')
    const selector = dropdown.closest('.date-selector')
    const formValue = selector.querySelector("input[type='hidden']").value
    const formDate = this.dateFormat(formValue)
    this.showWeekDays(dropdown)
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    dropdownTitle.setAttribute('data-action', 'click->date-selector#changeMonth')
    const prevMonthBtn = dropdown.querySelector('.dropdown-item.previous-month')
    const nextMonthBtn = dropdown.querySelector('.dropdown-item.next-month')
    prevMonthBtn.setAttribute('data-action', 'click->date-selector#previousMonth')
    nextMonthBtn.setAttribute('data-action', 'click->date-selector#nextMonth')
    this.addCalendar(dropdown, formDate)
  }

  showWeekDays(dropdown) {
    dropdown.querySelectorAll('.dropdown-item.day-of-the-week').forEach(dropdownItem => {
      dropdownItem.removeAttribute('style');
    });
  }

  formatDate(fullDate) {
    const dateArray = fullDate.split('-');
    return `${dateArray[2]}/${dateArray[1]}/${dateArray[0]}`;
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  getCalendarRange(resultDate) {
    const date = this.splitDate(resultDate)
    const beginningOfMonth = new Date(date.year, date.month - 1, 1);
    const endOfMonth = new Date(date.year, date.month, 0);
    const startWeekDay = beginningOfMonth.getDay();
    const endWeekDay = endOfMonth.getDay();
    const previousDays = startWeekDay === 0 ? 6 : startWeekDay - 1;
    const postDays = endWeekDay === 0 ? -1 : 6 - endWeekDay;
    const totalDays = postDays + endOfMonth.getDate() + previousDays + 1
    const endIndex = totalDays < 42 ? endOfMonth.getDate() + postDays + 7 : endOfMonth.getDate() + postDays
    return [-previousDays, endIndex, endOfMonth.getDate()];
  }

  changeMonth(event) {
    event.stopPropagation();
    const element = event.currentTarget;
    const dropdown = element.closest('.dropdown');
    const month = parseInt(element.getAttribute('data-month'));
    const year = parseInt(element.getAttribute('data-year'));
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const prevMonthBtn = dropdown.querySelector('.dropdown-item.previous-month')
    const nextMonthBtn = dropdown.querySelector('.dropdown-item.next-month')
    dropdownTitle.setAttribute('data-action', 'click->date-selector#changeYear')
    dropdownTitle.setAttribute('data-month', month)
    dropdownTitle.innerHTML = year;
    prevMonthBtn.setAttribute('data-action', 'click->date-selector#previousYear')
    nextMonthBtn.setAttribute('data-action', 'click->date-selector#nextYear')
    this.removeCalendar(dropdown)

    dropdown.querySelectorAll('.dropdown-item.day-of-the-week').forEach(dropdownItem => {
      dropdownItem.style.display = 'none';
    });

    this.showMonthGrid(dropdown, month, year)
  }

  showMonthGrid(dropdown, month, year) {
    const dropdownMenu = dropdown.querySelector('.dropdown-menu');
    const selectedDate = this.getSelectedDate(dropdown)
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const yearDisplayed = parseInt(dropdownTitle.getAttribute('data-year'))
    const today = this.splitDate(new Date)
    const monthGrid = document.createElement('div');
    monthGrid.classList.add('month-selector');

    for (const monthIndex in this.constructor.monthShortNames) {
      const monthDiv = document.createElement('div');
      monthDiv.classList.add('dropdown-item-month');
      if (monthIndex == month - 1 && selectedDate.year == yearDisplayed) {
        monthDiv.classList.add('selected');
      }
      if (monthIndex == today.month - 1 && year == today.year) {
        monthDiv.classList.add('current')
      }
      monthDiv.innerHTML = this.constructor.monthShortNames[monthIndex];
      monthDiv.setAttribute('data-month', parseInt(monthIndex) + 1)
      monthDiv.setAttribute('data-year', year)
      monthDiv.setAttribute('data-action', 'click->date-selector#prepareCalendar')
      monthGrid.appendChild(monthDiv);
    }

    dropdownMenu.appendChild(monthGrid);
  }

  changeYear(event) {
    event.stopPropagation();
    const element = event.currentTarget
    const year = parseInt(element.getAttribute('data-year'))
    const dropdown = element.closest('.dropdown');
    const prevMonthBtn = dropdown.querySelector('.dropdown-item.previous-month')
    const nextMonthBtn = dropdown.querySelector('.dropdown-item.next-month')
    prevMonthBtn.setAttribute('data-action', 'click->date-selector#previousRange')
    nextMonthBtn.setAttribute('data-action', 'click->date-selector#nextRange')
    this.showYearGrid(dropdown, year)
  }

  showYearGrid(dropdown, year) {
    const position = year % 12
    const minYear = year - (position - 1)
    const maxYear = year + (12 - position)
    const today = this.splitDate(new Date)
    const selectedDate = this.getSelectedDate(dropdown)
    const dropdownMenu = dropdown.querySelector('.dropdown-menu');
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const yearGrid = document.createElement('div');
    yearGrid.classList.add('year-selector');
    for(let yearIndex = minYear; yearIndex <= maxYear; yearIndex += 1) {
      const yearDiv = document.createElement('div');
      yearDiv.classList.add('dropdown-item-year');

      if (yearIndex == selectedDate.year) {
        yearDiv.classList.add('selected')
      }
      if (yearIndex == today.year) {
        yearDiv.classList.add('current')
      }
      yearDiv.innerHTML = yearIndex;
      yearDiv.setAttribute('data-year', yearIndex)
      yearDiv.setAttribute('data-action', 'click->date-selector#prepareMonths')
      yearGrid.appendChild(yearDiv);
    }
    dropdownMenu.appendChild(yearGrid);
    dropdownTitle.innerHTML = `${minYear} - ${maxYear}`;
    dropdownTitle.setAttribute('data-action', 'click->date-selector#stopPropagation')
    dropdown.querySelectorAll('.month-selector').forEach(monthDiv => { monthDiv.remove() })
  }

  prepareMonths(event) {
    event.stopPropagation();
    const element = event.currentTarget
    const year = parseInt(element.getAttribute('data-year'))
    const dropdown = element.closest('.dropdown');
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const month = parseInt(dropdownTitle.getAttribute('data-month'))
    const prevMonthBtn = dropdown.querySelector('.dropdown-item.previous-month')
    const nextMonthBtn = dropdown.querySelector('.dropdown-item.next-month')
    prevMonthBtn.setAttribute('data-action', 'click->date-selector#previousYear')
    nextMonthBtn.setAttribute('data-action', 'click->date-selector#nextYear')
    dropdownTitle.innerHTML = year;
    dropdownTitle.setAttribute('data-year', year)
    dropdownTitle.setAttribute('data-action', 'click->date-selector#changeYear')
    this.removeCalendar(dropdown)
    this.showMonthGrid(dropdown, month, year)
  }

  shiftMonth(event, monthOffset) {
    event.stopPropagation();
    const dropdown = event.currentTarget.closest('.dropdown');
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const month = parseInt(dropdownTitle.getAttribute('data-month')) - 1
    const year = parseInt(dropdownTitle.getAttribute('data-year'))
    const newDate = new Date(year, month + monthOffset, 1)
    this.addCalendar(dropdown, newDate)
  }

  nextMonth(event) {
    this.shiftMonth(event, 1)
  }

  previousMonth(event) {
    this.shiftMonth(event, -1)
  }

  shiftYear(event, yearOffset) {
    event.stopPropagation();
    const dropdown = event.currentTarget.closest('.dropdown');
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const year = parseInt(dropdownTitle.getAttribute('data-year'))
    const newYear = year + yearOffset
    const today = this.splitDate(new Date)
    dropdownTitle.setAttribute('data-year', newYear)
    dropdownTitle.innerHTML = newYear;
    const selectedDate = this.getSelectedDate(dropdown)
    dropdown.querySelectorAll('.dropdown-item-month').forEach(selector => {
      selector.setAttribute('data-year', newYear)
      const month = parseInt(selector.getAttribute('data-month'))
      if (month == selectedDate.month && newYear == selectedDate.year) {
        selector.classList.add('selected')
      } else {
        selector.classList.remove('selected')
      }
      if (month == today.month && newYear == today.year) {
        selector.classList.add('current')
      } else {
        selector.classList.remove('current')
      }
    })
  }

  nextYear(event) {
    this.shiftYear(event, 1)
  }

  previousYear(event) {
    this.shiftYear(event, -1)
  }

  shiftRange(event, direction) {
    event.stopPropagation();
    const element = event.currentTarget;
    const dropdown = element.closest('.dropdown');
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    const year = parseInt(dropdownTitle.getAttribute('data-year'))
    const nextYear = year + 12 * direction
    dropdownTitle.setAttribute('data-year', nextYear)
    dropdown.querySelectorAll('.year-selector').forEach(monthDiv => { monthDiv.remove() })
    this.showYearGrid(dropdown, nextYear)
  }

  nextRange(event) {
    this.shiftRange(event, 1)
  }

  previousRange(event) {
    this.shiftRange(event, -1)
  }

  prepareCalendar(event) {
    event.stopPropagation();
    const element = event.currentTarget;
    const dropdown = element.closest('.dropdown');
    const preMonth = parseInt(element.getAttribute('data-month'))
    const preYear = parseInt(element.getAttribute('data-year'))
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    dropdownTitle.setAttribute('data-month', preMonth)
    dropdownTitle.setAttribute('data-year', preYear)
    dropdownTitle.setAttribute('data-action', 'click->date-selector#changeMonth')
    const prevMonthBtn = dropdown.querySelector('.dropdown-item.previous-month')
    const nextMonthBtn = dropdown.querySelector('.dropdown-item.next-month')
    prevMonthBtn.setAttribute('data-action', 'click->date-selector#previousMonth')
    nextMonthBtn.setAttribute('data-action', 'click->date-selector#nextMonth')
    const date = new Date(preYear, preMonth - 1, 1)
    date.setHours(0, 0, 0, 0)
    this.removeCalendar(dropdown)
    this.showWeekDays(dropdown)
    this.addCalendar(dropdown, date)
  }

  getSelectedDate(dropdown) {
    const selector = dropdown.closest('.date-selector');
    const date = selector.querySelector("input[type='hidden']").value

    return this.splitDate(date);
  }

  addCalendar(dropdown, date) {
    const newMonth = date.getMonth()
    const newYear = date.getFullYear()
    const newDate = this.splitDate(date)
    const selector = dropdown.closest('.date-selector');
    const formValue = selector.querySelector("input[type='hidden']").value;
    const preselectedDate = this.splitDate(formValue)
    let varDate = new Date()
    if (formValue != ''){
      varDate = new Date(newDate.year, newDate.month - 1, 1);
    }

    const dropdownMenu = dropdown.querySelector('.dropdown-menu');
    const dropdownTitle = dropdown.querySelector('.dropdown-item.current-month')
    dropdownTitle.textContent = `${this.constructor.monthNames[parseInt(newMonth)]} ${newYear}`;
    dropdownTitle.setAttribute('data-month', newDate.month)
    dropdownTitle.setAttribute('data-year', newDate.year)
    this.removeCalendar(dropdown)

    const [start_index, end_index, days_of_month] = this.getCalendarRange(varDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    varDate.setDate(varDate.getDate() + start_index - 1);
    for (let i = start_index; i <= end_index; i += 1) {
      const day = document.createElement('div');
      varDate.setDate(varDate.getDate() + 1);
      day.classList.add('dropdown-item', 'selectable');

      if (i < 0 || i >= days_of_month) {
        day.classList.add('date-of-another-month');
      } else {
        day.classList.add('date-of-the-month');
      }

      if (preselectedDate && this.sameDate(formValue, varDate)) {
        day.classList.add('selected');
      }

      if (this.sameDate(today, varDate)) {
        day.classList.add('today');
      }

      day.setAttribute('data-action', 'click->date-selector#changeValue');
      day.setAttribute('data-date', this.datePart(varDate));
      day.innerHTML = varDate.getDate();
      dropdownMenu.appendChild(day);
    }
  }

  datePart(date) {
    return date.toISOString().split('T')[0]
  }

  splitDate(date) {
    let data = typeof(date) == 'string' ? date : this.datePart(date)
    const array = data.split('-')

    return { year: parseInt(array[0]), month: parseInt(array[1]), day: parseInt(array[2]) }
  }

  removeCalendar(dropdown) {
    dropdown.querySelectorAll('.dropdown-item.selectable, .month-selector, .year-selector').forEach(dropdownItem => {
      dropdownItem.remove();
    });
  }

  dateFormat(string) {
    if (string == '') return new Date()

    const date = this.splitDate(string)
    return new Date(date.year, date.month - 1, date.day)
  }

  sameDate(date_1, date_2) {
    const date1 = this.splitDate(date_1)
    const date2 = this.splitDate(date_2)

    return date1.day == date2.day && date1.month == date2.month && date1.year == date2.year
  }

  updateDate(event) {
    const element = event.currentTarget
    const dropdown = element.closest('.dropdown');
    const selector = dropdown.closest('.date-selector');
    const formValue = selector.querySelector("input[type='hidden']").value;
    const input = selector.querySelector("input[type='text']");
    const inputValue = input.value
    const onlyNumber = inputValue.replace(/\D/g, '');
    const today = this.splitDate(new Date)
    const optional = selector.querySelectorAll("input[type='hidden']")[1].value;

    let dayString
    let monthString
    let yearString
    if (inputValue != onlyNumber) {
      if (onlyNumber) {
        [dayString, monthString, yearString] = inputValue.split(/\D/g).filter(Number)
      } else {
        input.value = this.formatDate(formValue)
        return
      }
    } else {
      dayString = onlyNumber.substring(0, 2)
      monthString = onlyNumber.substring(2, 4)
      yearString = onlyNumber.substring(4, 8)
    }
    let year
    let month
    let day
    if (yearString) {
      year = parseInt(yearString)
      if (yearString.length == 2) {
        const currentCentury = Math.floor(today.year / 100) * 100
        year = currentCentury + year
      } else {
        year = year > 0 ? year : today.year
      }
    } else {
      year = today.year
    }
    if (monthString) {
      month = parseInt(monthString)
      month = month > 0 ? month : today.month
    } else {
      month = today.month
    }
    if (dayString) {
      day = parseInt(dayString)
      day = day > 0 ? day : today.day
    } else {
      day = today.day
    }

    if (optional == 'true' && inputValue == '') {
      this.updateValues(dropdown, '')
    } else {
      const date = this.datePart(new Date(year, month - 1, day))
      this.updateValues(dropdown, date)
    }
  }
}
