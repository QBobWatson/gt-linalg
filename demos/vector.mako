## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">A vector by coordinates</%block>

##

vecColor  = new Color "green"
lineColor = new Color "blue"

new Demo {
    mathbox:
        mathbox:
            warmup:  10
            splash:  false
            inspect: false
    camera:
        position: [3, -1, 1.5]
}, () ->
    window.mathbox = @mathbox

    view = @view axes: true

    @caption '''<p><span id="vector-here"></span></p>
                <p>[click and drag the arrow head and tail]</p>
             '''

    origin = [0, 0, 0]
    vector = [5, 3, 4]
    color  = vecColor

    @labeledVectors view,
        vectors:    [vector]
        origins:    [origin]
        colors:     [color]
        labels:     ['v']

    view
        .array
            channels: 3
            width:    4
            expr: (emit, i) ->
                switch i
                    when 0 then emit.apply null, origin
                    when 1 then emit vector[0], origin[1], origin[2]
                    when 2 then emit vector[0], vector[1], origin[2]
                    when 3 then emit.apply null, vector
        .line
            classes: ["linear-combo"]
            color:   lineColor.arr()
            opacity: 0.75
            width:   4
            zIndex:  1
    # labels
        .array
            channels: 3
            width:    3
            expr: (emit, i) ->
                switch i
                    when 0 then emit (origin[0] + vector[0])/2, origin[1], origin[2]
                    when 1 then emit vector[0], (origin[1] + vector[1])/2, origin[2]
                    when 2 then emit vector[0], vector[1], (origin[2] + vector[2])/2
        .text
            live:  true
            width: 3
            expr: (emit, i) -> emit (vector[i] - origin[i]).toFixed(2)
        .label
            outline:    0
            background: "black"
            color:      lineColor.arr()
            offset:     [25, 0]
            size:       15
            zIndex:     3

    # gui
    params =
        a: vector[0]
        b: vector[1]
        c: vector[2]
    gui = new dat.GUI()
    a = gui.add(params, 'a', -10, 10).step(0.1).listen()
    b = gui.add(params, 'b', -10, 10).step(0.1).listen()
    c = gui.add(params, 'c', -10, 10).step(0.1).listen()

    update = () =>
        vector[0] = params.a + origin[0]
        vector[1] = params.b + origin[1]
        vector[2] = params.c + origin[2]
        katex.render "\\color{#{vecColor.str()}}v = " \
            + @texVector([params.a, params.b, params.c], color: lineColor),
            document.getElementById "vector-here"
    a.onChange update
    b.onChange update
    c.onChange update
    update()

    # Make the vectors draggable
    @draggable view,
        points: [origin, vector]
        size:   30
        hiliteColor: [0, 1, 1, .75]
        onDrag: (vec) ->
            if @dragging == 0
                # dragging tail
                vector[0] = vec.x + params.a
                vector[1] = vec.y + params.b
                vector[2] = vec.z + params.c
            else
                # dragging head
                vec.clampScalar -10, 10
                params.a = vec.x - origin[0]
                params.b = vec.y - origin[1]
                params.c = vec.z - origin[2]
                update()

