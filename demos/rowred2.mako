## -*- coffee -*-

<%inherit file="base_slideshow.mako"/>

<%block name="title">Row Reducing a Matrix</%block>
<%block name="first_caption">Let's row reduce this matrix.</%block>

## '

rrmat.setMatrix [[0, -7, -4,  2],
                 [2,  4,  6, 12],
                 [3,  1, -1, -2]]

window.slideshow =
    rrmat.slideshow()

    .caption "<b>Step 1a:</b> These are the pivots in the first column."
    .setStyle(blink "red", [[1,0],[2,0]])
    .caption "<b>Step 1a:</b> These are the pivots in the first column." \
             + " We need to move one of them to the first row."
    .break()

    .setStyle
        color:    "black"
        entries:  [[2,0]]
        duration: 0.2
    .rowSwap 0, 1
    .break()

    .caption "<b>Step 1b:</b> Make this entry a 1 by dividing by 2."
    .setStyle(blink "red", [[0,0]], 1)
    .rowMult 0, 1/2
    .break()

    .caption "Let's get rid of this distracting line."
    .unAugment()
    .break()

    .caption "<b>Step 1c:</b> We kill this entry..."
    .setStyle(blink "blue", [[2,0]], 1)
    .caption "<b>Step 1c:</b>" \
             + " We kill this entry by subtracting 3 times the first row."
    .rowRep 0, -3, 2
    .setStyle
        color:    "black",
        entries:  [[2,0]]
        duration: 0.2
    .break()

    .caption """Now that the first column is clear except for the pivot in
                the first row, we can ignore the first row and the first
                column and concentrate on the rest of the matrix."""
    .setStyle
        color:    "rgb(200,200,200)",
        entries:  [[0,0],[0,1],[0,2],[0,3],[1,0],[2,0]]
        duration: 0.5
    .break()

    .caption """<b>Step 2a</b> (optional):
                Both of the remaining entries in
                the second column are pivots."""
    .setStyle(blink "red", [[1,1],[2,1]])
    .break()

    .caption """<b>Step 2a</b> (optional):
                We'll use the bottom entry as our pivot..."""
    .setStyle
        color:    "black"
        entries:  [[1,1]]
        duration: 1
    .caption """<b>Step 2a</b> (optional):
                We'll use the bottom entry as our pivot,
                so we have to switch rows."""
    .rowSwap 1, 2
    .break()

    .caption "<b>Step 2b:</b> Divide row 2 by -5 to make this pivat a 1."
    .rowMult 1, -1/5
    .caption """<b>Step 2b:</b> Divide row 2 by -5 to make this pivat a 1.
                (The other entries in this row are divisible by 5; that's why we
                used this row as the pivot row.)"""
    .break()

    .caption "<b>Step 2c:</b> To kill this entry..."
    .setStyle(blink "blue", [[2,1]], 1)
    .caption """<b>Step 2c:</b>
                To kill this entry, we add 7 times row 2 to row 3."""
    .rowRep 1, 7, 2
    .setStyle
        color:    "black"
        entries:  [[2,1]]
        duration: 0.2
    .break()

    .caption """Now the second column (the part we care about) is clear
                except for the pivot in the pivot, so we can ignore the
                second column and second row."""
    .setStyle
        color:    "rgb(200,200,200)"
        entries:  [[1,1],[1,2],[1,3],[2,1]]
        duration: 1
    .break()

    .caption """<b>Step 3a:</b>
                The first nonzero entry of the last row is a pivot."""
    .setStyle(blink "red", [[2,2]])
    .break()

    .caption "<b>Step 3b:</b> We divide by 10 to make it equal to 1."
    .rowMult 2, 1/10
    .break()

    .caption "Notice that the matrix is now in <i>row echelon form</i>."
    .setStyle [
        color:    "red"
        entries:  [[0,0],[1,1],[2,2]]
        duration: 1,
        color:    "black"
        entries:  [[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]]
        duration: 1
        ]
    .break()

    .caption """To put the matrix in <i>reduced</i> row echelon form, we
                need to clear the entries in
                <span style=\"color: blue;\">blue</span>."""
    .setStyle [
        color:    "black"
        entries:  [[0,0],[1,1],[2,2]]
        duration: 1
        ].concat(blink "blue", [[0,1],[0,2],[1,2]], 1)
    .break()

    .caption """<b>Last step:</b>
                We do this by taking advantage of the pivots in each column
                and doing row replacement."""
    .setStyle(blink "red", [[1,1],[2,2]])
    .break()

    .caption "<b>Last step:</b> First we clear the third column..."
    .setStyle [
        color:    "black"
        entries:  [[0,1], [1,1]]
        duration: 1
        ].concat(blink "red", [[2,2]], 1).concat(blink "blue", [[0,2],[1,2]], 1)
    .caption """<b>Last step:</b>
                First we clear the third column using row replacement."""
    .rowRep 2, -2, 1
    .rowRep 2, -3, 0
    .break()

    .caption "<b>Last step:</b> Then we clear the second column..."
    .setStyle [
        color:    "black"
        entries:  [[0,2],[1,2],[2,2]]
        duration: 1
        ].concat(blink "red", [[1,1]], 1).concat(blink "blue", [[0,1]], 1)
    .caption """<b>Last step:</b>
                Then we clear the second column in the same way."""
    .rowRep 1, -2, 0
    .break()

    .caption "The matrix is now in reduced row echelon form!"
    .setStyle [
        color:    "black"
        entries:  [[1,0],[2,0],[2,1],[0,1]]
        duration: 1,
        color: "red"
        entries: [[0,0],[1,1],[2,2]]
        duration: 1
        ]
    .break()

    .caption "Add back the divider..."
    .reAugment()
    .caption "Add back the divider, and we're done!"
    .setStyle
        transform: "rotate(360deg)"
        entries:   [[0,0],[0,1],[0,2],[0,3],
                    [1,0],[1,1],[1,2],[1,3],
                    [2,0],[2,1],[2,2],[2,3]]
        duration:  1.5
        timing:    'linear'
    .break()
