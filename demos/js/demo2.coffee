"use strict"

################################################################################
# * Color palette

# Keep this in sync with jdr-tikz.sty
palette =
    red:    [0.8941, 0.1020, 0.1098]
    blue:   [0.2157, 0.4941, 0.7216]
    green:  [0.3020, 0.6863, 0.2902]
    violet: [0.5961, 0.3059, 0.6392]
    orange: [1.0000, 0.4980, 0.0000]
    yellow: [0.7000, 0.7000, 0.0000]
    brown:  [0.6510, 0.3373, 0.1569]
    pink:   [0.9686, 0.5059, 0.7490]

class Color
    constructor: (args...) ->
        @r = 1
        @g = 1
        @b = 1
        if args.length > 0
            @set.apply @, args

    set: (args...) =>
        # Copied from THREE.js
        if args.length == 3 or args.length == 4
            [@r, @g, @b] = args
        else if args[0] instanceof Array
            @set.apply @, args[0]
        else if args[0] instanceof Color or args[0] instanceof THREE.Color
            [@r, @g, @b] = [args[0].r, args[0].g, args[0].b]
        else if typeof args[0] == 'number'
            hex = Math.floor args[0]
            @r = (hex >> 16 & 255) / 255
            @g = (hex >> 8  & 255) / 255
            @b = (hex       & 255) / 255
        else if typeof args[0] == 'string'
            style = args[0]
            # rgb(255,0,0)
            if /^rgb\((\d+), ?(\d+), ?(\d+)\)$/i.test style
                color = /^rgb\((\d+), ?(\d+), ?(\d+)\)$/i.exec style
                @r = Math.min(255, parseInt(color[1], 10)) / 255
                @g = Math.min(255, parseInt(color[2], 10)) / 255
                @b = Math.min(255, parseInt(color[3], 10)) / 255
            # rgb(100%,0%,0%)
            else if  /^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$/i.test style
                color = /^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$/i.exec style
                @r = Math.min(100, parseInt(color[1], 10)) / 100
                @g = Math.min(100, parseInt(color[2], 10)) / 100
                @b = Math.min(100, parseInt(color[3], 10)) / 100
            # #ff0000
            else if /^\#([0-9a-f]{6})$/i.test style
                color = /^\#([0-9a-f]{6})$/i.exec style
                @set parseInt(color[1], 16)
            # #f00
            else if /^\#([0-9a-f])([0-9a-f])([0-9a-f])$/i.test style
                color = /^\#([0-9a-f])([0-9a-f])([0-9a-f])$/i.exec style
                @set parseInt(color[1]+color[1]+color[2]+color[2]+color[3]+color[3], 16)
            # red
            else if /^(\w+)$/i.test style
                @set palette[style]

        @r = Math.min(1.0, Math.max(0.0, @r))
        @g = Math.min(1.0, Math.max(0.0, @g))
        @b = Math.min(1.0, Math.max(0.0, @b))

        @

    hex: () => (@r * 255) << 16 ^ (@g * 255) << 8 ^ (@b * 255) << 0

    str: () => '#' + ('000000' + @hex().toString(16)).slice(-6)

    arr: (args...) =>
        if args.length == 0
            return [@r, @g, @b]
        [@r, @g, @b, args[0]]

    three: () => new THREE.Color @r, @g, @b

    hsl: () =>
        max = Math.max @r, @g, @b
        min = Math.min @r, @g, @b
        l = (max + min) / 2
        h = s = 0
        if max != min
            d = max - min
            s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
            switch max
                when @r
                    h = (@g - @b) / d + (if @g < @b then 6 else 0)
                when @g
                    h = (@b - @r) / d + 2
                when @b
                    h = (@r - @g) / d + 4
            h /= 6
        [h, s, l]

    fromHSL: (h, s, l) =>
        h = Math.min(1.0, Math.max(0.0, h))
        s = Math.min(1.0, Math.max(0.0, s))
        l = Math.min(1.0, Math.max(0.0, l))
        if s == 0
            @r = @g = @b = l
        else
            hue2rgb = (p, q, t) ->
                if t < 0
                     t += 1
                if t > 1
                    t -= 1
                if t < 1/6
                    return p + (q - p) * 6 * t
                if t < 1/2
                    return q
                if t < 2/3
                    return p + (q - p) * (2/3 - t) * 6
                return p

            q = if l < 0.5 then l * (1 + s) else l + s - l * s
            p = 2 * l - q

            @r = hue2rgb p, q, h + 1/3
            @g = hue2rgb p, q, h
            @b = hue2rgb p, q, h - 1/3

        @

    brighten: (pct) =>
        [h, s, l] = @hsl()
        new Color().fromHSL(h, s, l + pct)
    darken: (pct) => @brighten -pct


################################################################################
# * Utility functions

# Test via a getter in the options object to see if the passive property is accessed
supportsPassive = false
try
    opts = Object.defineProperty({}, 'passive',
        get: () -> supportsPassive = true
    )
    window.addEventListener "testPassive", null, opts
    window.removeEventListener "testPassive", null, opts
catch e then

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

# Row reduce a matrix (in-place)
# Return [basis for null space,
#         basis for col space,
#         E st EA = rref,
#         f(b) = specific solution]
rowReduce = (M, opts) ->
    orig = (c.slice() for c in M)
    opts ?= {}
    m = opts.rows ? M[0].length
    n = opts.cols ? M.length
    ε = opts.epsilon ? 1e-5
    row = 0  # Current row
    col = 0  # Current pivot column
    pivots = []
    lastPivot = -1
    noPivots = []
    colBasis = []
    nulBasis = []
    # Start with m by m identity matrix, then do the same row ops
    E = ((0 for [0...m]) for [0...m])
    E[i][i] = 1 for i in [0...m]
    while true
        if col == n
            break
        if row == m
            noPivots.push k for k in [col...n]
            break
        # Find max in this column
        maxEl = Math.abs M[col][row]
        maxRow = row
        for k in [row+1...m]
            if Math.abs(M[col][k]) > maxEl
                maxEl = Math.abs M[col][k]
                maxRow = k
        if Math.abs(maxEl) < ε
            # No pivot in this column
            noPivots.push col
            col++
            continue
        # Swap max row with current row
        for k in [0...n]
            [M[k][maxRow], M[k][row]] = [M[k][row], M[k][maxRow]]
        for k in [0...m]
            [E[k][maxRow], E[k][row]] = [E[k][row], E[k][maxRow]]
        # Clear entries below (i,col)
        pivots.push [row, col]
        colBasis.push orig[col]
        lastPivot = row
        pivot = M[col][row]
        for k in [row+1...m]
            c = M[col][k] / pivot
            continue if c == 0
            M[col][k] = 0
            M[j][k] -= c * M[j][row] for j in [col+1...n]
            E[j][k] -= c * E[j][row] for j in [0...m]
        row++
        col++
    # Clear above pivot columns
    for [row, col] in pivots.reverse()
        pivot = M[col][row]
        # Divide by the pivot
        M[col][row] = 1
        for k in [col+1...n]
            M[k][row] /= pivot
        for k in [0...m]
            E[k][row] /= pivot
        for k in [0...row]
            c = M[col][k]
            M[col][k] = 0
            for j in [col+1...n]
                M[j][k] -= c * M[j][row]
            for j in [0...m]
                E[j][k] -= c * E[j][row]
    # Compute basis of null space
    for i in noPivots
        do () ->
            vec = (0 for [0...n])
            vec[i] = 1
            for [row, col] in pivots
                vec[col] = -M[i][row]
            nulBasis.push vec
    # Function that computes a specific solution
    # Returns null for inconsistent
    f = (b, ret) ->
        Eb = []
        for i in [0...m]
            x = 0
            x += E[j][i] * b[j] for j in [0...m]
            Eb.push x
        for i in [lastPivot+1...m]
            return null if Math.abs(Eb[i]) > ε
        ret ?= (0 for [0...n])
        for [row, col] in pivots
            ret[col] = Eb[row]
        ret
    return [nulBasis, colBasis, E, f]

# Find the eigenvalues of a 2x2 or 3x3 matrix
# Must include roots.js
# Returns [real, cplx] where each is a list of [root, multiplicity]
eigenvalues = (mat) ->
    switch mat.length
        when 2
            [[a, b], [c, d]] = mat
            charPoly = [a*d-b*c, -a-d, 1]
            return findRoots 1, -a-d, a*d-b*c
        when 3
            [[a, b, c], [d, e, f], [g, h, i]] = mat
            return findRoots 1, -a-e-i, a*e + a*i + e*i - b*d - c*g - f*h,
                -a*e*i - b*f*g - c*d*h + a*f*h + b*d*i + c*e*g,

# Poor man's listen / trigger mix-in
addEvents = (cls) ->
    cls.prototype.on = (types, callback) ->
        if not (types instanceof Array)
            types = [types]
        @_listeners ?= {}
        for type in types
            @_listeners[type] ?= []
            @_listeners[type].push callback
        @
    cls.prototype.off = (types, callback) ->
        if not (types instanceof Array)
            types = [types]
        for type in types
            idx = @_listeners?[type]?.indexOf callback
            if idx? and idx >= 0
                @_listeners[type].splice idx, 1
        @
    cls.prototype.trigger = (event) ->
        type = event.type
        event.target = @
        listeners = @_listeners?[type]?.slice()
        return unless listeners?
        for callback in listeners
            callback.call @, event, @
            if callback.triggerOnce
                @off type, callback
        @


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
        rgba = getShadedColor(rgba);

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

noShadeFragment = \
    """
    vec4 getShadedColor(vec4 rgba) {
        return rgba;
    }
    """

shadeFragment = \
    """
    varying vec3 vNormal;
    varying vec3 vLight;
    varying vec3 vPosition;

    vec3 offSpecular(vec3 color) {
      vec3 c = 1.0 - color;
      return 1.0 - c * c;
    }

    vec4 getShadedColor(vec4 rgba) {

      vec3 color = rgba.xyz;
      vec3 color2 = offSpecular(rgba.xyz);

      vec3 normal = normalize(vNormal);
      vec3 light = normalize(vLight);
      vec3 position = normalize(vPosition);

      float side    = gl_FrontFacing ? -1.0 : 1.0;
      float cosine  = side * dot(normal, light);
      float diffuse = mix(max(0.0, cosine), .5 + .5 * cosine, .1);

      vec3  halfLight = normalize(light + position);
    	float cosineHalf = max(0.0, side * dot(normal, halfLight));
    	float specular = pow(cosineHalf, 16.0);

    	return vec4(color * (diffuse * .9 + .05) + .25 * color2 * specular, rgba.a);
    }
    """

################################################################################
# * URL param parsing

evExpr = (expr) ->
    try return exprEval.Parser.evaluate expr
    catch
        0

class URLParams
    constructor: () ->
        pl = /\+/g
        search = /([^&=]+)=?([^&]*)/g
        decode = (s) -> decodeURIComponent s.replace pl, " "
        query = window.location.search.substring 1
        while match = search.exec query
            @[decode match[1]] = decode match[2]

    # 'type' is for type conversion
    # Possibilities are:
    #   str
    #   str[] (,-separated)
    #   int
    #   int[] (,-separated)
    #   float
    #   float[] (,-separated)
    #   matrix (, and :-separated)
    #   bool (true/yes/on false/no/off; other values give the default)
    get: (key, type='str', def=undefined) =>
        val = @[key]
        if val?
            switch type
                when 'str'
                    return val
                when 'str[]'
                    return val.split ','
                when 'float'
                    return evExpr val
                when 'float[]'
                    return val.split(',').map evExpr
                when 'int'
                    return parseInt val
                when 'int[]'
                    return val.split(',').map parseInt
                when 'bool'
                    if val in ['true', 'yes', 'on']
                        return true
                    if val in ['false', 'no', 'off']
                        return false
                    if def?
                        return def
                    return false
                when 'matrix'
                    return val.split(':').map (s) -> s.split(',').map evExpr
        else
            if def?
                return def
            switch type
                when 'str'
                    return ''
                when 'float'
                    return 0.0
                when 'int'
                    return 0
                when 'str[]', 'float[]', 'int[]', 'matrix'
                    return []
                when 'bool'
                    return false

urlParams = new URLParams()


################################################################################
# * Orbit controls

# Modified from three.js OrbitControls:
#  * Can set 'up'
#  * Can control multiple cameras

class OrbitControls
    constructor: (@camera, domElement) ->
        THREE.EventDispatcher.prototype.apply @

        @domElement = domElement ? document

        @enabled         = true
        @target          = new THREE.Vector3()
        @noZoom          = false
        @zoomSpeed       = 1.0
        @minDistance     = 0
        @maxDistance     = Infinity
        @noRotate        = false
        @rotateSpeed     = 1.0
        @noPan           = false
        @keyPanSpeed     = 7.0
        @autoRotate      = false
        @autoRotateSpeed = 2.0
        @minPolarAngle   = 0
        @maxPolarAngle   = Math.PI
        @noKeys          = true
        @keys =
            LEFT:   37
            UP:     38
            RIGHT:  39
            BOTTOM: 40
        @clones = []

        # Internal state
        @EPS = 0.000001

        @rotateStart = new THREE.Vector2()
        @rotateEnd   = new THREE.Vector2()
        @rotateDelta = new THREE.Vector2()

        @panStart   = new THREE.Vector2()
        @panEnd     = new THREE.Vector2()
        @panDelta   = new THREE.Vector2()
        @panOffset  = new THREE.Vector3()
        @panCurrent = new THREE.Vector3()

        @offset = new THREE.Vector3()

        @dollyStart = new THREE.Vector2()
        @dollyEnd   = new THREE.Vector2()
        @dollyDelta = new THREE.Vector2()

        @phiDelta   = 0
        @thetaDelta = 0
        @scale      = 1

        @lastPosition = new THREE.Vector3()

        @STATE =
            NONE:        -1
            ROTATE:       0
            DOLLY:        1
            PAN:          2
            TOUCH_ROTATE: 3
            TOUCH_DOLLY:  4
            TOUCH_PAN:    5

        @state = @STATE.NONE

        # for reset
        @target0   = @target.clone()
        @position0 = @camera.position.clone()

        @updateCamera()

        # events
        @changeEvent = type: 'change'
        @startEvent  = type: 'start'
        @endEvent    = type: 'end'

        # install listeners
        @domElement.addEventListener 'contextmenu',
            ((event) -> event.preventDefault()), false
        @domElement.addEventListener 'mousedown',      @onMouseDown,  false
        @domElement.addEventListener 'mousewheel',     @onMouseWheel, false
        @domElement.addEventListener 'touchstart',     @touchStart,   false
        window     .addEventListener 'keydown',        @onKeyDown,    false

        # force an update at start
        @update()

    enable: (val) =>
        @enabled = val
        if not @enabled
            de = document.documentElement
            if @state in [@STATE.ROTATE, @STATE.DOLLY, @STATE.PAN]
                de.removeEventListener 'mousemove', @onMouseMove, false
                de.removeEventListener 'mouseup',   @onMouseUp,   false
                @dispatchEvent @endEvent
            else if @state in [@STATE.TOUCH_ROTATE, @STATE.TOUCH_DOLLY, @STATE.TOUCH_PAN]
                de.removeEventListener 'touchend',    @touchEnd,  false
                de.removeEventListener 'touchmove',   @touchMove, false
                de.removeEventListener 'touchcancel', @touchEnd,  false
                @dispatchEvent @endEvent
            @state = @STATE.NONE

    updateCamera: () =>
        # so camera.up is the orbit axis
        @quat = new THREE.Quaternion().setFromUnitVectors(
            @camera.up, new THREE.Vector3 0, 1, 0)
        @quatInverse = @quat.clone().inverse()
        @update()

    getAutoRotationAngle: () => 2 * Math.PI / 60 / 60 * @autoRotateSpeed
    rotateLeft: (angle) => @thetaDelta -= angle ? @getAutoRotationAngle()
    rotateUp: (angle) => @phiDelta -= angle ? @getAutoRotationAngle()
    getZoomScale: () => Math.pow 0.95, @zoomSpeed
    dollyIn: (dollyScale) => @scale /= dollyScale ? @getZoomScale()
    dollyOut: (dollyScale) => @scale *= dollyScale ? @getZoomScale()

    # pass in distance in world space to move left
    panLeft: (distance) =>
        te = @camera.matrix.elements
        # get X column of matrix
        @panOffset.set te[0], te[1], te[2]
        @panOffset.multiplyScalar -distance
        @panCurrent.add @panOffset

    # pass in distance in world space to move up
    panUp: (distance) =>
        te = @camera.matrix.elements
        # get Y column of matrix
        @panOffset.set te[4], te[5], te[6]
        @panOffset.multiplyScalar distance
        @panCurrent.add @panOffset

    # pass in x,y of change desired in pixel space,
    # right and down are positive
    pan: (deltaX, deltaY) =>
        element = if @domElement == document then document.body else @domElement
        if @camera.fov?
            # perspective
            position       = @camera.position
            offset         = position.clone().sub @target
            targetDistance = offset.length()
            # half of the fov is center to top of screen
            targetDistance *= Math.tan(@camera.fov/2 * Math.PI / 180.0)
            # we actually don't use screenWidth, since perspective camera
            # is fixed to screen height
            @panLeft(2 * deltaX * targetDistance / element.clientHeight)
            @panUp(2 * deltaY * targetDistance / element.clientHeight)

        else if @camera.top?
            # orthographic
            @panLeft(deltaX * (@camera.right - @camera.left)   / element.clientWidth)
            @panUp  (deltaY * (@camera.top -   @camera.bottom) / element.clientHeight)

        else
            console.warn 'WARNING: OrbitControls encountered unknown camera type; pan disabled'

    update: (delta, state) =>
        clone.update 0, @ for clone in @clones unless state?
        state ?= @
        {thetaDelta, phiDelta, panCurrent, scale} = state

        position = @camera.position
        @offset.copy(position).sub @target
        # rotate offset to "y-axis-is-up" space
        @offset.applyQuaternion @quat
        # angle from z-axis around y-axis
        theta = Math.atan2 @offset.x, @offset.z
        # angle from y-axis
        phi = Math.atan2 \
            Math.sqrt(@offset.x * @offset.x + @offset.z * @offset.z), @offset.y

        if @autoRotate
            @rotateLeft @getAutoRotationAngle()

        theta += thetaDelta
        phi += phiDelta
        # restrict phi to be between desired limits
        phi = Math.max @minPolarAngle, Math.min(@maxPolarAngle, phi)
        # restrict phi to be between EPS and PI-EPS
        phi = Math.max @EPS, Math.min(Math.PI - @EPS, phi)
        radius = @offset.length() * scale
        # restrict radius to be between desired limits
        radius = Math.max @minDistance, Math.min(@maxDistance, radius)
        # move target to panned location
        @target.add panCurrent
        @offset.x = radius * Math.sin(phi) * Math.sin(theta)
        @offset.y = radius * Math.cos(phi)
        @offset.z = radius * Math.sin(phi) * Math.cos(theta)
        # rotate offset back to "camera-up-vector-is-up" space
        @offset.applyQuaternion @quatInverse
        # Update camera
        position.copy(@target).add @offset
        @camera.lookAt @target

        @thetaDelta = 0
        @phiDelta = 0
        @scale = 1
        @panCurrent.set 0, 0, 0

        if @lastPosition.distanceToSquared(position) > @EPS
            @dispatchEvent @changeEvent
            @lastPosition.copy position

    reset: () =>
        @state = @STATE.NONE
        @target.copy @target0
        @camera.position.copy @position0
        @update()

    onMouseDown: (event) =>
        return unless @enabled
        event.preventDefault()

        switch event.button
            when 0
                return if @noRotate
                @state = @STATE.ROTATE
                @rotateStart.set event.clientX, event.clientY
            when 1
                return if @noZoom
                @state = @STATE.DOLLY
                @dollyStart.set event.clientX, event.clientY
            when 2
                return if @noPan
                @state = @STATE.PAN
                @panStart.set event.clientX, event.clientY

        document.documentElement.addEventListener 'mousemove', @onMouseMove, false
        document.documentElement.addEventListener 'mouseup',   @onMouseUp,   false
        @dispatchEvent @startEvent

    onMouseMove: (event) =>
        return unless @enabled
        event.preventDefault()

        element = if @domElement == document then document.body else @domElement

        switch @state
            when @STATE.ROTATE
                return if @noRotate

                @rotateEnd.set event.clientX, event.clientY
                @rotateDelta.subVectors @rotateEnd, @rotateStart
                # rotating across whole screen goes 360 degrees around
                @rotateLeft(
                    2 * Math.PI * @rotateDelta.x / element.clientWidth * @rotateSpeed)
                # rotating up and down along whole screen attempts to go 360,
                # but limited to 180
                @rotateUp(
                    2 * Math.PI * @rotateDelta.y / element.clientHeight * @rotateSpeed)
                @rotateStart.copy @rotateEnd

            when @STATE.DOLLY
                return if @noZoom

                @dollyEnd.set event.clientX, event.clientY
                @dollyDelta.subVectors @dollyEnd, @dollyStart
                if @dollyDelta.y > 0 then @dollyIn() else @dollyOut()
                @dollyStart.copy @dollyEnd

            when @STATE.PAN
                return if @noPan

                @panEnd.set event.clientX, event.clientY
                @panDelta.subVectors @panEnd, @panStart
                @pan @panDelta.x, @panDelta.y
                @panStart.copy @panEnd

            else return

        @update()

    onMouseUp: () =>
        return unless @enabled

        document.documentElement.removeEventListener 'mousemove', @onMouseMove, false
        document.documentElement.removeEventListener 'mouseup',   @onMouseUp,   false
        @dispatchEvent @endEvent
        @state = @STATE.NONE

    onMouseWheel: (event) =>
        return unless @enabled and not @noZoom
        event.preventDefault()
        event.stopPropagation()

        delta = event.wheelDelta ? -event.detail
        if delta > 0 then @dollyOut() else @dollyIn()
        @update()
        @dispatchEvent @startEvent
        @dispatchEvent @endEvent

    onKeyDown: (event) =>
        return if not @enabled or @noKeys or @noPan

        switch event.keyCode
            when @keys.UP     then @pan 0,  @keyPanSpeed
            when @keys.BOTTOM then @pan 0, -@keyPanSpeed
            when @keys.LEFT   then @pan  @keyPanSpeed, 0
            when @keys.RIGHT  then @pan -@keyPanSpeed, 0
            else return

        @update()

    touchStart: (event) =>
        return unless @enabled
        event.preventDefault()

        switch event.touches.length
            # one-fingered touch: rotate
            when 1
                return if @noRotate
                @state = @STATE.TOUCH_ROTATE
                @rotateStart.set event.touches[0].clientX, event.touches[0].clientY
            # two-fingered touch: dolly
            when 2
                return if @noZoom
                @state = @STATE.TOUCH_DOLLY
                dx = event.touches[0].clientX - event.touches[1].clientX
                dy = event.touches[0].clientY - event.touches[1].clientY
                distance = Math.sqrt(dx * dx + dy * dy)
                @dollyStart.set 0, distance
            # three-fingered touch: pan
            when 3
                return if @noPan
                @state = @STATE.TOUCH_PAN
                @panStart.set event.touches[0].clientX, event.touches[0].clientY
            else
                @state = @STATE.NONE

        document.documentElement.addEventListener 'touchend',    @touchEnd,  false
        document.documentElement.addEventListener 'touchmove',   @touchMove, false
        document.documentElement.addEventListener 'touchcancel', @touchEnd,  false
        @dispatchEvent @startEvent

    touchMove: (event) =>
        return unless @enabled
        event.preventDefault()
        event.stopPropagation()

        element = if @domElement == document then document.body else @domElement

        switch event.touches.length
            # one-fingered touch: rotate
            when 1
                return if @noRotate or @state != @STATE.TOUCH_ROTATE
                @rotateEnd.set event.touches[0].clientX, event.touches[0].clientY
                @rotateDelta.subVectors @rotateEnd, @rotateStart
                # rotating across whole screen goes 360 degrees around
                @rotateLeft(
                    2 * Math.PI * @rotateDelta.x / element.clientWidth * @rotateSpeed)
                # rotating up and down along whole screen attempts to go 360,
                # but limited to 180
                @rotateUp(
                    2 * Math.PI * @rotateDelta.y / element.clientHeight * @rotateSpeed)
                @rotateStart.copy @rotateEnd
            # two-fingered touch: dolly
            when 2
                return if @noZoom or @state != @STATE.TOUCH_DOLLY
                dx = event.touches[0].clientX - event.touches[1].clientX
                dy = event.touches[0].clientY - event.touches[1].clientY
                distance = Math.sqrt(dx * dx + dy * dy)
                @dollyEnd.set 0, distance
                @dollyDelta.subVectors @dollyEnd, @dollyStart
                if @dollyDelta.y > 0 then @dollyOut() else @dollyIn()
                @dollyStart.copy @dollyEnd
            # three-fingered touch: pan
            when 3
                return if @noPan or @state != @STATE.TOUCH_PAN
                @panEnd.set event.touches[0].clientX, event.touches[0].clientY
                @panDelta.subVectors @panEnd, @panStart
                @pan @panDelta.x, @panDelta.y
                @panStart.copy @panEnd
            else
                @touchEnd()
                return

        @update()

    touchEnd: () =>
        return unless @enabled
        document.documentElement.removeEventListener 'touchend',    @touchEnd,  false
        document.documentElement.removeEventListener 'touchmove',   @touchMove, false
        document.documentElement.removeEventListener 'touchcancel', @touchEnd,  false
        @dispatchEvent @endEvent
        @state = @STATE.NONE


# Make demo controls all clone each other
groupControls = (demos...) ->
    demos = demos.filter (x) -> x.three.controls?
    for i in [0...demos.length]
        for j in [0...demos.length]
            continue if j == i
            demos[i].three.controls.clones.push demos[j].three.controls


################################################################################
# * Animations

# This class represents a single animation.  It knows how to start()
# itself, how to stop() itself, and when it is done().  It knows when it is
# @running, and it emits signals when start()ed and stop()ped.
#
# The stop() method should do nothing if @running is false.
class Animation
    constructor: () ->
        @running = false

    start: () ->
        @running = true
        @

    stop: () ->
        return unless @running
        @running = false
        @trigger type: 'stopped'
        @

    done: () ->
        @running = false
        @trigger type: 'done'
        @

addEvents Animation

# Thin wrapper around the mathbox API's play() method
class MathboxAnimation extends Animation
    constructor: (element, @opts) ->
        @opts.target = element
        @opts.to ?= Math.max.apply null, (k for k of @opts.script)
        super
    start: () ->
        @_play = @opts.target.play @opts
        @_play.on 'play.done', () =>
            @_play.remove()
            delete @_play
            @done()
        super
    stop: () ->
        @_play?.remove()
        delete @_play
        super


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
#     mesh: mesh for setting visibility of space
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

        @mesh = @opts.mesh

        # Scratch
        @tmpVec1 = new THREE.Vector3()
        @tmpVec2 = new THREE.Vector3()
        @tmpVec3 = new THREE.Vector3()

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
            when 0
                @dim = 0
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

    complement: () =>
        # Return an orthonormal basis for the orthogonal complement
        [ortho1, ortho2] = @ortho
        switch @dim
            when 0
                return [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
            when 1
                [a, b, c] = [ortho1.x, ortho1.y, ortho1.z]
                if Math.abs(a) < @zeroThreshold
                    if Math.abs(b) < @zeroThreshold
                        return [[1, 0, 0], [0, 1, 0]]
                    if Math.abs(c) < @zeroThreshold
                        return [[1, 0, 0], [0, 0, 1]]
                    # b and c are nonzero
                    return [[1, 0, 0], [0, c, -b]]
                # a is nonzero
                setTvec @tmpVec1, [b, -a, 0]
                setTvec @tmpVec2, [c, 0, -a]
                orthogonalize @tmpVec1, @tmpVec2
                return [[@tmpVec1.x, @tmpVec1.y, @tmpVec1.z],
                        [@tmpVec2.x, @tmpVec2.y, @tmpVec2.z]]
            when 2
                cross = @tmpVec1
                cross.crossVectors ortho1, ortho2
                return [[cross.x, cross.y, cross.z]]
            when 3
                return []

    complementFull: (twod) =>
        # Return three vectors that span the complement, or 2 vectors if twod
        # is true.
        vecs = @complement().concat([[0, 0, 0], [0, 0, 0], [0, 0, 0]])
        if twod
            vecs[0][2] = 0
            vecs[1][2] = 0
            return [vecs[0], vecs[1]]
        return vecs.slice(0, 3)

    contains: (vec) =>
        @project vec, @tmpVec3
        setTvec @tmpVec1, vec
        @tmpVec1.sub @tmpVec3
        return @tmpVec1.lengthSq() < @zeroThreshold

    # Set up the mathbox elements to draw the subspace if dim < 3
    draw: (view) =>
        name   = @opts.name   ? 'subspace'
        @range = @opts.range  ? 10.0
        color  = @opts.color  ? new Color("violet")
        live   = @opts.live   ? true

        if color instanceof Color
            color = color.arr()

        @range *= 2

        pointOpts =
            id:      "#{name}-point"
            classes: [name]
            color:   color
            opacity: 1.0
            size:    15
            visible: false
        extend pointOpts, @opts.pointOpts ? {}
        lineOpts =
            id:      "#{name}-line"
            classes: [name]
            color:   color
            opacity: 1.0
            stroke:  'solid'
            width:   5
            visible: false
        extend lineOpts, @opts.lineOpts ? {}
        surfaceOpts =
            id:      "#{name}-plane"
            classes: [name]
            color:   color
            opacity: 0.25
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

    setVisibility: (val) =>
        return unless @drawn
        @objects[@dim]?.set 'visible', val
        if @dim == 3
            @mesh?.material.visible = val

    updateDim: (oldDim) =>
        @onDimChange @
        return unless @drawn
        if oldDim >= 0 and oldDim < 3 and @objects[oldDim]?
            @objects[oldDim].set 'visible', false
        if @dim < 3 and @objects[@dim]?
            @objects[@dim].set 'visible', true
        @mesh?.material.visible = @dim == 3


################################################################################
# * Linear Combination

# Draw a linear combination of 1, 2, or 3 vectors
# Options:
#     vectors: input vectors
#     colors: colors of the lines
#     pointColor: color of the target point
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
        vectors    = opts.vectors
        colors     = opts.colors
        pointColor = opts.pointColor ? new Color("red")
        labels     = opts.labels
        coeffs     = opts.coeffs
        coeffVars  = opts.coeffVars ? ['x', 'y', 'z']

        if pointColor instanceof Color
            pointColor = pointColor.arr()

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
            color:   pointColor
            zIndex:  2
            size:    15
        extend pointOpts, opts.pointOpts ? {}
        labelOpts =
            classes:    [name]
            outline:    0
            background: [0,0,0,0]
            color:      pointColor
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
        for col, i in colors
            if col instanceof Color
                colors[i] = col.arr(1)
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
            .point pointOpts

        if labels?
            view
                # Label
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
        if ticksOpts["color"] instanceof Color
            ticksOpts["color"] = ticksOpts["color"].arr()

        lineOpts =
            id:      name
            opacity: .5
            stroke:  'solid'
            width:   2
            color:   0x880000
            zBias:   2
        extend lineOpts, opts.lineOpts ? {}
        if lineOpts["color"] instanceof Color
            lineOpts["color"] = lineOpts["color"].arr()

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
            totLines = (numLines + 1) * (numLines + 1) * 3
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
#     axisLabels: draw axis labels (x, y, z)
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
            color:   "black"
            opacity: 0.5
            zBias:   -1
            size:    5
        extend axisOpts, @opts.axisOpts ? {}

        doGrid = @opts.grid ? true
        gridOpts =
            classes: ["#{@name}-axes", "#{@name}-grid"]
            axes:    [1, 2]
            width:   2
            depth:   1
            color:   "black"
            opacity: 0.25
            zBias:   0
        extend gridOpts, @opts.gridOpts ? {}

        doAxisLabels = (@opts.axisLabels ? true) and doAxes
        labelOpts =
            classes:    ["#{@name}-axes"]
            size:       20
            color:      "black"
            opacity:    0.5
            outline:    0
            background: [0,0,0,0]
            offset:     [0, 0]
        extend labelOpts, @opts.labelOpts ? {}

        if @numDims == 3
            viewOpts =
                range:    viewRange
                scale:    viewScale
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
        # Set this to false to disable hovering
        @enabled = true

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
                    if not @enabled
                        emit 1, 1, 1, 0
                        return
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

        @canvas.addEventListener 'mousedown',  @onMouseDown, false
        @canvas.addEventListener 'mousemove',  @onMouseMove, false
        @canvas.addEventListener 'mouseup',    @onMouseUp,   false
        @canvas.addEventListener 'touchstart', @touchStart,  false
        @three.on 'post', @post

    onMouseDown: (event) =>
        return if @hovered < 0 or not @enabled
        event.preventDefault()
        @dragging = @hovered
        @activePoint = @points[@dragging]

    onMouseMove: (event) =>
        dpr = window.devicePixelRatio
        @mouse = [event.offsetX * dpr, event.offsetY * dpr]
        @hovered = @getIndexAt @mouse[0], @mouse[1]
        return if @dragging < 0 or not @enabled
        event.preventDefault()
        @movePoint event.offsetX, event.offsetY

    onMouseUp: (event) =>
        return if @dragging < 0 or not @enabled
        event.preventDefault()
        @dragging = -1
        @activePoint = undefined

    movePoint: (x, y) =>
        screenX = x / @canvas.offsetWidth * 2 - 1.0
        screenY = -(y / @canvas.offsetHeight * 2 - 1.0)
        # Move the point in the plane parallel to the camera.
        @projected
            .set(@activePoint[0], @activePoint[1], @activePoint[2])
            .applyMatrix4 @viewMatrix
        @matrix.multiplyMatrices @camera.projectionMatrix, @eyeMatrix
        @matrix.multiply @matrixInv.getInverse @camera.matrixWorld
        @projected.applyProjection @matrix
        @vector.set screenX, screenY, @projected.z
        @vector.applyProjection @matrixInv.getInverse @matrix
        @vector.applyMatrix4 @viewMatrixInv
        @vector.z = 0 if @is2D
        @onDrag.call @, @vector
        @activePoint[0] = @vector.x
        @activePoint[1] = @vector.y
        @activePoint[2] = @vector.z
        @postDrag.call @

    touchStart: (event) =>
        return unless event.touches.length == 1 and event.targetTouches.length == 1
        return unless @enabled
        touch = event.targetTouches[0]
        rect = event.target.getBoundingClientRect()
        offsetX = touch.pageX - rect.left
        offsetY = touch.pageY - rect.top
        dpr = window.devicePixelRatio
        @dragging = @getIndexAt offsetX * dpr, offsetY * dpr
        return if @dragging < 0
        @activePoint = @points[@dragging]
        event.preventDefault()
        @canvas.addEventListener 'touchend',    @touchEnd,  false
        @canvas.addEventListener 'touchmove',   @touchMove, false
        @canvas.addEventListener 'touchcancel', @touchEnd,  false

    touchMove: (event) =>
        return unless event.touches.length == 1 and event.targetTouches.length == 1
        return if @dragging < 0 or not @enabled
        event.preventDefault()
        touch = event.targetTouches[0]
        rect = event.target.getBoundingClientRect()
        offsetX = touch.pageX - rect.left
        offsetY = touch.pageY - rect.top
        @movePoint offsetX, offsetY

    touchEnd: (event) =>
        return if @dragging < 0 or not @enabled
        event.preventDefault()
        @dragging = -1
        @activePoint = undefined

    post: () =>
        if not @enabled
            @three.controls?.enable true
            return
        if @dragging >= 0
            @canvas.style.cursor = 'pointer'
        else if @hovered >= 0
            @canvas.style.cursor = 'pointer'
        else if @three.controls
            @canvas.style.cursor = 'move'
        else
            @canvas.style.cursor = ''
        @three.controls?.enable(@hovered < 0 and @dragging < 0)

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
#    shaded: use mesh shading
#    fragmentShader: use custom fragment shader
#
# Works equally well for a 2D view

class ClipCube
    constructor: (@view, @opts) ->
        @opts ?= {}
        range  = @opts.range  ? 1.0
        pass   = @opts.pass   ? "world"
        hilite = @opts.hilite ? true
        draw   = @opts.draw   ? false
        shaded = @opts.shaded ? false

        @three = @view._context.api.three
        @camera = @view._context.api.select("camera")[0].controller.camera

        if draw
            material = @opts.material ? new THREE.MeshBasicMaterial()
            if @opts.color?
                @opts.color = new Color @opts.color
            color    = @opts.color    ? new Color .7, .7, .7
            @mesh = do () =>
                geo  = new THREE.BoxGeometry 2, 2, 2
                mesh = new THREE.Mesh geo, material
                cube = new THREE.BoxHelper mesh
                cube.material.color = color.three()
                @three.scene.add cube
                mesh

        @uniforms =
            range:
                type: 'f'
                value: range
            hilite:
                type: 'i'
                value: if hilite then 1 else 0

        if @opts.fragmentShader?
            fragment = @opts.fragmentShader
        else if shaded
            fragment = shadeFragment + "\n" + clipFragment
        else
            fragment = noShadeFragment + "\n" + clipFragment
        @clipped = @view
            .shader code: clipShader
            .vertex pass: pass
            .shader
                code: fragment
                uniforms: @uniforms
            .fragment()

    installMesh: () ->
        @three.scene.add @mesh
        @three.on 'pre', () =>
            if Math.abs(@camera.position.x < 1.0) and
               Math.abs(@camera.position.y < 1.0) and
               Math.abs(@camera.position.z < 1.0)
                @mesh.material.side = THREE.BackSide
            else
                @mesh.material.side = THREE.FrontSide


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
#     labelsLive: if the labels can change
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
        labelsLive = @opts.labelsLive ? false
        vectorOpts =
            id:      "#{name}-vectors-drawn"
            classes: [name]
            points:  "##{name}-vectors"
            colors:  "##{name}-colors"
            color:   "white"
            end:     true
            size:    5
            width:   5
        extend vectorOpts, @opts.vectorOpts ? {}
        labelOpts =
            id:         "#{name}-vector-labels"
            classes:    [name]
            colors:     "##{name}-colors"
            color:      "white"
            outline:    0
            background: [0,0,0,0]
            size:       15
            offset:     [0, 25]
        extend labelOpts, @opts.labelOpts ? {}
        doZero = @opts.zeroPoints ? false
        zeroOpts =
            id:      "#{name}-zero-points"
            classes: [name]
            points:  "##{name}-zeros"
            colors:  "##{name}-zero-colors"
            color:   "white"
            size:    20
        extend zeroOpts, @opts.zeroOpts ? {}
        zeroThreshold = @opts.zeroThreshold ? 0.0

        for col, i in colors
            if col instanceof Color
                colors[i] = col.arr(1)

        @hidden = false

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
        @vecs = view.vector vectorOpts

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
                    live:  labelsLive
                    width: labels.length
                    data:  labels
            @labels = view.label labelOpts

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
            @zeroPoints.bind 'visible', () =>
                return false if @hidden
                for i in [0...vectors.length]
                    if vectors[i][0] * vectors[i][0] +
                       vectors[i][1] * vectors[i][1] +
                       vectors[i][2] * vectors[i][2] <=
                       zeroThreshold * zeroThreshold
                        return true
                return false

    hide: () =>
        return if @hidden
        @hidden = true
        @vecs.set 'visible', false
        @labels?.set 'visible', false
    show: () =>
        return unless @hidden
        @hidden = false
        @vecs.set 'visible', true
        @labels?.set 'visible', true


################################################################################
# * Labeled points

# Constructs mathbox primitives for points with labels
# Options:
#     name: ids begin with "#{name}-"
#     points: positions of points to draw (dynamic array)
#     colors: colors to draw the points
#     labels: labels for the points
#     live: if the points can move
#     labelsLive: if the labels can change
#     pointOpts: passed to mathbox.vector
#     labelOpts: passed to mathbox.label
#
# In 2D, this adds a zero final coordinate to the vectors if necessary

class LabeledPoints
    constructor: (view, @opts) ->
        @opts ?= {}
        name    = @opts.name ? "labeled-points"
        points  = @opts.points
        colors  = @opts.colors
        labels  = @opts.labels
        live    = @opts.live ? true
        labelsLive = @opts.labelsLive ? false
        pointOpts =
            id:      "#{name}-drawn"
            classes: [name]
            points:  "##{name}-points"
            colors:  "##{name}-colors"
            color:   "white"
            size:    15
        extend pointOpts, @opts.pointOpts ? {}
        labelOpts =
            id:         "#{name}-labels"
            classes:    [name]
            points:     "##{name}-points"
            colors:     "##{name}-colors"
            color:      "white"
            outline:    0
            background: [0,0,0,0]
            size:       15
            offset:     [0, 25]
        extend labelOpts, @opts.labelOpts ? {}

        for col, i in colors
            if col instanceof Color
                colors[i] = col.arr(1)

        @hidden = false

        pointData = []
        # Extend to 3D
        point[2] ?= 0 for point in points
        for i in [0...points.length]
            pointData.push points[i]

        # vectors
        view
            .array
                id:       "#{name}-points"
                channels: 3
                width:    points.length
                data:     pointData
                live:     live
            .array
                id:       "#{name}-colors"
                channels: 4
                width:    colors.length
                data:     colors
                live:     live
        @pts = view.point pointOpts

        # Labels
        if labels?
            view
                .text
                    id:    "#{name}-text"
                    live:  labelsLive
                    width: labels.length
                    data:  labels
            @labels = view.label labelOpts

    hide: () =>
        return if @hidden
        @hidden = true
        @pts.set 'visible', false
        @labels?.set 'visible', false
    show: () =>
        return unless @hidden
        @hidden = false
        @pts.set 'visible', true
        @labels?.set 'visible', true


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
        @urlParams = urlParams

        @opts ?= {}
        mathboxOpts =
            plugins:     ['core', 'controls', 'cursor']
            controls:
                klass:   OrbitControls
                parameters:
                    noKeys: true
            mathbox:
                inspect: false
            splash:
                fancy:   true
                color:   "blue"
        extend mathboxOpts, @opts.mathbox ? {}
        clearColor   = @opts.clearColor   ? 0xffffff
        clearOpacity = @opts.clearOpacity ? 1.0
        cameraOpts   =
            proxy:    true
            position: [3, 1.5, 1.5]
            lookAt:   [0, 0, 0]
            up:       [0, 0, 1]
        extend cameraOpts, @opts.camera ? {}
        if @opts.cameraPosFromQS ? true
            cameraOpts.position = @urlParams.get 'camera', 'float[]', cameraOpts.position
        focusDist    = @opts.focusDist  ? 1.5
        scaleUI      = @opts.scaleUI    ? true
        doFullScreen = @opts.fullscreen ? true
        @dims        = @opts.dims       ? 3

        clearColor = new Color clearColor

        @animations = []

        onPreloaded = () =>
            # Setup mathbox
            @mathbox = mathBox(mathboxOpts)
            @three = @mathbox.three
            @three.renderer.setClearColor clearColor.three(), clearOpacity
            @controls = @three.controls
            @camera = @mathbox.camera(cameraOpts)[0].controller.camera
            @controls?.updateCamera?()
            @canvas = @mathbox._context.canvas
            if scaleUI
                @mathbox.bind 'focus', () =>
                    focusDist / 1000 * Math.min @canvas.clientWidth, @canvas.clientHeight
            else
                @mathbox.set 'focus', focusDist
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

    texVector: (vec, opts) ->
        opts ?= {}
        precision = opts.precision ? 2
        dim = opts.dim ? @dims
        vec = vec.slice(0, dim)
        if precision >= 0
            for coord, i in vec
                vec[i] = coord.toFixed precision
        ret = ''
        if opts.color?
            if opts.color instanceof Color
                opts.color = opts.color.str()
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
        if colors?
            for col, i in colors
                if col instanceof Color
                    colors[i] = col.str()
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
        if colors?
            for col, i in colors
                if col instanceof Color
                    colors[i] = col.str()
        coeffColors = opts.coeffColors
        unless coeffColors instanceof Array
            coeffColors = (coeffColors for [0...vecs.length])
        for col, i in coeffColors
            if col instanceof Color
                coeffColors[i] = col.str()
        precision = opts.precision ? 2
        str = ''
        for vec, i in vecs
            if coeffColors[i]?
                str += "\\color{#{coeffColors[i]}}{"
            if coeffs[i] != 1
                if coeffs[i] == -1
                    str += '-'
                else
                    str += coeffs[i].toFixed precision
            if coeffColors[i]?
                str += "}"
            if colors?
                opts.color = colors[i]
            str += @texVector vec, opts
            if i+1 < vecs.length and coeffs[i+1] >= 0
                str += ' + '
        str

    texMatrix: (cols, opts) ->
        opts ?= {}
        colors = opts.colors
        if colors?
            for col, i in colors
                if col instanceof Color
                    colors[i] = col.str()
        precision = opts.precision ? 2
        m = opts.rows ? @dims
        n = opts.cols ? cols.length
        str = "\\begin{bmatrix}"
        for i in [0...m]
            for j in [0...n]
                if colors?
                    str += "\\color{#{colors[j]}}{"
                if precision >= 0
                    str += cols[j][i].toFixed precision
                else
                    str += cols[j][i]
                if colors?
                    str += "}"
                str += "&" if j+1 < n
            str += "\\\\" if i+1 < m
        str += "\\end{bmatrix}"

    rowred: (mat, opts) -> rowReduce mat, opts

    view: (opts) ->
        opts ?= {}
        if @urlParams.range?
            r = @urlParams.get 'range', 'float'
            opts.viewRange ?= [[-r, r], [-r, r], [-r, r]]
        new View(@mathbox, opts).view

    caption: (text) -> new Caption @mathbox, text
    popup: (text) -> new Popup @mathbox, text
    clipCube: (view, opts) -> new ClipCube view, opts
    draggable: (view, opts) -> new Draggable view, opts
    linearCombo: (view, opts) -> new LinearCombo view, opts
    grid: (view, opts) -> new Grid view, opts
    labeledVectors: (view, opts) -> new LabeledVectors view, opts
    labeledPoints: (view, opts) -> new LabeledPoints view, opts
    subspace: (opts) -> new Subspace opts

    clearAnims: () =>
        @animations = @animations.filter (a) -> a.running

    animate: (opts) =>
        anim = opts.animation ? new MathboxAnimation opts.element, opts
        anim.on 'stopped', @clearAnims
        anim.on 'done', @clearAnims
        anim.start()
        @animations.push anim

    stopAll: () =>
        for anim in @animations
            anim.stop()
            anim.off 'stopped', @clearAnims
            anim.off 'done', @clearAnims
        @animations = []


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
        opts.camera.position     ?= [0, 0, ortho]
        opts.camera.lookAt       ?= [0, 0, 0]
        opts.camera.up           ?= [1, 0, 0]
        vertical = opts.vertical ? 1.1
        opts.camera.fov          ?= Math.atan(vertical/ortho) * 360 / π
        opts.focusDist           ?= ortho/1.5

        super opts, callback

    view: (opts) ->
        opts ?= {}
        if @urlParams.range?
            r = @urlParams.get 'range', 'float'
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

window.Color = Color
for name, color of palette
    document.body.style.setProperty("--palette-#{name}", new Color(color).str())

window.rowReduce     = rowReduce
window.eigenvalues   = eigenvalues

window.Animation     = Animation
window.Demo          = Demo
window.Demo2D        = Demo2D
window.urlParams     = urlParams
window.OrbitControls = OrbitControls
window.groupControls = groupControls
