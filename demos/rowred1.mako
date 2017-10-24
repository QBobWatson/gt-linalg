## -*- coffee -*-

<%inherit file="base_slideshow.mako"/>

<%block name="title">"Solving" a matrix</%block>
<%block name="first_caption">We want to "solve" this matrix.</%block>

##

rrmat.setMatrix [[1, 2, 3, 6],
                 [2, -3, 2, 14],
                 [3,  1, -1, -2]]
augment = 2 # for base_slideshow.mako

window.slideshow =
    rrmat.slideshow()
    .caption "We want these two entries to be zero."
    .setStyle(blink "red", [[1,0],[2,0]])
    .break()

    .caption "So we subtract multiples of the first row."
    .rowRep 0, -2, 1
    .rowRep 0, -3, 2
    .setStyle
        color:    "black"
        entries:  [[1,0],[2,0]]
        duration: 0.2
    .break()

    .caption "Now we want these to be zero."
    .setStyle(blink "red", [[0,1],[2,1]])
    .break()

    .caption "It would be nice if this were a 1."
    .setStyle(blink "blue", [[1,1]])
    .break()

    .caption "We could divide the second row by by -7"
    .setStyle(blink "blue", [[1,0],[1,1],[1,2],[1,3]])
    .caption "We could divide the second row by by -7" \
             + " ... but then we would end up with ugly fractions."
    .setStyle
        color:    "black"
        entries:  [[1,0],[1,1],[1,2],[1,3]]
        duration: 0.2
    .break()

    .caption "Let's swap the last two rows first."
    .rowSwap 1, 2
    .setStyle [
        color:    "black"
        entries:  [[1,1]]
        duration: 1
        delay:    0.1,
        color:    "red"
        entries:  [[2,1]]
        duration: 1
        delay:    0.1
        ]
    .break()

    .caption "Now we divide the middle row by -5, without producing fractions."
    .rowMult 1, -1/5
    .break()

    .caption "We kill the red entries using row replacement, like before."
    .rowRep 1, -2, 0
    .rowRep 1,  7, 2
    .setStyle
        color: "black"
        entries: [[0,1],[2,1]]
        duration: 0.2
    .break()

    .caption "Next we want to get rid of these entries."
    .setStyle(blink "red", [[0,2],[1,2]])
    .break()

    .caption "To make this entry a 1..."
    .setStyle(blink "black", [[2,2]])
    .caption "To make this entry a 1, we divide the third row by 10"
    .rowMult 2, 1/10
    .break()

    .caption "We kill the red entries using row replacement, like before."
    .rowRep 2, -2, 1
    .rowRep 2,  1, 0
    .setStyle
        color:    "black"
        entries:  [[0,2],[1,2]]
        duration: 0.2
    .caption "And we're done!"
    .setStyle
        transform: "rotate(360deg)"
        entries: [[0,0],[0,1],[0,2],[0,3],
                  [1,0],[1,1],[1,2],[1,3],
                  [2,0],[2,1],[2,2],[2,3]]
        duration: 1.5
        timing: 'linear'
    .break()

