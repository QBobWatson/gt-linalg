## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Scalar multiplication</%block>
##

window.demo = new Demo {
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
    vector2 = [3*1.5, -5*1.5,  4*1.5]
    color1 = new Color "green"
    color2 = new Color "red"

    @labeledVectors view,
        vectors: [vector1]
        colors:  [color1]
        labels:  ['v']
        vectorOpts:
            width: 10

    @labeledVectors view,
        vectors: [vector2]
        colors:  [color2]
        labels:  ['v']
        zeroPoints: true
        name:    'scaled'
    mathbox.select("#scaled-text").set 'live', true
    mathbox.select("#scaled-text").bind 'data', () -> [params.c.toFixed(2) + 'v']

    # Make the vector draggable
    @draggable view,
        points: [vector1]
        onDrag: (vec) ->
            vec.clampScalar -10, 10
            vector2[0] = vector1[0] * params.c
            vector2[1] = vector1[1] * params.c
            vector2[2] = vector1[2] * params.c
            update()

    # gui
    params =
        c: 1.5
    gui = new dat.GUI();
    gui.add(params, 'c', -10, 10).step(0.1).onChange () ->
        vector2[0] = vector1[0] * params.c
        vector2[1] = vector1[1] * params.c
        vector2[2] = vector1[2] * params.c
        update()

    @caption '''<p><span id="vectors-here"></span></p>
                <p>[click and drag the head of v to move it]</p>
             '''
    @vecElt = document.getElementById "vectors-here"
    update = () =>
        katex.render \
            params.c.toFixed(2) + "\\cdot" \
          + @texVector(vector1, color: color1) \
          + "=" \
          + @texVector(vector2, color: color2),
          @vecElt

    update()

