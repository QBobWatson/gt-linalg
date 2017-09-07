# Compile with:
#    cat matrices.coffee | coffee --compile --stdio > matrices.js

class Matrix
    constructor: (@mat, @description = '') ->

    katex: () ->
        html = katex.renderToString("\\begin{bmatrix} #{@mat[0][0]} & #{@mat[0][1]} \\\\ #{@mat[1][0]} & #{@mat[1][1]} \\end{bmatrix}")
        html

shear_left = new Matrix([[1, -1], [0, 1]], "shear left")
shear_right = new Matrix([[1, 1], [0, 1]], "shear right")
shear_down = new Matrix([[1, 0], [-1, 1]], "shear down")
shear_up = new Matrix([[1, 0], [1, 1]], "shear up")

html = mat.katex()
console.log html
