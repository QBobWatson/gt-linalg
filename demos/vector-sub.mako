## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Vector subtraction</%block>

##

new Demo {
    mathbox:
        mathbox:
            warmup:  10
            splash:  false
            inspect: false
    camera:
        position:
            [-1.5, -3, 1.5]
}, () ->
    window.mathbox = @mathbox

    view = @view axes: false
    vector1 = [3, -5,  4]
    vector2 = [4, -1, -2]
    color1 = new Color "blue"
    color2 = new Color "green"
    color3 = new Color "red"
    origins = [[0, 0, 0], [0, 0, 0], vector2]
    vectors = [vector1,   vector2,   vector1]
    colors  = [color1,    color2,    color3]

    @labeledVectors view,
        vectors: vectors
        origins: origins
        colors:  colors
        labels:  ['v', 'w', 'v-w']

    # Make the vectors draggable
    @draggable view,
        points: [vector1, vector2]
        onDrag: (vec) ->
            vec.clampScalar -10, 10
            update()

    @caption '''<p><span id="vectors-here"></span></p>
                <p>[click and drag the heads of v and w to move them]</p>
             '''
    @vecElt = document.getElementById "vectors-here"
    update = () =>
        katex.render \
            @texVector(vector1, color: color1) \
          + "-" \
          + @texVector(vector2, color: color2) \
          + "=" \
          + @texVector([vector1[0]-vector2[0], vector1[1]-vector2[1], vector1[2]-vector2[2]], color: color3),
          @vecElt

    update()
