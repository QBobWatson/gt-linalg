## -*- coffee -*-

<%inherit file="base_diptych.mako"/>

<%block name="title">Implicit Function of Best Fit</%block>

<%block name="inline_style">
${parent.inline_style()}
  #eqn-here {
    color: var(--palette-red);
  }
  #sumsq-here {
    color: var(--palette-violet);
  }
</%block>

<%block name="overlay_text">
<div class="overlay-text">
  <p>Best-fit equation: <span id="eqn-here"></span></p>
  <p>Quantity minimized: <span id="sumsq-here"></span></p>
</div>
</%block>

<%block name="label1">
<div class="mathbox-label">Graph</div>
</%block>

<%block name="label2">
<div class="mathbox-label">Zero Set</div>
</%block>

##

range = urlParams.get 'range', 'float', 10
rangeZ = urlParams.get 'rangez', 'float', range

# urlParams.func has to be of the form A*blah1(x)+B*blah2(x)-C*blah3(x)+D
# spaces are replaced by '+' (the reverse happens in urldecode)
funcStr = urlParams.func ? 'C*x+D'
funcStr = funcStr.replace /\s+/g, '+'
func = exprEval.Parser.parse funcStr
# x and y are function variables; the rest are parameters
params = []
zeroParams = {}
uniforms = {}
vars = ['x', 'y']
for letter in func.variables().sort()
    if letter in ['x', 'y']
        continue
    params.push letter
    zeroParams[letter] = 0
    uniforms[letter] =
        type:  'f'
        value: 0.0
numParams = params.length

# unit coordinate vectors in the parameters
units = []
for i in [0...numParams]
    obj = {}
    for param in params
        obj[param] = 0
    obj[params[i]] = 1
    units.push obj

# Target vectors
targets = []
i = 1
while urlParams["v#{i}"]?
    target = urlParams.get "v#{i}", 'float[]'
    target[2] = 0
    targets.push target
    i++
numTargets = targets.length

# Set up the linear equations
# The matrix has numParams columns, each with numTargets rows
matrix = ((0 for [0...numTargets]) for [0...numParams])
bvec = (0 for [0...numTargets])
xhat = (0 for [0...numParams])
bestfit = (x, y) -> 0
bestFitStr = ''
paramVals = {}

# Pass the function (almost) directly from the URL into the GPU
funcStrUrl = funcStr.replace /([a-zA-Z_]+)\^(\d+)/g, (match, p1, p2) ->
    (p1 for [0...parseInt(p2)]).join("*")
funcFragment = ''
for letter in params
    funcFragment += "uniform float #{letter};\n"
funcFragment += """\n
    float func(float x, float y) {
        return #{funcStrUrl};
    }
"""
# This should work for most TeX functions
for op of func.unaryOps
    if op.match /^[a-zA-Z]+$/
        funcStr = funcStr.replace(new RegExp(op, 'g'), "\\#{op}")

dot = (v1, v2) ->
    ret = 0
    for i in [0...v1.length]
        ret += v1[i] * v2[i]
    ret

updateCaption = () ->

solve = () ->
    # First have to figure out the coefficients of matrix and bvec
    for eqno in [0...numTargets]
        target = targets[eqno]
        linear = func.simplify
            x: target[0]
            y: target[1]
        # linear is now an (affine linear) function of the parameters only
        # First get the constant term
        constant = linear.evaluate zeroParams
        # Now get the linear terms
        for i in [0...numParams]
            matrix[i][eqno] = linear.evaluate(units[i]) - constant
        # The last coordinate of the target is the right-hand side of the equation
        bvec[eqno] = target[2] - constant
    # Now least-squares solve Ax=b
    ATA = ((dot(matrix[i], matrix[j]) for i in [0...numParams]) for j in [0...numParams])
    ATb = (dot(matrix[i], bvec) for i in [0...numParams])
    solver = rowReduce(ATA)[3]
    solver ATb, xhat
    # Substitute the parameters to get the best-fit function
    for letter, i in params
        paramVals[letter] = xhat[i]
        uniforms[letter].value = xhat[i]
    bestfit = func.simplify(paramVals).toJSFunction(vars.join ',')
    makeString()
    updateCaption()

makeString = () ->
    # Make a TeX string out of the function
    bestFitStr = funcStr
    for letter, i in params
        val = xhat[i]
        if val >= 0
            valAlone = val.toFixed 2
            valPlus  = "+#{valAlone}"
            valMinus = "-#{valAlone}"
        if val < 0
            val = -val
            valAlone = val.toFixed 2
            valPlus  = "-#{valAlone}"
            valMinus = "+#{valAlone}"
            valAlone = "-#{valAlone}"
        bestFitStr = bestFitStr.replace(
            new RegExp("\\+#{letter}\\*", 'g'), valPlus + '\\,')
        bestFitStr = bestFitStr.replace(
            new RegExp("\\+#{letter}", 'g'), valPlus)
        bestFitStr = bestFitStr.replace(
            new RegExp("-#{letter}\\*", 'g'), valMinus + '\\,')
        bestFitStr = bestFitStr.replace(
            new RegExp("-#{letter}", 'g'), valMinus)
        bestFitStr = bestFitStr.replace(
            new RegExp("#{letter}\\*", 'g'), valAlone + '\\,')
        bestFitStr = bestFitStr.replace(
            new RegExp("#{letter}", 'g'), valAlone)
        bestFitStr = bestFitStr.replace(/\*/g, '')

solve()


clipShader = \
    """
    // Enable STPQ mapping
    #define POSITION_STPQ
    void getPosition(inout vec4 xyzw, inout vec4 stpq) {
      // Store XYZ per vertex in STPQ
    stpq = xyzw;
    }
    """
# Copied from mathbox (I don't know how to pipe it in)
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

# A point is drawn on the line if the function changes sign nearby.
# "nearby" means "on one of the points in toSample"
# glsl2 can't do statically initialized arrays as far as I can tell
numSamples = 8
radius = 0.02
samples = ''
for i in [0...numSamples]
    c = Math.cos(2*π*i/numSamples) * radius
    s = Math.sin(2*π*i/numSamples) * radius
    samples += "if(func(stpq.x + #{c.toFixed 8}, stpq.y + #{s.toFixed 8}) * val < 0.0)\n"
    samples += "    return rgba;\n"

curveFragment = \
    """
    // Enable STPQ mapping
    #define POSITION_STPQ

    vec4 getColor(vec4 rgba, inout vec4 stpq) {
        float val = func(stpq.x, stpq.y);

        #{samples}

        discard;
    }
    """

samples = ''
radius = 0.1
for i in [0...numSamples]
    c = Math.cos(2*π*i/numSamples) * radius
    s = Math.sin(2*π*i/numSamples) * radius
    samples += "if(func(stpq.x + #{c.toFixed 8}, stpq.y + #{s.toFixed 8}) * val < 0.0)\n"
    samples += "    return rgba;\n"
clipFragment = \
    """
    // Enable STPQ mapping
    #define POSITION_STPQ
    uniform float range;
    uniform float rangeZ;
    uniform int hilite;

    vec4 getColor(vec4 rgba, inout vec4 stpq) {
        float val = stpq.z;
        rgba = getShadedColor(rgba);
        vec4 oldrgba = rgba;

        // Discard pixels outside of clip box
        if(abs(stpq.x) > range || abs(stpq.y) > range || abs(stpq.z) > rangeZ)
            discard;

        rgba.xyz *= 10.0;
        rgba.w = 1.0;

        if(hilite != 0 && stpq.z < #{radius} && stpq.z > -#{radius}) {
            #{samples}
        }

        return oldrgba;
    }
    """


window.demo1 = new Demo {
    mathbox: element: document.getElementById "mathbox1"
    scaleUI: true
    camera: position: urlParams.get 'camera1', 'float[]', [3, 1.5, 1.5]
}, () ->
    window.mathbox1 = @mathbox

    view = @view
        axes:      false
        grid:      true
        viewRange: [[-range,range],[-range,range],[-rangeZ,rangeZ]]

    ##################################################
    # (Unlabeled) points
    @labeledPoints view,
        name:      'targets'
        points:    targets
        colors:    (new Color("blue") for [0...numTargets])
        live:      true
        pointOpts: zIndex: 2

    ##################################################
    # Graph the best-fit function
    uniforms.range =
        type: 'f'
        value: range
    uniforms.rangeZ =
        type: 'f'
        value: rangeZ
    uniforms.hilite =
        type:  'i'
        value: 1
    clipCube = view
        .shader code: clipShader
        .vertex pass: 'data'
        .shader
            code: funcFragment + "\n" + shadeFragment + "\n" + clipFragment
            uniforms: uniforms
        .fragment()
    geo  = new THREE.BoxGeometry 2, 2, 2
    mesh = new THREE.Mesh geo, new THREE.MeshBasicMaterial()
    cube = new THREE.BoxHelper mesh
    cube.material.color = new THREE.Color .7, .7, .7
    @three.scene.add cube

    clipCube
        .area
            channels: 3
            rangeX:   [-range, range]
            rangeY:   [-range, range]
            width:    100
            height:   100
            expr: (emit, x, y) ->
                emit(x, y, bestfit(x, y))
        .surface
            color:   new Color("red").arr()
            opacity: 0.7
            fill:    true

    ##################################################
    # Draw error lines
    view
        .array
            channels: 3
            width:    2
            items:    numTargets
            expr: (emit, end) ->
                for i in [0...numTargets]
                    x = targets[i][0]
                    y = targets[i][1]
                    z = targets[i][2]
                    if end
                        emit(x, y, bestfit(x, y))
                    else
                        emit(x, y, z)
        .line
            color:  new Color("violet").arr()
            width:  3
            zIndex: 3


window.demo2 = new Demo2D {
    mathbox: element: document.getElementById "mathbox2"
    scaleUI: true
}, () ->
    window.mathbox2 = @mathbox

    view = @view
        axes:      true
        axisLabels: false
        grid:      true
        viewRange: [[-range,range],[-range,range]]

    ##################################################
    # (Unlabeled) points
    @labeledPoints view,
        name:      'targets'
        points:    targets
        colors:    (new Color("blue") for [0...numTargets])
        live:      true
        pointOpts: zIndex: 2

    ##################################################
    # Implicit curve
    # We don't compute the curve, so much as run a surface through a custom clip
    # shader, and only draw values near z=0.
    curve = view
        .shader code: clipShader
        .vertex pass: 'data'
        .shader
            code: funcFragment + "\n" + curveFragment
            uniforms: uniforms
        .fragment()
    curve
        .matrix
            channels: 2
            width:    2
            height:   2
            data:     [[[-range,-range], [-range,range]],
                       [[ range,-range], [ range,range]]]
        .surface
            color:   new Color("red").arr()
            opacity: 1.0
            fill:    true

    ##################################################
    # Dragging
    @draggable view,
        points:   targets
        postDrag: solve

    ##################################################
    # Caption
    bestFitElt = document.getElementById 'eqn-here'
    minimElt   = document.getElementById 'sumsq-here'

    updateCaption = () =>
        katex.render "\\quad 0 = #{bestFitStr}", bestFitElt
        minimized = []
        quantity = 0
        for target in targets
            diff = Math.abs(target[2] - bestfit(target[0], target[1]))
            minimized.push "#{diff.toFixed 2}^2"
            quantity += diff*diff
        str = '\\quad' + quantity.toFixed(2) + '=' + minimized.join('+')
        katex.render str, minimElt

    updateCaption()
