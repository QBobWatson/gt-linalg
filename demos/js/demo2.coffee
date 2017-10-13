"use strict"

extend = (obj, src) ->
    for key, val of src
        obj[key] = val if src.hasOwnProperty key


# Clipping shader
clipShader = \
    """
    // Enable STPQ mapping
    #define POSITION_STPQ
    void getPosition(inout vec4 xyzw, inout vec4 stpq) {
      // Store XYZ per vertex in STPQ
    stpq = xyzw;
    }
    """

clipFragment = \
    """
    // Enable STPQ mapping
    #define POSITION_STPQ
    uniform float range;
    uniform int hilite;

    vec4 getColor(vec4 rgba, inout vec4 stpq) {
        stpq = abs(stpq);

        // Discard pixels outside of clip box
        if(stpq.x > range || stpq.y > range || stpq.z > range)
            discard;

        if(hilite != 0 &&
           (range - stpq.x < range * 0.002 ||
            range - stpq.y < range * 0.002 ||
            range - stpq.z < range * 0.002)) {
            rgba.xyz *= 10.0;
            rgba.w = 1.0;
        }

        return rgba;
    }
    """


# Caption in the upper-left part of the screen (controlled by css)

class Caption
    constructor: (@mathbox, text) ->
        @div = @mathbox._context.overlays.div
        @label = document.createElement 'div'
        @label.className = "overlay-text"
        @label.innerHTML = text
        @div.appendChild @label


# Wrapper for a mathbox cartesian view (2D or 3D).
# Options:
#     name: ids and classes are prefixed with "#{name}-"
#     viewRange: range option for the view.  Determines number of dimensions.
#     viewScale: scale option for the view
#     doAxes: construct the axes
#     axisOpts: options to mathbox.axis
#     doGrid: construct a grid
#     gridOpts: options to mathbox.grid
#     doAxisLabels: draw axis labels (x, y, z)
#     labelOpts: options to mathbox.label

class View
    constructor: (@mathbox, @opts) ->
        @opts ?= {}
        @name        = @opts.name         ? "view"
        viewRange    = @opts.viewRange    ? [[-10, 10], [-10, 10], [-10, 10]]
        @numDims     = viewRange.length
        viewScale    = @opts.viewScale    ? [1, 1, 1]

        doAxes = @opts.axes ? true
        axisOpts =
            classes: ["#{@name}-axes"]
            end:     true
            width:   3
            depth:   1
            color:   "white"
            opacity: 0.75
            zBias:   -1
            size:    5
        extend axisOpts, @opts.axisOpts ? {}

        doGrid = @opts.grid ? true
        gridOpts =
            classes: ["#{@name}-axes", "#{@name}-grid"]
            axes:    [1, 2]
            width:   2
            depth:   1
            color:   "white"
            opacity: 0.5
            zBias:   0
        extend gridOpts, @opts.gridOpts ? {}

        doAxisLabels = (@opts.axisLabels  ? true) and doAxes
        labelOpts =
            classes:    ["#{@name}-axes"]
            size:       20
            color:      "white"
            opacity:    1
            outline:    2
            background: "black"
            offset:     [0, 0]
        extend labelOpts, @opts.labelOpts ? {}

        viewScale[0] = -viewScale[0]
        viewOpts =
            range:    viewRange
            scale:    viewScale
            # z is up...
            rotation: [-π/2, 0, 0]
            id:       "#{@name}-view"
        extend viewOpts, @opts.viewOpts ? {}
        @view = @mathbox.cartesian viewOpts

        if doAxes
            for i in [1..@numDims]
                axisOpts.axis = i
                @view.axis axisOpts

        if doGrid
            @view.grid gridOpts

        if doAxisLabels
            @view.array
                channels: @numDims
                width:    @numDims
                live:     false
                expr: (emit, i) =>
                    arr = []
                    for j in [0...@numDims]
                        if i == j
                            arr.push viewRange[i][1] * 1.04
                        else
                            arr.push 0
                    emit.apply null, arr
            .text
                live:  false
                width: @numDims
                data:  ['x', 'y', 'z'][0...@numDims]
            .label labelOpts


# Makes a mathbox API that clips its contents to the cube [-range,range]^3.
# Optionally draws the cube too.
# Options:
#    range: range to clip
#    pass: transform pass to apply the clip to
#    hilite: hilite boundary
#    draw: draw the cube
#    material: material to draw the cube
#    color: color for the wireframe cube

class ClipCube
    constructor: (@view, @opts) ->
        @opts ?= {}
        range  = @opts.range  ? 1.0
        pass   = @opts.pass   ? "world"
        hilite = @opts.hilite ? true
        draw   = @opts.draw   ? false

        if draw
            material = @opts.material ? new THREE.MeshBasicMaterial()
            color    = @opts.color    ? new THREE.Color 1, 1, 1
            @clipCubeMesh = do () =>
                geo  = new THREE.BoxGeometry 2, 2, 2
                mesh = new THREE.Mesh geo, material
                cube = new THREE.BoxHelper mesh
                cube.material.color = color
                @view._context.api.three.scene.add cube
                mesh

        @clipped = @view
            .shader code: clipShader
            .vertex pass: pass
            .shader
                code: clipFragment
                uniforms:
                    range:
                        type: 'f'
                        value: range
                    hilite:
                        type: 'i'
                        value: if hilite then 1 else 0
            .fragment()


# Class for constructing components common to the demos
# Options:
#    mathboxOpts: passed to the mathBox constructor
#    clearColor: THREE's clear color
#    clearOpacity: THREE's clear opacity
#    camera: passed to mathbox.camera()
#    focusDist: mathbox focus distance
#    scaleUI: whether to scale focusDist by min(width, height)/1000
#    doFullScreen: enable screenfull binding to key 'f'

class Demo
    # Construct a mathBox instance, with optional preload
    constructor: (@opts, callback) ->
        @opts ?= {}
        mathboxOpts =
            plugins:     ['core', 'controls', 'cursor']
            controls:
                klass:   THREE.OrbitControls
                parameters:
                    noKeys: true
            mathbox:
                inspect: false
            splash:
                fancy:   true
                color:   "blue"
        extend mathboxOpts, @opts.mathbox ? {}
        clearColor   = @opts.clearColor   ? 0x000000
        clearOpacity = @opts.clearOpacity ? 1.0
        cameraOpts   =
            proxy:    true
            position: [3, 1.5, 1.5]
            lookAt:   [0, 0, 0]
        extend cameraOpts, @opts.camera ? {}
        # Transform camera position (z is up...)
        p = cameraOpts.position
        cameraOpts.position = [-p[0], p[2], -p[1]]
        focusDist    = @opts.focusDist  ? 1.5
        scaleUI      = @opts.scaleUI    ? true
        doFullScreen = @opts.fullscreen ? true

        onPreloaded = () =>
            # Setup mathbox
            @mathbox = mathBox(mathboxOpts)
            @three = @mathbox.three
            @three.renderer.setClearColor new THREE.Color(clearColor), clearOpacity
            @camera = @mathbox.camera(cameraOpts)[0].controller.camera
            @canvas = @mathbox._context.canvas
            if scaleUI
                @mathbox.bind 'focus', () =>
                    focusDist / 1000 * Math.min @canvas.clientWidth, @canvas.clientHeight
            # Setup screenfull
            if doFullScreen
                document.body.addEventListener 'keypress', (event) ->
                    if event.charCode == 'f'.charCodeAt 0 and screenfull.enabled
                        screenfull.toggle()

            callback.apply @

        @decodeQS()

        # Do preloading (only images currently)
        preload = @opts.preload ? {}
        toPreload = 0
        if preload
            for key, value of preload
                toPreload++
                image = new Image()
                @[key] = image
                image.src = value
                image.addEventListener 'load', () ->
                    if --toPreload == 0
                        onPreloaded()
        onPreloaded() unless toPreload > 0

    decodeQS: () ->
        pl = /\+/g
        search = /([^&=]+)=?([^&]*)/g
        decode = (s) -> decodeURIComponent s.replace pl, " "
        query = window.location.search.substring 1
        @urlParams = {}
        while match = search.exec query
            @urlParams[decode match[1]] = decode match[2]
        @urlParams

    view: (opts) -> new View(@mathbox, opts).view
    caption: (text) -> new Caption @mathbox, text
    clipCube: (view, opts) -> new ClipCube view, opts


window.Demo = Demo
