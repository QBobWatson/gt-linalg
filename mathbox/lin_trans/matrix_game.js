class MatrixGame {
    constructor(matrices, start_matrix, win_condition, objective, title) {
	this.matrices = matrices;
	this.current_matrix = start_matrix;
	this.win_condition = win_condition;
	this.objective = objective;
	this.title = title;
    }

    keydown_action(e) {
	var code = e.keyCode;

	console.log(e);
	console.log(code);
	for(var i = 0; i < this.matrices.length; i++) {
	    var tr = this.matrices[i];
	    if (code == tr.keycode) {
		this.current_matrix = mul(tr, this.current_matrix);
	    }
	}
    }

    keyup_action() {
	if (this.win_condition(this.current_matrix)) {
	    alert('You won!');
	}
    }

    game_description_html() {
	// Generates an HTML string describing the game.

	var html = `<h1>${this.title}</h1>
	<section>
	    <dl class="dl-horizontal">
		<dt>Controls</dt>
		<dd>
                    <table class="table">
                        <tbody>`;

	for(var i = 0; i < this.matrices.length; i++) {
	    var tr = this.matrices[i];

	    html += `<tr><td>${tr.key_html}</td><td>${tr.description}</td><td>${tr.katex()}</td></tr>`;
	}

	html += `</tbody> </table>
		</dd>
		<dt>Objective</dt>
		<dd>${this.objective}</dd>
	    </dl>
	</section>`;

	return html;
    }
}
