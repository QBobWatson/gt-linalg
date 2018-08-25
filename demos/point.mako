## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">A point by coordinates</%block>

##

pointColor = new Color "green"
lineColor  = new Color "blue"

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

    @caption '''<p><span id="point-here"></span></p>
                <p>[click and drag the point]</p>
             '''

    origin = [0, 0, 0]
    point  = [5, 3, 4]
    color  = pointColor

    view
        .array
            channels: 3
            data:     point
        .point
            color:  pointColor.arr()
            size:   15
            zIndex: 5
        .text
            data: ['p']
        .label
            outline:    0
            background: "black"
            color:      pointColor.arr()
            offset:     [0, 30]
            size:       20
            zIndex:     5

    view
        .array
            channels: 3
            width:    4
            expr: (emit, i) ->
                switch i
                    when 0 then emit.apply null, origin
                    when 1 then emit point[0], origin[1], origin[2]
                    when 2 then emit point[0], point[1], origin[2]
                    when 3 then emit.apply null, point
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
                    when 0 then emit (origin[0] + point[0])/2, origin[1], origin[2]
                    when 1 then emit point[0], (origin[1] + point[1])/2, origin[2]
                    when 2 then emit point[0], point[1], (origin[2] + point[2])/2
        .text
            live:  true
            width: 3
            expr: (emit, i) -> emit (point[i] - origin[i]).toFixed(2)
        .label
            outline:    0
            background: "black"
            color:      lineColor.arr()
            offset:     [25, 0]
            size:       15
            zIndex:     3

    # gui
    params =
        a: point[0]
        b: point[1]
        c: point[2]
    gui = new dat.GUI()
    a = gui.add(params, 'a', -10, 10).step(0.1).listen()
    b = gui.add(params, 'b', -10, 10).step(0.1).listen()
    c = gui.add(params, 'c', -10, 10).step(0.1).listen()

    update = () =>
        point[0] = params.a
        point[1] = params.b
        point[2] = params.c
        katex.render "\\color{#{pointColor.str()}}p = " \
            + "\\color{#{lineColor.str()}}{#{params.a.toFixed 2}, " \
            + "#{params.b.toFixed 2}, #{params.c.toFixed 2}}",
            document.getElementById "point-here"
    a.onChange update
    b.onChange update
    c.onChange update
    update()

    # Make the vectors draggable
    @draggable view,
        points: [point]
        size:   30
        hiliteColor: [0, 1, 1, .75]
        onDrag: (vec) ->
            # dragging head
            vec.clampScalar -10, 10
            params.a = vec.x
            params.b = vec.y
            params.c = vec.z
            update()

