"use strict"

################################################################################
# * Utility functions

# Extend an object by another
extend = (obj, src) ->
    for key, val of src
        obj[key] = val if src.hasOwnProperty key

# Orthogonalize linearly independent vectors
orthogonalize = do () ->
    tmpVec = null
    (vec1, vec2) ->
        tmpVec = new THREE.Vector3() unless tmpVec?
        tmpVec.copy vec1.normalize()
        vec2.sub(tmpVec.multiplyScalar vec2.dot vec1).normalize()

# If 'vec' is an array, convert it to a THREE.Vector3()
makeTvec = (vec) ->
    return vec if vec instanceof THREE.Vector3
    ret = new THREE.Vector3()
    ret.set vec[0], vec[1], vec[2] ? 0

# Set a THREE.Vector3 to another THREE.Vector3 or an array
setTvec = (orig, vec) ->
    if vec instanceof THREE.Vector3
        orig.copy vec
    else
        orig.set vec[0], vec[1], vec[2] ? 0


################################################################################
# * Shaders

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


################################################################################
# * Subspace

# Abstract representation of a subspace, which can draw itself
# Options:
#     vectors: a spanning set
#     onDimChange: called when the dimension changes
#     zeroThreshold: a number smaller than this is considered zero, for the
#        purposes of linear independence
# Drawing options:
#     name: object id's will be prefixed with "#{name}"
#     range: make drawn objects at least [-range, range] on a side
#     color: default color of drawn objects
#     noPlane: do not draw planes
#     pointOpts: passed to mathbox.point
#     lineOpts: passed to mathbox.line
#     surfaceOpts: passed to mathbox.surface
#     live: whether the vectors can change
#
# In 2D, the z-coordinate is just always zero.

class Subspace
    constructor: (@opts) ->
        @onDimChange = @opts.onDimChange ? () ->

        @ortho = [new THREE.Vector3(), new THREE.Vector3()]
        @zeroThreshold = @opts.zeroThreshold ? 0.00001

        @numVecs = @opts.vectors.length
        @vectors = []
        @vectors[i] = makeTvec @opts.vectors[i] for i in [0...@numVecs]

        # Scratch
        @tmpVec1 = new THREE.Vector3()
        @tmpVec2 = new THREE.Vector3()

        @drawn = false
        @dim = -1
        @update()

    setVecs: (vecs) =>
        setTvec @vectors[i], vecs[i] for i in [0...@numVecs]
        @update()

    update: () =>
        # Compute the dimension, and an orthonormal basis if dim <= 2
        [vec1, vec2, vec3] = @vectors
        [ortho1, ortho2] = @ortho
        cross = @tmpVec1
        oldDim = @dim

        switch @numVecs
            when 1
                if vec1.lengthSq() <= @zeroThreshold
                    @dim = 0
                else
                    @dim = 1
                    ortho1.copy(vec1).normalize()
            when 2
                cross.crossVectors vec1, vec2
                if cross.lengthSq() <= @zeroThreshold
                    vec1Zero = vec1.lengthSq() <= @zeroThreshold
                    vec2Zero = vec2.lengthSq() <= @zeroThreshold
                    if vec1Zero and vec2Zero
                        @dim = 0
                    else if vec1Zero
                        @dim = 1
                        ortho1.copy(vec2).normalize()
                    else
                        @dim = 1
                        ortho1.copy(vec1).normalize()
                else
                    @dim = 2
                    orthogonalize ortho1.copy(vec1), ortho2.copy(vec2)
            when 3
                cross.crossVectors vec1, vec2
                if Math.abs(cross.dot vec3) > @zeroThreshold
                    @dim = 3
                else # dim <= 2
                    if cross.lengthSq() > @zeroThreshold
                        @dim = 2
                        orthogonalize ortho1.copy(vec1), ortho2.copy(vec2)
                    else
                        cross.crossVectors vec1, vec3
                        if cross.lengthSq() > @zeroThreshold
                            @dim = 2
                            orthogonalize ortho1.copy(vec1), ortho2.copy(vec3)
                        else
                            cross.crossVectors vec2, vec3
                            if cross.lengthSq() > @zeroThreshold
                               @dim = 2
                               orthogonalize ortho1.copy(vec2), ortho2.copy(vec3)
                             # dim <= 1
                            else if vec1.lengthSq() > @zeroThreshold
                                @dim = 1
                                ortho1.copy vec1
                            else if vec2.lengthSq() > @zeroThreshold
                                @dim = 1
                                ortho1.copy vec2
                            else if vec3.lengthSq() > @zeroThreshold
                                @dim = 1
                                ortho1.copy vec3
                            else
                                @dim = 0

        if oldDim != @dim
            @updateDim oldDim

    project: (vec, projected) =>
        vec = setTvec @tmpVec1, vec
        [ortho1, ortho2] = @ortho
        switch @dim
            when 0
                projected.set 0, 0, 0
            when 1
                projected.copy(ortho1).multiplyScalar ortho1.dot(vec)
            when 2
                projected.copy(ortho1).multiplyScalar ortho1.dot(vec)
                @tmpVec2.copy(ortho2).multiplyScalar ortho2.dot(vec)
                projected.add @tmpVec2
            when 3
                projected.copy vec

    # Set up the mathbox elements to draw the subspace if dim < 3
    draw: (view) =>
        name    = @opts.name   ? 'subspace'
        @range  = @opts.range  ? 10.0
        color   = @opts.color  ? 0x880000
        live    = @opts.live   ? true

        @range *= 2

        pointOpts =
            id:      "#{name}-point"
            color:   color
            opacity: 1.0
            size:    15
            visible: false
        extend pointOpts, @opts.pointOpts ? {}
        lineOpts =
            id:      "#{name}-line"
            color:   0x880000
            opacity: 1.0
            stroke:  'solid'
            width:   5
            visible: false
        extend lineOpts, @opts.lineOpts ? {}
        surfaceOpts =
            id:      "#{name}-plane"
            color:   color
            opacity: 0.5
            lineX:   false
            lineY:   false
            fill:    true
            visible: false
        extend surfaceOpts, @opts.surfaceOpts ? {}

        if live or @dim == 0
            view.array
                channels: 3
                width:    1
                live:     live
                data:     [[0, 0, 0]]
            @point = view.point pointOpts

        if (live and @numVecs >= 1) or @dim == 1
            view.array
                channels: 3
                width:    2
                live:     live
                expr: (emit, i) =>
                    if i == 0
                        emit -@ortho[0].x * @range,
                             -@ortho[0].y * @range,
                             -@ortho[0].z * @range
                    else
                        emit  @ortho[0].x * @range,
                              @ortho[0].y * @range,
                              @ortho[0].z * @range
            @line = view.line lineOpts

        if (live and @numVecs >= 2) or @dim == 2
            unless @opts.noPlane
                view.matrix
                    channels: 3
                    width:    2
                    height:   2
                    live:     live
                    expr: (emit, i, j) =>
                        sign1 = if i == 0 then -1 else 1
                        sign2 = if j == 0 then -1 else 1
                        emit sign1 * @ortho[0].x * @range + sign2 * @ortho[1].x * @range,
                             sign1 * @ortho[0].y * @range + sign2 * @ortho[1].y * @range,
                             sign1 * @ortho[0].z * @range + sign2 * @ortho[1].z * @range
                @plane = view.surface surfaceOpts

        @objects = [@point, @line, @plane]

        @drawn = true
        @updateDim -1

    updateDim: (oldDim) =>
        @onDimChange @
        return unless @drawn
        if oldDim >= 0 and oldDim < 3 and @objects[oldDim]?
            @objects[oldDim].set 'visible', false
        if @dim < 3 and @objects[@dim]?
            @objects[@dim].set 'visible', true


################################################################################
# * Linear Combination

# Draw a linear combination of 1, 2, or 3 vectors
# Options:
#     vectors: input vectors
#     colors: colors of the lines
#     labels: vector labels
#     coeffs: .x, .y, .z are the coefficients, or:
#     coeffVars: names of the coefficients
#     lineOpts: passed to mathbox.line
#     pointOpts: passed to mathbox.point for the end point
#     labelOpts: passed to mathbox.label
#
# In 2D, this adds a zero final coordinate to the vectors if necessary

class LinearCombo
    constructor: (view, opts) ->
        name = opts.name ? 'lincombo'
        vectors   = opts.vectors
        colors    = opts.colors
        labels    = opts.labels
        coeffs    = opts.coeffs
        coeffVars = opts.coeffVars ? ['x', 'y', 'z']

        c = (i) -> coeffs[coeffVars[i]]

        lineOpts =
            classes: [name]
            points:  "##{name}-points"
            colors:  "##{name}-colors"
            color:   "white"
            opacity: 0.75
            width:   3
            zIndex:  1
        extend lineOpts, opts.lineOpts ? {}
        pointOpts =
            classes: [name]
            points:  "##{name}-combo"
            color:   0x00ffff
            zIndex:  2
            size:    15
        extend pointOpts, opts.pointOpts ? {}
        labelOpts =
            classes:    [name]
            outline:    2
            background: "black"
            color:      0x00ffff
            offset:     [0, 25]
            zIndex:     3
            size:       15
        extend labelOpts, opts.labelOpts ? {}

        numVecs = vectors.length
        # Extend to 3D vectors
        vec[2] ?= 0 for vec in vectors
        vector1 = vectors[0]
        vector2 = vectors[1]
        vector3 = vectors[2]
        color1 = colors[0]
        color2 = colors[1]
        color3 = colors[2]

        switch numVecs
            when 1
                combine = () =>
                    @combo = [vector1[0]*c(0),
                              vector1[1]*c(0),
                              vector1[2]*c(0)]

                view
                    .array
                        id:       "#{name}-points"
                        channels: 3
                        width:    2
                        items:    1
                        expr: (emit, i) ->
                            if i == 0
                                # starting points of lines
                                emit 0, 0, 0
                            else
                                emit vector1[0]*c(0),
                                     vector1[1]*c(0),
                                     vector1[2]*c(0)
                    .array
                        id:       "#{name}-colors"
                        channels: 4
                        width:    1
                        items:    1
                        data:     [color1]
                    .array
                        id:       "#{name}-combo"
                        channels: 3
                        width:    1
                        expr: (emit) -> emit.apply null, combine()
            when 2
                combine = () =>
                    @combo = [vector1[0]*c(0) + vector2[0]*c(1),
                              vector1[1]*c(0) + vector2[1]*c(1),
                              vector1[2]*c(0) + vector2[2]*c(1)]
                view
                    .array
                        id:       "#{name}-points"
                        channels: 3
                        width:    2
                        items:    4
                        expr: (emit, i) ->
                            vec1 = [vector1[0]*c(0),
                                    vector1[1]*c(0),
                                    vector1[2]*c(0)]
                            vec2 = [vector2[0]*c(1),
                                    vector2[1]*c(1),
                                    vector2[2]*c(1)]
                            vec12 = [vec1[0] + vec2[0],
                                     vec1[1] + vec2[1],
                                     vec1[2] + vec2[2]]
                            if i == 0
                                # starting points of lines
                                emit 0, 0, 0
                                emit 0, 0, 0
                                emit.apply null, vec1
                                emit.apply null, vec2
                            else
                                emit.apply null, vec1
                                emit.apply null, vec2
                                emit.apply null, vec12
                                emit.apply null, vec12
                    .array
                        id:       "#{name}-colors"
                        channels: 4
                        width:    2
                        items:    4
                        data:     [color1, color2, color2, color1,
                                   color1, color2, color2, color1]
                    .array
                        id:       "#{name}-combo"
                        channels: 3
                        width:    1
                        expr: (emit) -> emit.apply null, combine()
            when 3
                combine = () =>
                    @combo = \
                        [vector1[0]*c(0) + vector2[0]*c(1) + vector3[0]*c(2),
                         vector1[1]*c(0) + vector2[1]*c(1) + vector3[1]*c(2),
                         vector1[2]*c(0) + vector2[2]*c(1) + vector3[2]*c(2)]

                view
                    .array
                        id:       "#{name}-points"
                        channels: 3
                        width:    2
                        items:    12
                        expr: (emit, i) ->
                            vec1 = [vector1[0]*c(0),
                                    vector1[1]*c(0),
                                    vector1[2]*c(0)]
                            vec2 = [vector2[0]*c(1),
                                    vector2[1]*c(1),
                                    vector2[2]*c(1)]
                            vec3 = [vector3[0]*c(2),
                                    vector3[1]*c(2),
                                    vector3[2]*c(2)]
                            vec12 = [vec1[0]+vec2[0], vec1[1]+vec2[1], vec1[2]+vec2[2]]
                            vec13 = [vec1[0]+vec3[0], vec1[1]+vec3[1], vec1[2]+vec3[2]]
                            vec23 = [vec2[0]+vec3[0], vec2[1]+vec3[1], vec2[2]+vec3[2]]
                            vec123 = [vec1[0] + vec2[0] + vec3[0],
                                      vec1[1] + vec2[1] + vec3[1],
                                      vec1[2] + vec2[2] + vec3[2]]
                            if i == 0
                                # starting points of lines
                                emit 0, 0, 0
                                emit 0, 0, 0
                                emit 0, 0, 0
                                emit.apply null, vec1
                                emit.apply null, vec1
                                emit.apply null, vec2
                                emit.apply null, vec2
                                emit.apply null, vec3
                                emit.apply null, vec3
                                emit.apply null, vec12
                                emit.apply null, vec13
                                emit.apply null, vec23
                            else
                                # ending points of lines
                                emit.apply null, vec1
                                emit.apply null, vec2
                                emit.apply null, vec3
                                emit.apply null, vec12
                                emit.apply null, vec13
                                emit.apply null, vec12
                                emit.apply null, vec23
                                emit.apply null, vec13
                                emit.apply null, vec23
                                emit.apply null, vec123
                                emit.apply null, vec123
                                emit.apply null, vec123
                    .array
                        id:       "#{name}-colors"
                        channels: 4
                        width:    2
                        items:    12
                        data:     [color1, color2, color3, color2, color3, color1,
                                   color3, color1, color2, color3, color2, color1,
                                   color1, color2, color3, color2, color3, color1,
                                   color3, color1, color2, color3, color2, color1]
                    .array
                        id:       "#{name}-combo"
                        channels: 3
                        width:    1
                        expr: (emit) -> emit.apply null, combine()

        view
            .line lineOpts
            # Label
            .point pointOpts
            .text
                live:  true
                width: 1
                expr: (emit) ->
                    ret = c(0).toFixed(2) + labels[0]
                    if numVecs >= 2
                        b = Math.abs c(1)
                        add = if c(1) >= 0 then "+" else "-"
                        ret += add + b.toFixed(2) + labels[1]
                    if numVecs >= 3
                        cc = Math.abs c(2)
                        add = if c(2) >= 0 then "+" else "-"
                        ret += add + cc.toFixed(2) + labels[2]
                    emit ret
            .label labelOpts

        @combine = combine


################################################################################
# * Grid

# Draw a grid along one, two, or three vectors
# Options:
#     name: id of the drawn primitive
#     vectors: vectors along which to draw the grid
#     numLines: number of lines or ticks to draw (minus 1)
#     live: whether the vectors can move
#
# In 2D, this adds a zero final coordinate to the vectors if necessary

class Grid
    constructor: (view, opts) ->
        name     = opts.name     ? "vecgrid"
        vectors  = opts.vectors
        numLines = opts.numLines ? 40
        live     = opts.live     ? true

        ticksOpts =
            id:      name
            opacity: 1
            size:    20
            normal:  false
            color:   0xcc0000
        extend ticksOpts, opts.ticksOpts ? {}

        lineOpts =
            id:      name
            opacity: .75
            stroke:  'solid'
            width:   3
            color:   0x880000
            zBias:   2
        extend lineOpts, opts.lineOpts ? {}

        numVecs = vectors.length
        # Extend to 3D
        vec[2] ?= 0 for vec in vectors
        [vector1, vector2, vector3] = vectors
        perSide = numLines/2

        if numVecs == 1
            view.array
                channels: 3
                live:     live
                width:    numLines + 1
                expr: (emit, i) ->
                    i -= perSide
                    emit i * vector1[0], i * vector1[1], i * vector1[2]
            @ticks = view.ticks ticksOpts
            return

        if numVecs == 2
            totLines = (numLines + 1) * 2
            doLines = (emit, i) ->
                for j in [-perSide..perSide]
                    start = if i == 0 then -perSide else perSide
                    # First axis
                    emit start*vector1[0] + j*vector2[0],
                         start*vector1[1] + j*vector2[1],
                         start*vector1[2] + j*vector2[2]
                    # Second axis
                    emit start*vector2[0] + j*vector1[0],
                         start*vector2[1] + j*vector1[1],
                         start*vector2[2] + j*vector1[2]

        if numVecs == 3
            totLines = (numLines + 1) * (numLines + 1) * 3;
            doLines = (emit, i) ->
                for j in [-perSide..perSide]
                    for k in [-perSide..perSide]
                        start = if i == 0 then -perSide else perSide
                        # First axis
                        emit start*vector1[0] + j*vector2[0] + k*vector3[0],
                             start*vector1[1] + j*vector2[1] + k*vector3[1],
                             start*vector1[2] + j*vector2[2] + k*vector3[2]
                        # Second axis
                        emit start*vector2[0] + j*vector1[0] + k*vector3[0],
                             start*vector2[1] + j*vector1[1] + k*vector3[1],
                             start*vector2[2] + j*vector1[2] + k*vector3[2]
                        # Third axis
                        emit start*vector3[0] + j*vector1[0] + k*vector2[0],
                             start*vector3[1] + j*vector1[1] + k*vector2[1],
                             start*vector3[2] + j*vector1[2] + k*vector2[2]

        view.array
            channels: 3
            live:     live
            width:    2
            items:    totLines
            expr:     doLines
        @lines = view.line lineOpts


################################################################################
# * Caption

# Caption in the upper-left part of the screen (controlled by css)

class Caption
    constructor: (@mathbox, text) ->
        @div = @mathbox._context.overlays.div
        @label = document.createElement 'div'
        @label.className = "overlay-text"
        @label.innerHTML = text
        @div.appendChild @label


################################################################################
# * Popup

# Popup in the bottom part of the screen (controlled by css)

class Popup
    constructor: (@mathbox, text) ->
        @div = @mathbox._context.overlays.div
        @popup = document.createElement 'div'
        @popup.className = "overlay-popup"
        @popup.style.display = 'none'
        if text?
            @popup.innerHTML = text
        @div.appendChild @popup

    show: (text) ->
        if text?
            @popup.innerHTML = text
        @popup.style.display = ''

    hide: () -> @popup.style.display = 'none'


################################################################################
# * View

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

        if @numDims == 3
            viewScale[0] = -viewScale[0]
            viewOpts =
                range:    viewRange
                scale:    viewScale
                # z is up...
                rotation: [-π/2, 0, 0]
                id:       "#{@name}-view"
        else
            viewOpts =
                range:    viewRange
                scale:    viewScale
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


################################################################################
# * Draggable

# Make points draggable.
# Options:
#     points: list of draggable points.  The coordinates of these points will be
#         changed by the drag.  Max 254 points.
#     size: size of the draggable point
#     hiliteColor: color (plus opacity) of a hovered point
#     hiliteOpts: other options for the hilite points
#     onDrag: drag callback where you can modify the new vector
#     postDrag: drag callback where the vector has been already updated
#     getMatrix: return a matrix to use as the view matrix
#     eyeMatrix: apply a transformation on eye pass too
#     is2D: the z-coordinate is always zero in drags
#
# Available instance attributes:
#     hovered: index of the point the mouse is hovering over, or -1 if none
#     dragging: point currently being dragged, or -1 if none
#
# In 2D, this adds a zero final coordinate to the vectors if necessary

class Draggable
    constructor: (@view, @opts) ->
        @opts ?= {}
        name        = @opts.name      ? "draggable"
        @points     = @opts.points
        size        = @opts.size      ? 30
        @onDrag     = @opts.onDrag    ? () ->
        @postDrag   = @opts.postDrag  ? () ->
        @is2D       = @opts.is2D      ? false
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

        # Extend to 3D
        point[2] ?= 0 for point in @points

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
        @vector.z = 0 if @is2D
        @onDrag.call @, @vector
        @activePoint[0] = @vector.x
        @activePoint[1] = @vector.y
        @activePoint[2] = @vector.z
        @postDrag.call @

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


################################################################################
# * ClipCube

# Makes a mathbox API that clips its contents to the cube [-range,range]^3.
# Optionally draws the cube too.
# Options:
#    range: range to clip
#    pass: transform pass to apply the clip to
#    hilite: hilite boundary
#    draw: draw the cube
#    material: material to draw the cube
#    color: color for the wireframe cube
#
# Works equally well for a 2D view

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
            @mesh = do () =>
                geo  = new THREE.BoxGeometry 2, 2, 2
                mesh = new THREE.Mesh geo, material
                cube = new THREE.BoxHelper mesh
                cube.material.color = color
                @view._context.api.three.scene.add cube
                mesh

        @uniforms =
            range:
                type: 'f'
                value: range
            hilite:
                type: 'i'
                value: if hilite then 1 else 0

        @clipped = @view
            .shader code: clipShader
            .vertex pass: pass
            .shader
                code: clipFragment
                uniforms: @uniforms
            .fragment()


################################################################################
# * Labeled vectors

# Constructs mathbox primitives for vectors with labels
# Options:
#     name: ids begin with "#{name}-"
#     vectors: heads of vectors to draw (dynamic array)
#     origins: tails of the vectors
#     colors: colors to draw the vectors
#     labels: labels for the vectors
#     live: if the vectors can move
#     vectorOpts: passed to mathbox.vector
#     labelOpts: passed to mathbox.label
#     zeroPoints: draw a point when a vector is zero
#     zeroThreshold: a vector is considered "zero" if it's this small
#     zeroOpts: passed to mathbox.point
#
# In 2D, this adds a zero final coordinate to the vectors if necessary

class LabeledVectors
    constructor: (view, @opts) ->
        @opts ?= {}
        name    = @opts.name ? "labeled"
        vectors = @opts.vectors
        colors  = @opts.colors
        labels  = @opts.labels
        origins = @opts.origins ? ([0, 0, 0] for [0...vectors.length])
        live    = @opts.live ? true
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
        extend zeroOpts, @opts.zeroOpts ? {}
        zeroThreshold = @opts.zeroThreshold ? 0.0

        vectorData = []
        # Extend to 3D
        vec[2] ?= 0 for vec in vectors
        vec[2] ?= 0 for vec in origins
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
                live:     live
            .array
                id:       "#{name}-colors"
                channels: 4
                width:    colors.length
                data:     colors
                live:     live
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
                    live:     live
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
                    live:     live
                    expr: (emit, i) ->
                        if vectors[i][0] * vectors[i][0] +
                           vectors[i][1] * vectors[i][1] +
                           vectors[i][2] * vectors[i][2] <=
                           zeroThreshold * zeroThreshold
                            emit.apply null, colors[i]
                        else
                            emit 0, 0, 0, 0
                .array
                    id:       "#{name}-zeros"
                    channels: 3
                    width:    vectors.length
                    data:     zeroData
                    live:     false
            @zeroPoints = view.point zeroOpts
            @zeroPoints.bind 'visible', () ->
                for i in [0...vectors.length]
                    if vectors[i][0] * vectors[i][0] +
                       vectors[i][1] * vectors[i][1] +
                       vectors[i][2] * vectors[i][2] <=
                       zeroThreshold * zeroThreshold
                        return true
                return false


################################################################################
# * Demo

# Class for constructing components common to the demos
# Options:
#    mathboxOpts: passed to the mathBox constructor
#    clearColor: THREE's clear color
#    clearOpacity: THREE's clear opacity
#    camera: passed to mathbox.camera()
#    cameraPosFromQS: read camera position from query string
#    focusDist: mathbox focus distance
#    scaleUI: whether to scale focusDist by min(width, height)/1000
#    doFullScreen: enable screenfull binding to key 'f'

class Demo
    # Construct a mathBox instance, with optional preload
    constructor: (@opts, callback) ->
        @decodeQS()

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
        if @opts.cameraPosFromQS ? true and @urlParams.camera?
            cameraOpts.position = @urlParams.camera.split(",").map parseFloat
        # Transform camera position (z is up...)
        p = cameraOpts.position
        cameraOpts.position = [-p[0], p[2], -p[1]]
        focusDist    = @opts.focusDist  ? 1.5
        scaleUI      = @opts.scaleUI    ? true
        doFullScreen = @opts.fullscreen ? true
        @dims        = @opts.dims       ? 3

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

    texVector: (vec, opts) ->
        opts ?= {}
        precision = opts.precision ? 2
        vec = vec.slice(0, @dims)
        if precision >= 0
            for coord, i in vec
                vec[i] = coord.toFixed precision
        ret = ''
        if opts.color?
            ret += "\\color{#{opts.color}}{"
        ret += "\\begin{bmatrix}"
        ret += vec.join "\\\\"
        ret += "\\end{bmatrix}"
        if opts.color?
            ret += "}"
        ret

    texSet: (vecs, opts) =>
        opts ?= {}
        colors = opts.colors
        precision = opts.precision ? 2
        str = "\\left\\{"
        for vec, i in vecs
            if colors?
                opts.color = colors[i]
            str += @texVector vec, opts
            if i+1 < vecs.length
                str += ",\\,"
        str + "\\right\\}"

    texCombo: (vecs, coeffs, opts) =>
        opts ?= {}
        colors = opts.colors
        precision = opts.precision ? 2
        str = ''
        for vec, i in vecs
            if coeffs[i] != 1
                if coeffs[i] == -1
                    str += '-'
                else
                    str += coeffs[i].toFixed precision
            if colors?
                opts.color = colors[i]
            str += @texVector vec, opts
            if i+1 < vecs.length and coeffs[i+1] >= 0
                str += ' + '
        str

    texMatrix: (cols, opts) ->
        opts ?= {}
        colors = opts.colors
        precision = opts.precision ? 2
        str = "\\begin{bmatrix}"
        for i in [0...@dims]
            for j in [0...cols.length]
                if colors?
                    str += "\\color{#{colors[j]}}{"
                if precision >= 0
                    str += cols[j][i].toFixed precision
                else
                    str += cols[j][i]
                if colors?
                    str += "}"
                str += "&" if j+1 < cols.length
            str += "\\\\" if i+1 < @dims
        str += "\\end{bmatrix}"

    moveCamera: (x, y, z) ->
        @camera.position.set -x, z, -y

    view: (opts) ->
        opts ?= {}
        if @urlParams.range?
            r = parseFloat @urlParams.range
            opts.viewRange ?= [[-r, r], [-r, r], [-r, r]]
        new View(@mathbox, opts).view

    caption: (text) -> new Caption @mathbox, text
    popup: (text) -> new Popup @mathbox, text
    clipCube: (view, opts) -> new ClipCube view, opts
    draggable: (view, opts) -> new Draggable view, opts
    linearCombo: (view, opts) -> new LinearCombo view, opts
    grid: (view, opts) -> new Grid view, opts
    labeledVectors: (view, opts) -> new LabeledVectors view, opts
    subspace: (opts) -> new Subspace opts


################################################################################
# * Demo2D

class Demo2D extends Demo
    constructor: (opts, callback) ->
        opts                 ?= {}
        opts.dims            ?= 2
        opts.mathbox         ?= {}
        opts.mathbox.plugins ?= ['core']

        # Setup fake orthographic camera
        ortho = opts.ortho ? 10000
        opts.mathbox.camera      ?= {}
        opts.mathbox.camera.near ?= ortho/4
        opts.mathbox.camera.far  ?= ortho*4
        opts.camera              ?= {}
        opts.camera.proxy        ?= false
        opts.camera.position     ?= [0, -ortho, 0]
        opts.camera.lookAt       ?= [0, 0, 0]
        opts.camera.up           ?= [1, 0, 0]
        vertical = opts.vertical ? 1.1
        opts.camera.fov          ?= Math.atan(vertical/ortho) * 360 / π
        opts.focusDist           ?= ortho/1.5

        super opts, callback

    view: (opts) ->
        opts ?= {}
        if @urlParams.range?
            r = parseFloat @urlParams.range
            opts.viewRange ?= [[-r, r], [-r, r]]
        else
            opts.viewRange ?= [[-10, 10], [-10, 10]]
        new View(@mathbox, opts).view

    draggable: (view, opts) ->
        opts ?= {}
        opts.is2D ?= true
        new Draggable view, opts


################################################################################
# * Globals

window.Demo   = Demo
window.Demo2D = Demo2D
