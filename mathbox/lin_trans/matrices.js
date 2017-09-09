function verbose_descr(abbrev) {
    switch(abbrev) {
    case 'H':
	return 'horizontal ';
    case 'V':
	return 'vertical ';
    case '':
	return '';
    }
    throw 'Invalid abbreviation';
}


class Matrix{
    constructor(mat, description, keycode) {
	this.mat = mat;
	this.description = description;
	this.keycode = keycode;
    }

    katex(element) {
	// Render the matrix into the specified HTML element
        katex.render(`\\begin{bmatrix} ${this.mat[0][0]} & ${this.mat[0][1]}`+
		     `\\\\ ${this.mat[1][0]} & ${this.mat[1][1]}`
		     + ` \\end{bmatrix}`, element);
    }

    multiply_vec(x, y) {
        // Multiply a vector by this
        const vec = [this.mat[0][0]*x + this.mat[0][1]*y, this.mat[1][0]*x + this.mat[1][1]*y];
        return vec;
    }

    is_identity() {
	// var id = Matrix.identity();
        // return this.mat == id.mat;
        return this.mat[0][0] == 1 && this.mat[1][1] == 1 && this.mat[0][1] == 0 &&
	    this.mat[1][0] == 0;
    }

    fixes_square() {
	// Decide if the matrix fixes the square with vertices (+-1, +-1)
	// Assumes that the transformation is orientation-preserving.
        return this.mat[0][0] == 1 && this.mat[1][1] == 1 && this.mat[0][1] == 0 &&
	    this.mat[1][0] == 0 ||
        this.mat[0][0] == -1 && this.mat[1][1] == -1 && this.mat[0][1] == 0 &&
	    this.mat[1][0] == 0 ||
        this.mat[0][0] == 0 && this.mat[1][1] == 0 && this.mat[0][1] == 1 &&
	    this.mat[1][0] == -1 ||
        this.mat[0][0] == 0 && this.mat[1][1] == 0 && this.mat[0][1] == -1 &&
	    this.mat[1][0] == 1;
    }

    static identity() {
	return new Matrix([[1,0],[0,1]], 'identity');
    }

    static shear(amount, direction) {
	let mat = [[1, 0], [0, 1]];
	let keycode = 0;
	if (direction == 'H') {
	    mat[0][1] = amount;
	    if (amount >= 0) {
		keycode = 39;  // Right arrow
	    } else {
		keycode = 37; // Left arrow
	    }
	}
	else if (direction == 'V') {
	    mat[1][0] = amount;
	    if (amount >= 0) {
		keycode = 38; // Up arrow
	    } else {
		keycode = 40; // Down arrow
	    }
	}
	let desc = `${verbose_descr(direction)}shear by ${amount}`;
	return new Matrix(mat, desc, keycode);
    }

    static rotation(angle) {
	let a = angle/360*2*Math.PI;
	let mat = [[Math.cos(a),-Math.sin(a)],[Math.sin(a),Math.cos(a)]];
	let keycode = 80; // TODO: 'r'
	return new Matrix(mat, `counterclockwise rotation by ${angle} degrees`,
			 keycode);
    }

    static scale(factor, direction = ''){
	let mat = Matrix.identity();
	let keycode = 0;
	if (direction == 'V') {
	    mat.mat[1][1] = factor;
	    keycode = 0; // TODO: 'v'
	}
	else if (direction == 'H') {
	    mat.mat[0][0] = factor;
	    keycode = 0; // TODO: 'h'
	} else if (direction == '') {
	    mat.mat[0][0] = factor;
	    mat.mat[1][1] = factor;
	    keycode = 0; // TODO: 's'
	}
	return new Matrix(mat.mat, `${verbose_descr(direction)}scaling by ${factor}`);
    }

}

function mul(m1, m2) {
    var x = [[m1.mat[0][0]*m2.mat[0][0] + m1.mat[0][1]*m2.mat[1][0],
        m1.mat[0][0]*m2.mat[0][1] + m1.mat[0][1]*m2.mat[1][1]],
        [m1.mat[1][0]*m2.mat[0][0] + m1.mat[1][1]*m2.mat[1][0],
         m1.mat[1][0]*m2.mat[0][1] + m1.mat[1][1]*m2.mat[1][1]]];
    return new Matrix(x);
}

window.Matrix = Matrix;
window.mul = mul;

// EXAMPLES:
// console.log(Matrix.rotation(90));
// console.log(Matrix.scale(2, 'V'));
// console.log(Matrix.scale(0.3, 'H'));
// console.log(Matrix.scale(5));
// console.log(Matrix.shear(-1, 'V'));

// console.log(Matrix.identity() == Matrix.identity());
// var a = Matrix.identity();
// var b = Matrix.identity();
// console.log(a.mat);
// console.log(b.mat);
// console.log(a.mat == b.mat);
