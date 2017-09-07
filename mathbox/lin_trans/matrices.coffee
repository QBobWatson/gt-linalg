# Compile with:
#    cat matrices.coffee | coffee --compile --stdio > matrices.js

class Matrix
    constructor: (@mat, @description = '') ->

    katex: (element) ->
        katex.render("\\begin{bmatrix} #{@mat[0][0]} & #{@mat[0][1]}
            \\\\ #{@mat[1][0]} & #{@mat[1][1]} \\end{bmatrix}", element)
        # @

    multiply_vec: (x, y) =>
        # Multiply a vector by self
        vec = [@mat[0][0]*x + @mat[0][1]*y, @mat[1][0]*x + @mat[1][1]*y]
        console.log vec
        vec

    is_identity: () ->
        @mat[0][0] == 1 and @mat[1][1] == 1 and @mat[0][1] == 0 and @mat[1][0] == 0

    fixes_square: () ->
        @mat[0][0] == 1 and @mat[1][1] == 1 and @mat[0][1] == 0 and @mat[1][0] == 0 or
        @mat[0][0] == -1 and @mat[1][1] == -1 and @mat[0][1] == 0 and @mat[1][0] == 0 or
        @mat[0][0] == 0 and @mat[1][1] == 0 and @mat[0][1] == 1 and @mat[1][0] == -1 or
        @mat[0][0] == 0 and @mat[1][1] == 0 and @mat[0][1] == -1 and @mat[1][0] == 1

mul = (m1, m2) ->
    x = [[m1.mat[0][0]*m2.mat[0][0] + m1.mat[0][1]*m2.mat[1][0],
        m1.mat[0][0]*m2.mat[0][1] + m1.mat[0][1]*m2.mat[1][1]],
        [m1.mat[1][0]*m2.mat[0][0] + m1.mat[1][1]*m2.mat[1][0],
        m1.mat[1][0]*m2.mat[0][1] + m1.mat[1][1]*m2.mat[1][1]]]
    new Matrix(x)

window.shear_left = new Matrix([[1, -1], [0, 1]], "shear left")
window.shear_right = new Matrix([[1, 1], [0, 1]], "shear right")
window.shear_down = new Matrix([[1, 0], [-1, 1]], "shear down")
window.shear_up = new Matrix([[1, 0], [1, 1]], "shear up")

window.Matrix = Matrix
window.mul = mul
