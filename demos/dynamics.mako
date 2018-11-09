## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Matrix Dynamics</%block>

<%block name="inline_style">
${parent.inline_style()}
html, body {
    margin:           0;
    height:           100%;
    background-color: white;
    overflow-x:       hidden;
}
#mathbox {
    width:       100%;
    height:      100%;
}
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
#mult-here.hidden {
    display: none;
}
</%block>

<%block name="body_html">
<div id="caption" class="overlay-text"></div>
<div id="gui-container"></div>
<div id="mathbox"></div>
</%block>

<%block name="js">
    ${parent.js()}
    <script src="${"js/dynamics.js" | vers}"></script>
</%block>

##

<%include file="dyncommon.coffee"/>

######################################################################
# * URL parameters:
#
# + matrix: a 2x2 matrix.  If this is a 3D demo, this is the 2x2 part of a
#   block diagonal form.
# + eigenz: for 3D, this is the (real) third eigenvalue
# + v1, v2, v3: for 3D, this is the basis with respect to which the
#   block-diagonal matrix is specified.
# + vec: display test vector
# + path: display test path
#
# + duration: animation time
# + matname: matrix name
# + vecname: vector name
# + testmat, flow: for testing

matrix = urlParams.get 'mat', 'matrix', [[ 1/2, 1/2],
                                         [-1/2, 1/2]]
matName = urlParams.matname ? 'A'
vecName = urlParams.vecname ? 'x'
size = if urlParams.eigenz? then 3 else 2
eigenz = urlParams.get 'eigenz', 'float', 1
v1 = urlParams.get 'v1', 'float[]', [1,0,0]
v2 = urlParams.get 'v2', 'float[]', [0,1,0]
v3 = urlParams.get 'v3', 'float[]', [0,0,1]

v1[2] ?= 0
v2[2] ?= 0
v3[2] ?= 0

if urlParams.testmat?
    matrix = testMatrices[urlParams.testmat]

duration = urlParams.get 'duration', 'float', 2.5

vectorIn = urlParams.get 'y', 'float[]', [5, 0, 0]
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

v1p = mv3v2 v1, v2, basis1
v2p = mv3v2 v1, v2, basis2
v3p = v3

# The matrix is block-diagonal in standard form wrt v1p, v2p, v3p

controller = new dynamics.Controller
    continuous: false
    flow: urlParams.get 'flow', 'bool', false
    duration: duration
    is3D: size == 3

dynView = new dynamics.DynamicsView
    is3D: size == 3
    axisOpts:
        width:   if size == 3 then 5 else 3
        opacity: 1.0
    axisColors: axisColors
    refColor: new Color("blue").arr()
    timer: true
dynView.setCoords v1p, v2p, v3p
controller.addView dynView
controller.loadDynamics type, typeOpts


######################################################################
# * Create demo

params =
    Multiply:      null
    "Un-multiply": null
    "Test vector": urlParams.get 'vec', 'bool', true
    "Show path":   urlParams.get 'path', 'bool', true

window.demo = demo = dynamicsDemo controller,
    dynView:      dynView
    params:       params
    matName:      matName
    vecName:      vecName
    size:         size
    eigenz:       eigenz
    eigenStr:     eigenStr
    vectorIn:     vectorIn

gui = new dat.GUI autoPlace: false
params["Multiply"] = controller.step
gui.add(params, "Multiply")
params["Un-multiply"] = controller.unStep
gui.add(params, "Un-multiply")
gui.add(params, "Test vector").onFinishChange demo.toggleVector
gui.add(params, "Show path").onFinishChange demo.togglePath
document.getElementById('gui-container').appendChild gui.domElement

if controller.flow
    controller.start 55
