import "numeric.js";

function start_game() {
    var row_sel = document.getElementById("row-selector");
    var opt = row_sel.options[row_sel.selectedIndex];
    var nrows = opt.value;

    var col_sel = document.getElementById("col-selector");
    opt = col_sel.options[col_sel.selectedIndex];
    var ncols = opt.value;

}


class Game {
    constructor(nrows, ncols, win_condition) {
	this.nrows = nrows;
	this.ncols = ncols;
	this.win_condition = win_condition;

	this.generate_board();
    }

    generate_board() {
	var board = document.getElementById("board");
	for (var i=0; i<this.nrows; i++) {
	    var tr = document.createElement("tr");
	    for (var j=0; j<this.ncols; j++) {
		var td = document.createElement(
		    "td", {id: "entry${i}${j}",
			   class: "entry"});
		tr.appendChild(td);
	    }
	    board.appendChild(tr);
	}
    }

}
