function start_game() {
	var size = $('#size-selector').find(':selected').val();
	return new Game(size);
}

function coordinates($element){
	var id = $element.id;
	var i = id.slice(-2,-1);
	var j = id.slice(-1);
	return [Number(i), Number(j)]
}

class Game {
	constructor(size) {
		this.size = size;
		this.clear_board();
		this.generate_board();
		this.current_player = 0;
		this.remaining = size*size;
	}

	clear_board() {
		$('#board').empty();
		$('#result').hide();
		$('#determinant').html('');
	}
	
	generate_board() {
		var that = this;
		var $board = $('#board');
		for (var i=0; i<this.size; i++) {
			var $tr = $("<tr>");
			for (var j=0; j<this.size; j++) {
				var $td = $('<td>');
				var $div = $("<div>", {id: `entry${i}${j}`,
			"class": `empty size${this.size}`}).click(function() {
				that.enter_entry(this);
			  });
			  	$td.append($div)
				$tr.append($td);
				$board.append($tr);
			}
		}
		this.give_instruction('Player 0: choose a square to enter a 0');
	}

	enter_entry(td_div) {
		var cls = $(td_div).attr('class').split(' ');
		if (!cls.includes('empty')) {
		} else {
			this.remaining -= 1;
			if (this.current_player == 0) {
				$(td_div).removeClass('empty').addClass('zero').html('0');
				this.current_player = 1;
				this.give_instruction('Player 1: choose a square to enter a 1')
				$("#instructions").removeClass('zero').addClass('one');
			} else {
				$(td_div).removeClass('empty').addClass('one').html('1');
				this.current_player = 0;
				this.give_instruction('Player 0: choose a square to enter a 0')
				$("#instructions").removeClass('one').addClass('zero');
			}
			this.check_winner();
		}
	}

	check_winner() {
		if (this.remaining == 0) {
			
			var matrix = [];
			var rows = $('#board').children();
			for (var i = 0; i < rows.length; i++) {
				matrix.push([]);
				var items = $(rows[i]).children();
				for (var j = 0; j < items.length; j++) {
					var $div = $(items[j]).children().first();
					console.log($div);
					if ($div.html() == '0') {
						matrix[i].push(0);
						console.log(matrix);
					} else {
						matrix[i].push(1);
						console.log(matrix);
					}
				}
			}			console.log(matrix);
			var det = numeric.det(matrix);
			console.log(det);

			$('#determinant').html(det);
			$('#result').show();	
			if (det == 0) {
				this.give_instruction("<strong>Player 0 wins!</strong>")
				$("#instructions").removeClass('one').addClass('zero');
				// $('#result').html();
			} else {
				this.give_instruction("<strong>Player 1 wins!</strong>")
				$("#instructions").removeClass('zero').addClass('one');

			}
			$("#instructions div").fadeToggle('slow').fadeToggle('slow').fadeToggle('slow').fadeToggle('slow');				
		}
	}

	give_instruction(text) {
		$("#instructions div").html(text);
	}
}