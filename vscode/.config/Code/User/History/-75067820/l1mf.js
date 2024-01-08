import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = []

  connect() {
    this.numeric = false
    this.date = false
    this.alphanumeric = false;
    this.ths = document.querySelectorAll('.sortable')
  }

  sortBy(){
    this.th = event.target
    this.numeric = this.th.classList.contains('numeric')
    this.date = this.th.classList.contains('date')
    this.alphanumeric = this.th.classList.contains('alphanumeric')
    const tr = this.th.closest('tr')
    const table = tr.closest('table')
    var idx = Array.from(tr.children).indexOf(this.th)

    this.sortTable(table, idx)
  }

  sortTable(table, idx) {
    var  rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
    switching = true;
    // Set the sorting direction to ascending:
    dir = 'asc';
    /* Make a loop that will continue until
    no switching has been done: */
    this.ths.forEach(element => {
      element.classList.remove('selected')
      element.children[0].classList = ''
      element.children[0].classList.add('fa', 'fa-sort')
    });

    this.th.classList.add('selected')

    while (switching) {
      // Start by saying: no switching is done:
      switching = false;
      rows = table.rows;
      /* Loop through all table rows (except the
      first, which contains table headers): */

      for (i = 1; i < (rows.length - 1); i++) {
        // Start by saying there should be no switching:
        shouldSwitch = false;
        /* Get the two elements you want to compare,
        one from current row and one from the next: */

        x = rows[i].getElementsByTagName("TD")[idx];
        y = rows[i + 1].getElementsByTagName("TD")[idx];

        // Added this check if there is a row that has a colspan e.g. ending balance row
        if ((x == undefined) || (y == undefined)) { continue }

        /* Check if the two rows should switch place,
        based on the direction, asc or desc: */

        // Check if numeric sort (th has class numeric)
        if (this.numeric) {
          var compx = x.innerHTML.replace(/\D/g, '')
          var compy = y.innerHTML.replace(/\D/g, '')

          var item_one = /\d/.test(compx) ? parseFloat(compx) : 0
          var item_two = /\d/.test(compy) ? parseFloat(compy) : 0
        } else if (this.date) {  // Check if date sort (th has class date)
          var compx = x.innerHTML.replace('-', '').replace('  ', ' ')
          var compy = y.innerHTML.replace('-', '').replace('  ', ' ')

          var dateX = compx.split('/')
          var dateY = compy.split('/')

          var item_one = new Date(`${dateX[1]}/${dateX[0]}/${dateX[2]}`)
          var item_two = new Date(`${dateY[1]}/${dateY[0]}/${dateY[2]}`)
        } else {
          var item_one = x.innerHTML.toLowerCase()
          var item_two = y.innerHTML.toLowerCase()
        }

        if (dir == 'asc') {
          if (this.alphanumeric) {
            if ((item_one.localeCompare(item_two, undefined, { numeric: true })) == 1) {
              // If so, mark as a switch and break the loop:
              shouldSwitch = true;
              this.th.children[0].classList = 'fa fa-sort-up'

              break;
            }
          } else {
            if (item_one > item_two) {
              // If so, mark as a switch and break the loop:
              shouldSwitch = true;
              this.th.children[0].classList = 'fa fa-sort-up'

              break;
            }
          }
        } else if (dir == 'desc') {
          if (this.alphanumeric) {
            if ((item_two.localeCompare(item_one, undefined, { numeric: true })) == 1) {
              // If so, mark as a switch and break the loop:
              shouldSwitch = true;
              this.th.children[0].classList = 'fa fa-sort-down'

              break;
            }
          } else {
            if (item_one < item_two) {
              // If so, mark as a switch and break the loop:
              shouldSwitch = true;
              this.th.children[0].classList = 'fa fa-sort-down'

              break;
            }
          }

        }
      }

      if (shouldSwitch) {
        /* If a switch has been marked, make the switch
        and mark that a switch has been done: */
        rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
        switching = true;
        // Each time a switch is done, increase this count by 1:
        switchcount ++;
      } else {
        /* If no switching has been done AND the direction is "asc",
        set the direction to "desc" and run the while loop again. */
        if (switchcount == 0 && dir == 'asc') {
          dir = 'desc';
          switching = true;
        }
      }
    }
  }
}
