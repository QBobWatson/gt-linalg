function start_game() {
	var size = $('#size-selector').find(':selected').val();
	var starting_player = $('#player-selector').find(':selected').val();
	return new Game(size, starting_player);
}

function coordinates($element){
	var id = $element.id;
	var i = id.slice(-2,-1);
	var j = id.slice(-1);
	return [Number(i), Number(j)]
}

class Game {
	constructor(size, starting_player) {
		this.size = size;
		this.clear_board();
		this.generate_board();
		this.current_player = starting_player;
		this.remaining = size*size;
	}

	current_class() {
		if (this.current_player == 0) {
			return 'zero_hover';
		} else {
			return 'one_hover';
		}
	}

	clear_board() {
		$('#board').empty();
		$('#determinant').html('');
		$('#winner').html('').removeClass('one').removeClass('zero').addClass('neutral');
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
			  $div.hover(function(){
				if ($(this).hasClass('empty')){
				  $(this).removeClass('empty').addClass(that.current_class()).html(that.current_player);
				}
			  },
			  function(){
				var cls = that.current_class();
				if ($(this).hasClass(cls)){
				  $(this).removeClass(cls).addClass('empty').html('');
				}
			  }
			  )
			  	$td.append($div)
				$tr.append($td);
				$board.append($tr);
			}
		}
	}

	enter_entry(td_div) {
		if ($(td_div).hasClass('zero_hover') || $(td_div).hasClass('one_hover'))
		{
			this.remaining -= 1;
			if (this.current_player == 0) {
				$(td_div).removeClass('zero_hover').addClass('zero');
				this.current_player = 1;
			} else {
				$(td_div).removeClass('one_hover').addClass('one');
				this.current_player = 0;

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
			var winner;
			if (det == 0) {
				$('#winner').html(0).removeClass('neutral').addClass('zero');
			} else {
				$('#winner').html(1).removeClass('neutral').addClass('one');
			}
			$('#winner').fadeTo('slow',0.2).fadeTo('slow',1).fadeTo('slow',0.2).fadeTo('slow',1).fadeTo('slow',0.2).fadeTo('slow',1);
		}
	}

}