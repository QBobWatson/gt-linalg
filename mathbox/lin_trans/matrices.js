class Matrix{
    constructor(mat, description) {
	this.mat = mat;
	this.description = description;
    }

    katex(element) {
        katex.render(`\\begin{bmatrix} ${this.mat[0][0]} & ${this.mat[0][1]}`+
		     `\\\\ ${this.mat[1][0]} & ${this.mat[1][1]}`
		     + ` \\end{bmatrix}`, element);
    }

    multiply_vec(x, y) {
        // Multiply a vector by self
        const vec = [this.mat[0][0]*x + this.mat[0][1]*y, this.mat[1][0]*x + this.mat[1][1]*y];
        console.log(vec);
        return vec;
    }

    is_identity() {
        return this.mat[0][0] == 1 && this.mat[1][1] == 1 && this.mat[0][1] ==
	    0 && this.mat[1][0] == 0;
    }

    fixes_square() {
        return this.mat[0][0] == 1 && this.mat[1][1] == 1 && this.mat[0][1] == 0 &&
	    this.mat[1][0] == 0 ||
        this.mat[0][0] == -1 && this.mat[1][1] == -1 && this.mat[0][1] == 0 &&
	    this.mat[1][0] == 0 ||
        this.mat[0][0] == 0 && this.mat[1][1] == 0 && this.mat[0][1] == 1 &&
	    this.mat[1][0] == -1 ||
        this.mat[0][0] == 0 && this.mat[1][1] == 0 && this.mat[0][1] == -1 &&
	    this.mat[1][0] == 1;
    }

    static shear(amount, direction) {
	let mat = [[1, 0], [0, 1]];
	if (direction == 'horizontal') {
	    mat[0][1] = amount;
	}
	else if (direction == 'vertical') {
	    mat[1][0] = amount;
	}
	let desc = '${direction} shear by ${amount}';
	return new Matrix(mat, desc);
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
