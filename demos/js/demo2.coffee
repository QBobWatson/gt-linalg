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
        @name        = @opts.name      ? "view"
        viewRange    = @opts.viewRange ? [[-10, 10], [-10, 10], [-10, 10]]
        @numDims     = viewRange.length
        viewScale    = @opts.viewScale ? [1, 1, 1]

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


# Make points draggable.
# Options:
#     points: list of draggable points.  The coordinates of these points will be
#         changed by the drag.  Max 254 points.
#     size: size of the draggable point
#     hiliteColor: color (plus opacity) of a hovered point
#     hiliteOpts: other options for the hilite points
#     onDrag: drag callback
#     getMatrix: return a matrix to use as the view matrix
#     eyeMatrix: apply a transformation on eye pass too
#
# Available instance attributes:
#     hovered: index of the point the mouse is hovering over, or -1 if none
#     dragging: point currently being dragged, or -1 if none

class Draggable
    constructor: (@view, @opts) ->
        @opts ?= {}
        name        = @opts.name      ? "draggable"
        @points     = @opts.points
        size        = @opts.size      ? 30
        @onDrag     = @opts.onDrag    ? () ->
        hiliteColor = @opts.hiliteColor ? [0, .5, .5, .75]
        @eyeMatrix  = @opts.eyeMatrix ? new THREE.Matrix4()
        getMatrix   = @opts.getMatrix ? (d) ->
            d.view[0].controller.viewMatrix
        hiliteOpts =
            id:     "#{name}-hilite"
            color:  "white"
            points: "##{name}-points"
            colors: "##{name}-colors"
            size:   size
            zIndex: 2
            zTest:  false
            zWrite: false
        extend hiliteOpts, @opts.hiliteOpts ? {}
        @three = @view._context.api.three
        @canvas = @three.canvas
        @camera = @view._context.api.select("camera")[0].controller.camera

        # State
        @hovered     = -1
        @dragging    = -1
        @mouse       = [-1, -1]
        @activePoint = undefined

        # Scratch
        @projected = new THREE.Vector3()
        @vector    = new THREE.Vector3()
        @matrix    = new THREE.Matrix4()
        @matrixInv = new THREE.Matrix4()

        @scale = 1/4  # Render RTT at quarter resolution
        @viewMatrix = getMatrix @
        @viewMatrixInv = new THREE.Matrix4().getInverse @viewMatrix
        @viewMatrixTrans = @viewMatrix.clone().transpose()
        @eyeMatrixTrans = @eyeMatrix.clone().transpose()
        @eyeMatrixInv = new THREE.Matrix4().getInverse @eyeMatrix

        # Red channel picks out the point
        # Alpha channel for existence
        indices = ([(i+1)/255, 1.0, 0, 0] for i in [0...@points.length])

        @view
            .array
                id:       "#{name}-points"
                channels: 3
                width:    @points.length
                data:     @points
            .array
                id:       "#{name}-index"
                channels: 4
                width:    @points.length
                data:     indices
                live:     false

        rtt = @view.rtt
            id:     "#{name}-rtt"
            size:   'relative'
            width:  @scale
            height: @scale

        rtt
            .transform
                pass:   'eye'
                matrix: Array.prototype.slice.call @eyeMatrixTrans.elements
            # This should really be automatic...
            .transform
                matrix: Array.prototype.slice.call @viewMatrixTrans.elements
            .point
                points:   "##{name}-points"
                colors:   "##{name}-index"
                color:    'white'
                size:     size
                blending: 'no'
            .end()

        # Debug RTT
        # @view.compose opacity: 0.5

        @view
            .array
                id:       "#{name}-colors"
                channels: 4
                width:    @points.length
                expr: (emit, i, t) =>
                    if @dragging == i or @hovered == i
                        # Show the hilite
                        emit.apply null, hiliteColor
                    else
                        emit 1, 1, 1, 0
            .point hiliteOpts

        # Readback RTT pixels
        @readback = @view.readback
            source: "##{name}-rtt"
            type:   'unsignedByte'

        @canvas.addEventListener 'mousedown', @onMouseDown, false
        @canvas.addEventListener 'mousemove', @onMouseMove, false
        @canvas.addEventListener 'mouseup',   @onMouseUp,   false
        @three.on 'post', @post

    onMouseDown: (event) =>
        return if @hovered < 0
        event.preventDefault()
        @dragging = @hovered
        @activePoint = @points[@dragging]

    onMouseMove: (event) =>
        @mouse = [event.offsetX * window.devicePixelRatio,
                  event.offsetY * window.devicePixelRatio]
        @hovered = @getIndexAt @mouse[0], @mouse[1]
        return if @dragging < 0
        event.preventDefault()
        mouseX = event.offsetX / @canvas.offsetWidth * 2 - 1.0
        mouseY = -(event.offsetY / @canvas.offsetHeight * 2 - 1.0)
        # Move the point in the plane parallel to the camera.
        @projected
            .set(@activePoint[0], @activePoint[1], @activePoint[2])
            .applyMatrix4 @viewMatrix
        @matrix.multiplyMatrices @camera.projectionMatrix, @eyeMatrix
        @matrix.multiply @matrixInv.getInverse @camera.matrixWorld
        @projected.applyProjection @matrix
        @vector.set mouseX, mouseY, @projected.z
        @vector.applyProjection @matrixInv.getInverse @matrix
        @vector.applyMatrix4 @viewMatrixInv
        @onDrag.call @, @vector
        @activePoint[0] = @vector.x
        @activePoint[1] = @vector.y
        @activePoint[2] = @vector.z

    onMouseUp: (event) =>
        return if @dragging < 0
        event.preventDefault()
        @dragging = -1
        @activePoint = undefined

    post: () =>
        if @dragging >= 0
            @canvas.style.cursor = 'pointer'
        else if @hovered >= 0
            @canvas.style.cursor = 'pointer'
        else if @three.controls
            @canvas.style.cursor = 'move'
        else
            @canvas.style.cursor = ''
        if @three.controls
            @three.controls.enabled = @hovered < 0 and @dragging < 0

    getIndexAt: (x, y) =>
        data = @readback.get 'data'
        return -1 unless data
        x = Math.floor x * @scale
        y = Math.floor y * @scale
        w = @readback.get 'width'
        h = @readback.get 'height'
        o = (x + w * (h - y - 1)) * 4
        r = data[o]
        a = data[o+3]
        if r? then (if a == 0 then r-1 else -1) else -1


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


class LabeledVectors
    constructor: (view, @opts) ->
        @opts ?= {}
        name    = @opts.name ? "labeled"
        vectors = @opts.vectors
        colors  = @opts.colors
        labels  = @opts.labels
        origins = @opts.origins ? ([0, 0, 0] for [0...vectors.length])
        vectorOpts =
            id:     "#{name}-vectors-drawn"
            points: "##{name}-vectors"
            colors: "##{name}-colors"
            color:  "white"
            end:    true
            size:   5
            width:  5
        extend vectorOpts, @opts.vectorOpts ? {}
        labelOpts =
            id:         "#{name}-vector-labels"
            colors:     "##{name}-colors"
            color:      "white"
            outline:    2
            background: "black"
            size:       15
            offset:     [0, 25]
        extend labelOpts, @opts.labelOpts ? {}
        doZero = @opts.zeroPoints ? false
        zeroOpts =
            id:      "#{name}-zero-points"
            points:  "##{name}-zeros"
            colors:  "##{name}-zero-colors"
            color:   "white"
            size:    20
            visible: false
        extend zeroOpts, @opts.zeroOpts ? {}
        zeroThreshold = @opts.zeroThreshold ? 0.0

        vectorData = []
        for i in [0...vectors.length]
            vectorData.push origins[i]
            vectorData.push vectors[i]

        # vectors
        view
            .array
                id:       "#{name}-vectors"
                channels: 3
                width:    vectors.length
                items:    2
                data:     vectorData
            .array
                id:       "#{name}-colors"
                channels: 4
                width:    colors.length
                data:     colors
            .vector vectorOpts

        # Labels
        if labels?
            view
                .array
                    channels: 3
                    width:    vectors.length
                    expr: (emit, i) ->
                        emit (vectors[i][0] + origins[i][0])/2,
                             (vectors[i][1] + origins[i][1])/2,
                             (vectors[i][2] + origins[i][2])/2
                .text
                    id:    "#{name}-text"
                    live:  false
                    width: labels.length
                    data:  labels
                .label labelOpts

        # Points for when vectors are zero
        if doZero
            zeroData = ([0, 0, 0] for [0...vectors.length])
            view
                .array
                    id:       "#{name}-zero-colors"
                    channels: 4
                    width:    vectors.length
                    expr: (emit, i) ->
                        if Math.abs(vectors[i][0]) < zeroThreshold and
                           Math.abs(vectors[i][1]) < zeroThreshold and
                           Math.abs(vectors[i][2]) < zeroThreshold
                            emit.apply null, colors[i]
                        else
                            emit 0, 0, 0, 0
                .array
                    id:       "#{name}-zeros"
                    channels: 3
                    width:    vectors.length
                    data:     zeroData
            @zeroPoints = view.point zeroOpts


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

    texVector: (x, y, z, opts) ->
        opts ?= {}
        precision = opts.precision ? 2
        ret = ''
        if opts.color?
            ret += "\\color{#{opts.color}}{"
        ret += """
               \\begin{bmatrix}
                   #{x.toFixed precision} \\\\
                   #{y.toFixed precision} \\\\
                   #{z.toFixed precision}
               \\end{bmatrix}
               """
        if opts.color?
            ret += "}"
        ret

    view: (opts) -> new View(@mathbox, opts).view
    caption: (text) -> new Caption @mathbox, text
    clipCube: (view, opts) -> new ClipCube view, opts
    draggable: (view, opts) -> new Draggable view, opts
    labeledVectors: (view, opts) -> new LabeledVectors view, opts


window.Demo = Demo
