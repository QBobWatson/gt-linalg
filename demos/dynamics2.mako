## -*- coffee -*-

<%inherit file="base_diptych.mako"/>

<%block name="title">Dynamics of Similar Matrices</%block>

<%block name="inline_style">
${parent.inline_style()}
.espace-1 {
    color: var(--palette-green);
}
.espace-2 {
    color: var(--palette-violet);
}
.espace-3 {
    color: var(--palette-brown);
}
.overlay-text {
    z-index: 1;
}
#gui-container {
  position: absolute;
  right:    10px;
  top:      0px;
  z-index:  2;
}
#captions3 {
  position:    absolute;
  left:        50%;
  top:         initial;
  transform:   translate(-50%, 0);
  bottom:      10px;
  z-index:     2;
}
#mult-here1.hidden,
#mult-here2.hidden {
    display: none;
}
</%block>

<%block name="label1">
<div id="captions1" class="overlay-text"></div>
</%block>

<%block name="label2">
<div id="captions2" class="overlay-text"></div>
</%block>

<%block name="body_html">
<div id="gui-container"></div>
<div id="captions3" class="overlay-text">
<p>
    <span id="C-here"></span><br>
    <span id="sim-here"></span><br>
</p>
</div>
${parent.body_html()}
</%block>

<%block name="js">
    ${parent.js()}
    <script src="${"js/dynamics.js" | vers}"></script>
</%block>

##

<%include file="dyncommon.coffee"/>

######################################################################
# * URL parameters

# This is the matrix on the *left*, wrt the basis w1,w2,w3.  The matrix on
# the right is the same matrix, wrt the basis v1,v2,v3.
matrix = urlParams.get 'mat', 'matrix', [[ 1/2, 1/2],
                                         [-1/2, 1/2]]

matNames = urlParams.get 'matnames', 'str[]', ['A', 'D', 'C']
vecNames = urlParams.get 'vecnames', 'str[]', ['x', 'y']
size = if urlParams.eigenz? then 3 else 2
eigenz = urlParams.get 'eigenz', 'float', 1

w1 = urlParams.get 'w1', 'float[]', [1,0,0]
w2 = urlParams.get 'w2', 'float[]', [0,1,0]
w3 = urlParams.get 'w3', 'float[]', [0,0,1]
v1 = urlParams.get 'v1', 'float[]', [1,0,0]
v2 = urlParams.get 'v2', 'float[]', [0,1,0]
v3 = urlParams.get 'v3', 'float[]', [0,0,1]

v1[2] ?= 0
v2[2] ?= 0
v3[2] ?= 0
w1[2] ?= 0
w2[2] ?= 0
w3[2] ?= 0

if urlParams.testmat?
    matrix = testMatrices[urlParams.testmat]

duration = urlParams.get 'duration', 'float', 2.5

vectorIn = urlParams.get 'y', 'float[]', [5, 0, 1]
vectorIn[2] ?= 0
vectorIn[0] /= 10
vectorIn[1] /= 10
vectorIn[2] /= 10


######################################################################
# * Create view and controller

{basis1, basis2, type, typeOpts, axisColors, eigenStrs} = matrixInfo matrix

if size == 3
    eigenStrs.push "This is the <span class=\"espace-3\">" +
                   "#{eigenz.toFixed 2}-eigenspace.</span>"
    typeOpts.scaleZ = eigenz
eigenStr = eigenStrs.join "<br>"

w1p = mv3v2 w1, w2, basis1
w2p = mv3v2 w1, w2, basis2
w3p = w3

# The matrix is block-diagonal in standard form wrt w1p, w2p, w3p

controller = new dynamics.Controller
    continuous: false
    flow: urlParams.get 'flow', 'bool', false
    duration: duration
    is3D: size == 3

dynView1 = new dynamics.DynamicsView
    is3D: size == 3
    axisOpts:
        width:   if size == 3 then 5 else 3
        opacity: 1.0
    axisColors: axisColors
    refColor: new Color("blue").arr()
    timer: true
dynView1.setCoords w1p, w2p, w3p
controller.addView dynView1

dynView2 = new dynamics.DynamicsView
    is3D: size == 3
    axisOpts:
        width:   if size == 3 then 5 else 3
        opacity: 1.0
    axisColors: axisColors
    refColor: new Color("blue").arr()
    timer: false

v1p = mv3v2 v1, v2, basis1
v2p = mv3v2 v1, v2, basis2
v3p = v3

dynView2.setCoords v1p, v2p, v3p
controller.addView dynView2

controller.loadDynamics type, typeOpts


C = do () ->
    m1 = new THREE.Matrix4().set \
        w1[0], w2[0], w3[0], 0,
        w1[1], w2[1], w3[1], 0,
        w1[2], w2[2], w3[2], 0,
        0,     0,     0,     1
    m1 = new THREE.Matrix4().getInverse m1
    m2 = new THREE.Matrix4().set \
        v1[0], v2[0], v3[0], 0,
        v1[1], v2[1], v3[1], 0,
        v1[2], v2[2], v3[2], 0,
        0,     0,     0,     1
    m1.multiply m2
Cinv = new THREE.Matrix4().getInverse C


######################################################################
# * Create demo

params =
    Multiply:      null
    "Un-multiply": null
    "Test vector": urlParams.get 'vec', 'bool', true
    "Show path":   urlParams.get 'path', 'bool', true

window.demo1 = demo1 = dynamicsDemo controller,
    dynView:    dynView1
    element:    document.getElementById 'mathbox1'
    captionElt: document.getElementById 'captions1'
    suffix:     '1'
    matName:    matNames[1]
    vecName:    vecNames[1]
    size:       size
    eigenz:     eigenz
    eigenStr:   eigenStr
    params:     params
    vectorIn:   vectorIn
    dragHook: (v) ->
        v = v.slice()
        C.applyToVector3Array v
        demo2.setVec v

C.applyToVector3Array vectorIn

window.demo2 = demo2 = dynamicsDemo controller,
    dynView:    dynView2
    element:    document.getElementById 'mathbox2'
    captionElt: document.getElementById 'captions2'
    suffix:     '2'
    matName:    matNames[0]
    vecName:    vecNames[0]
    size:       size
    eigenz:     eigenz
    eigenStr:   eigenStr
    params:     params
    vectorIn:   vectorIn
    dragHook: (v) ->
        v = v.slice()
        Cinv.applyToVector3Array v
        demo1.setVec v

do () ->
    te = C.elements
    if size == 2
        displayMat = [[te[0], te[1]], [te[4], te[5]]]
    else if size == 3
        displayMat = [[te[0], te[1], te[2]],
                      [te[4], te[5], te[6]],
                      [te[8], te[9], te[10]]]

    check = new THREE.Matrix4() \
        .multiply(C)
        .multiply(dynView1.matrixOrigCoords)
        .multiply(Cinv)
    console.log "CDC^-1 = ", check
    console.log "A = ", dynView2.matrixOrigCoords

    elt = document.getElementById "C-here"
    A = matNames[0]
    D = matNames[1]
    mC = matNames[2]
    x = vecNames[0]
    y = vecNames[1]
    katex.render("#{mC} = " + demo1.texMatrix(displayMat), elt)
    elt = document.getElementById "sim-here"
    vc = new Color("red").str()
    katex.render("#{A} = #{mC}#{D}#{mC}^{-1} \\quad " +
                 "\\color{#{vc}}{#{x}} = #{mC}\\color{#{vc}}{#{y}}", elt)


######################################################################
# * GUI

groupControls demo1, demo2 if size == 3

gui = new dat.GUI autoPlace: false
params["Multiply"] = () ->
    controller.step()
gui.add(params, "Multiply")
params["Un-multiply"] = () ->
    controller.unStep()
gui.add(params, "Un-multiply")
gui.add(params, "Test vector").onFinishChange (val) ->
    demo1.toggleVector val
    demo2.toggleVector val
gui.add(params, "Show path").onFinishChange (val) ->
    demo1.togglePath val
    demo2.togglePath val

document.getElementById('gui-container').appendChild gui.domElement
