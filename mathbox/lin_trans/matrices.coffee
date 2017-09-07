# Compile with:
#    cat matrices.coffee | coffee --compile --stdio > matrices.js

class Matrix
    constructor: (@mat) ->

    katex: () ->
        html = katex.renderToString("\\begin{bmatrix} #{@mat[0][0]} & #{@mat[0][1]} \\\\ #{@mat[1][0]} & #{@mat[1][1]} \\end{bmatrix}")
        html

mat = new Matrix([[2, 1], [1, 1]])
html = mat.katex()
console.log html
