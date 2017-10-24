## -*- coffee -*-

<%inherit file="base_triptych.mako"/>

<%block name="title">Composition of Transformations</%block>

<%block name="overlay_text">
<div class="overlay-text">
  <p><span id="matrix1-here"></span></p>
  <p><span id="matrix2-here"></span></p>
  <p><span id="matrix3-here"></span></p>
</div>
</%block>

<%block name="label1">
<div class="mathbox-label">Input of U</div>
</%block>
<%block name="label2">
<div class="mathbox-label">Output of U / Input of T</div>
</%block>
<%block name="label3">
<div class="mathbox-label">Output of T / of T &#x25CB; U</div>
</%block>

##

##################################################
# Globals
vector1 = [-1, 2, 3]
vector2 = [0, 0, 0]
vector3 = [0, 0, 0]

color1 = [0, 1, 0, 1]
color2 = [1, 0, 1, 1]
color3 = [1, 1, 0, 1]

if urlParams.x?
    vector1 = urlParams.x.split(",").map parseFloat

matrix1 = [[1, 0, 0],
           [0, 1, 0],
           [0, 0, 1]]
if urlParams.mat1?
   matrix1 = urlParams.mat1.split(":").map (s) -> s.split(",").map parseFloat
matrix2 = [[1, 0, 0],
           [0, 1, 0],
           [0, 0, 1]]
if urlParams.mat2?
   matrix2 = urlParams.mat2.split(":").map (s) -> s.split(",").map parseFloat

dim1 = matrix1[0].length
dim2 = matrix2[0].length
dim3 = matrix2.length
vector1[2] = 0 if dim1 == 2

# Make 3x3, make first coord = column
transpose = (mat) ->
    tmp = []
    for i in [0...3]
        tmp[i] = []
        for j in [0...3]
            tmp[i][j] = mat[j]?[i] ? 0
    tmp
matrix1 = transpose matrix1
matrix2 = transpose matrix2
# product
matrix3 = [[matrix2[0][0] * matrix1[0][0] +
            matrix2[1][0] * matrix1[0][1] +
            matrix2[2][0] * matrix1[0][2],
            matrix2[0][1] * matrix1[0][0] +
            matrix2[1][1] * matrix1[0][1] +
            matrix2[2][1] * matrix1[0][2],
            matrix2[0][2] * matrix1[0][0] +
            matrix2[1][2] * matrix1[0][1] +
            matrix2[2][2] * matrix1[0][2]],
           [matrix2[0][0] * matrix1[1][0] +
            matrix2[1][0] * matrix1[1][1] +
            matrix2[2][0] * matrix1[1][2],
            matrix2[0][1] * matrix1[1][0] +
            matrix2[1][1] * matrix1[1][1] +
            matrix2[2][1] * matrix1[1][2],
            matrix2[0][2] * matrix1[1][0] +
            matrix2[1][2] * matrix1[1][1] +
            matrix2[2][2] * matrix1[1][2]],
           [matrix2[0][0] * matrix1[2][0] +
            matrix2[1][0] * matrix1[2][1] +
            matrix2[2][0] * matrix1[2][2],
            matrix2[0][1] * matrix1[2][0] +
            matrix2[1][1] * matrix1[2][1] +
            matrix2[2][1] * matrix1[2][2],
            matrix2[0][2] * matrix1[2][0] +
            matrix2[1][2] * matrix1[2][1] +
            matrix2[2][2] * matrix1[2][2]]]

tMatrix1 = new THREE.Matrix3()
tMatrix1.set matrix1[0][0], matrix1[1][0], matrix1[2][0],
             matrix1[0][1], matrix1[1][1], matrix1[2][1],
             matrix1[0][2], matrix1[1][2], matrix1[2][2]
tMatrix2 = new THREE.Matrix3()
tMatrix2.set matrix2[0][0], matrix2[1][0], matrix2[2][0],
             matrix2[0][1], matrix2[1][1], matrix2[2][1],
             matrix2[0][2], matrix2[1][2], matrix2[2][2]

##################################################
# gui
params =
    Axes: if urlParams.axes == "false" then false else true
params["range U"]  = if urlParams.rangeU?  then true else false
params["range T"]  = if urlParams.rangeT?  then true else false
params["range TU"] = if urlParams.rangeTU? then true else false

gui = new dat.GUI()
gui.add(params, 'Axes').onFinishChange (val) ->
    for i in [0...3]
        demos[i].mathbox.select(".view#{i+1}-axes").set 'visible', val

##################################################
# Compute output vectors
tmpVec = new THREE.Vector3()
computeOut = () ->
    tmpVec.set.apply(tmpVec, vector1).applyMatrix3 tMatrix1
    vector2[0] = tmpVec.x
    vector2[1] = tmpVec.y
    vector2[2] = tmpVec.z
    tmpVec.applyMatrix3 tMatrix2
    vector3[0] = tmpVec.x
    vector3[1] = tmpVec.y
    vector3[2] = tmpVec.z
    updateCaption()

##################################################
# make demos

setupDemo = (opts) ->
    new (if opts.dim == 3 then Demo else Demo2D) {
        mathbox: element: document.getElementById "mathbox#{opts.index}"
        scaleUI: false
    }, () ->
        {@index, @vector, @dim, @color, @label} = opts
        window["mathbox#{@index}"] = @mathbox

        ##################################################
        # Demo parameters
        range = 10.0
        if urlParams["range#{@index}"]?
            range = parseFloat urlParams["range#{@index}"]

        ##################################################
        # view, axes
        r = range
        @viewObj = @view
            name:       "view#{@index}"
            viewRange:  [[-r,r], [-r,r], [-r,r]][0...@dim]
            axisLabels: false
        @mathbox.select(".view#{@index}-axes").set 'visible', params.Axes

        ##################################################
        # labeled vector
        labeled = @labeledVectors @viewObj,
            name:          "labeled#{@index}"
            vectors:       [@vector]
            colors:        [@color]
            labels:        [@label]
            live:          true
            zeroPoints:    true
            zeroThreshold: 0.1
            vectorOpts:    zIndex: 2
            labelOpts:     zIndex: 3
            zeroOpts:      zIndex: 3

        ##################################################
        # Clip cube
        @clipCubeObj = @clipCube @viewObj,
            draw:   @dim == 3
            hilite: @dim == 3
            color:  new THREE.Color .75, .75, .75
            material: new THREE.MeshBasicMaterial
                color:       new THREE.Color 0, 0, 0
                opacity:     0.5
                transparent: true
                visible:     false
                depthWrite:  false
                depthTest:   true

window.demo1 = setupDemo
    index:  1
    vector: vector1
    dim:    dim1
    color:  color1
    label:  'x'

window.demo2 = setupDemo
    index:  2
    vector: vector2
    dim:    dim2
    color:  color2
    label:  'U(x)'

window.demo3 = setupDemo
    index:  3
    vector: vector3
    dim:    dim3
    color:  color3
    label:  'T(U(x))'

demos = [demo1, demo2, demo3]
groupControls demo1, demo2, demo3

##################################################
# dragging
demo1.draggable demo1.viewObj,
    points:   [vector1]
    postDrag: computeOut

##################################################
# ranges
demo2.rangeU = demo2.subspace
    name:    'rangeU'
    vectors: matrix1
    live:    false
    color:   new THREE.Color color1[0]/2, color1[1]/2, color1[2]/2
    mesh:    demo2.clipCubeObj.mesh
if demo2.rangeU.dim == 3
    demo2.clipCubeObj.installMesh()
    demo2.clipCubeObj.mesh.material.color.setRGB color1[0]/2, color1[1]/2, color1[2]/2
demo2.rangeU.draw demo2.clipCubeObj.clipped
demo2.rangeU.setVisibility params['range U']

demo3.rangeT = demo3.subspace
    name:    'rangeT'
    vectors: matrix2
    live:    false
    color:   new THREE.Color color2[0]/2, color2[1]/2, color2[2]/2
    mesh:    demo3.clipCubeObj.mesh
demo3.rangeT.draw demo3.clipCubeObj.clipped
demo3.rangeT.setVisibility params['range T']

demo3.rangeTU = demo3.subspace
    name:    'rangeTU'
    vectors: matrix3
    live:    false
    color:   new THREE.Color color3[0]/2, color3[1]/2, color3[2]/2
    mesh:    demo3.clipCubeObj.mesh
demo3.rangeTU.draw demo3.clipCubeObj.clipped
demo3.rangeTU.setVisibility params['range TU']
demo3.clipCubeObj.installMesh() if demo3.rangeT.dim == 3 or demo3.rangeTU.dim == 3

gui.add(params, 'range U').onFinishChange demo2.rangeU.setVisibility
gui.add(params, 'range T').onFinishChange (val) ->
    if val and demo3.rangeT.dim == 3
        demo3.clipCubeObj.mesh.material.color.setRGB \
            color2[0]/2, color2[1]/2, color2[2]/2
    demo3.rangeT.setVisibility val
gui.add(params, 'range TU').onFinishChange (val) ->
    if val and demo3.rangeTU.dim == 3
        demo3.clipCubeObj.mesh.material.color.setRGB \
            color3[0]/2, color3[1]/2, color3[2]/2
    demo3.rangeTU.setVisibility val

matrix1Elt = document.getElementById 'matrix1-here'
matrix2Elt = document.getElementById 'matrix2-here'
matrix3Elt = document.getElementById 'matrix3-here'
hexColor1 = "#" + new THREE.Color(color1[0], color1[1], color1[2]).getHexString()
hexColor2 = "#" + new THREE.Color(color2[0], color2[1], color2[2]).getHexString()
hexColor3 = "#" + new THREE.Color(color3[0], color3[1], color3[2]).getHexString()

updateCaption = () ->
    str  = "U(\\color{#{hexColor1}}{x}) = "
    str += demo1.texMatrix matrix1, {cols: dim1, rows: dim2}
    str += demo1.texVector vector1, {color: hexColor1}
    str += "="
    str += demo2.texVector vector2, {color: hexColor2}
    katex.render str, matrix1Elt
    str  = "T(\\color{#{hexColor2}}{U(x)}) = "
    str += demo2.texMatrix matrix2, {cols: dim2, rows: dim3}
    str += demo2.texVector vector2, {color: hexColor2}
    str += "="
    str += demo3.texVector vector3, {color: hexColor3}
    katex.render str, matrix2Elt
    str  = "T\\circ U(\\color{#{hexColor1}}{x}) = "
    str += demo1.texMatrix matrix3, {cols: dim1, rows: dim3}
    str += demo1.texVector vector1, {color: hexColor1}
    str += "="
    str += demo3.texVector vector3, {color: hexColor3}
    katex.render str, matrix3Elt

computeOut()
