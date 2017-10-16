## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">The function Ax=b</%block>

<%block name="inline_style">
html, body {
    margin: 0;
    height: 100%;
}
#mathbox1 {
    width:    100%;
    height:   100%;
    position: relative;
    z-index:  0;
}
#inset-container {
    width : 30%;
    position: absolute;
    bottom:   0px;
    right:    0px;
    z-index:  1;
}
#inset-container2 {
    position: absolute;
    left:   0px;
    top:    0px;
    transform: translateY(-100%);
    width:  100%;
    padding-bottom: 100%;
    border: 2px solid #cccccc;
    box-sizing: border-box;
}
#mathbox2 {
    position: absolute;
    width:    100%;
    height:   100%;
}
#inconsistent {
    font-weight:   bold;
    font-size:     120%;
    padding-left:  1em;
    padding-right: 1em;
    color:         red;
    display:       none;
}
.overlay-text > p:last-child {
    text-align: center;
}
</%block>

<%block name="body_html">
<div id="mathbox1">
    <div id="inset-container">
        <div id="inset-container2">
            <div id="mathbox2"></div>
        </div>
    </div>
    <div class="overlay-text">
      <p><span id="the-equation"></span>
          <span id="inconsistent">inconsistent</span></p>
      <p>[Click and drag the heads of x and b]</p>
    </div>
</div>
</%block>

##

##################################################
# Globals
vector    = [-1, 2, 3]
outVec    = [0, 0]
colBasis  = []
showSolnsKey = "Show solution set"
lockSolnsKey = "Lock solution set"

solve         = null
solnspace     = null
params        = null
labeled       = null
updateCaption = null


window.demo1 = new Demo {
    mathbox: element: document.getElementById "mathbox1"
}, () ->
    window.mathbox1 = @mathbox

    ##################################################
    # Demo parameters
    @showSolns = @urlParams.show ? false
    @lockSolns = @urlParams.lock ? true
    @matrix    = [ 1, -1,  2,
                  -2,  2, -4]

    if @urlParams.x?
        vector = @urlParams.x.split(",").map parseFloat
    if @urlParams.mat?
        @matrix = @urlParams.mat.split(",").map parseFloat

    @tMatrix = new THREE.Matrix3()
    @tMatrix.set @matrix[0], @matrix[1], @matrix[2],
                 @matrix[3], @matrix[4], @matrix[5],
                          0,          0,          0
    @matrix = [[@matrix[0], @matrix[3]],
               [@matrix[1], @matrix[4]],
               [@matrix[2], @matrix[5]]]

    # Scratch
    tmpVec = new THREE.Vector3()

    ##################################################
    # gui
    params =
        Axes: not (@urlParams.axes in ['off', 'disabled'])
        Homogeneous: () =>
            vector[0] = vector[1] = vector[2] = 0
            params[showSolnsKey] = true
            params[lockSolnsKey] = true
            @mathbox.select('#solnset').set 'visible', true
            computeOut()
    params[showSolnsKey] = @showSolns
    params[lockSolnsKey] = @lockSolns

    gui = new dat.GUI width: 350
    gui.add(params, 'Axes').onFinishChange (val) =>
        @mathbox.select(".view-axes").set 'visible', val
    gui.add(params, showSolnsKey).listen().onFinishChange (val) =>
        @mathbox.select("#solnset").set 'visible', val
    gui.add(params, lockSolnsKey).listen()
    gui.add params, 'Homogeneous'

    ##################################################
    # view, axes
    view = @view
        name: 'view1'
        viewRange: [[-5,5], [-5,5], [-5,5]]
    @mathbox.select(".view1-axes").set 'visible', params.Axes

    ##################################################
    # labeled vector
    labeled = @labeledVectors view,
        vectors:       [vector]
        colors:        [[0, 1, 0, 1]]
        labels:        ['x']
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.1
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    ##################################################
    # Clip cube
    clipCube = @clipCube view,
        draw:     true
        color:    new THREE.Color .75, .75, .75

    ##################################################
    # Solution set
    [nulBasis, colBasis, Emat, solve] = @rowred (c.slice() for c in @matrix)
    solnspace = @subspace
        name: 'nulspace'
        vectors: nulBasis
        live: false
        surfaceOpts: id: 'solnset'
    tform = clipCube.clipped.transform().bind position: () => vector
    solnspace.draw tform
    @mathbox.select("#solnset").set 'visible', params[showSolnsKey]

    ##################################################
    # Dragging
    computeOut = () =>
        tmpVec.set.apply(tmpVec, vector).applyMatrix3 @tMatrix
        outVec[0] = tmpVec.x
        outVec[1] = tmpVec.y
        updateCaption()

    onDrag = (vec) =>
        if params[showSolnsKey] and params[lockSolnsKey]
            tmpVec.set.apply tmpVec, vector
            solnspace.project vec.sub(tmpVec), vec
            vec.add tmpVec

    @draggable view,
        points: [vector]
        onDrag: onDrag
        postDrag: computeOut

    ##################################################
    # Caption
    eqnElt = document.getElementById 'the-equation'
    inconsElt = document.getElementById 'inconsistent'
    updateCaption = () =>
        if labeled.hidden
            katex.render @texMatrix(@matrix, {rows: 2, precision: -1}) \
                + '\\color{#00ff00}{x}' \
                + ' = ' \
                + @texVector(outVec, {color: '#ffff00', dim: 2}),
                eqnElt
            inconsElt.style.display = 'inline'
        else
            katex.render @texMatrix(@matrix, {rows: 2, precision: -1}) \
                + @texVector(vector, color: '#00ff00') \
                + ' = ' \
                + @texVector(outVec, {color: '#ffff00', dim: 2}),
                eqnElt
            inconsElt.style.display = 'none'

    computeOut()


window.demo2 = new Demo2D {
    mathbox: element: document.getElementById "mathbox2"
    scaleUI: false
}, () ->
    window.mathbox2 = @mathbox

    ##################################################
    # view, axes
    view = @view
        name: 'view2'
        axisLabels: false

    ##################################################
    # labeled vector
    @labeledVectors view,
        vectors:       [outVec]
        colors:        [[1, 1, 0, 1]]
        labels:        ['b']
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    ##################################################
    # Clip cube
    clipCube = @clipCube view,
        draw: false
        hilite: false

    ##################################################
    # Column span
    subspace = @subspace
        name: 'colspace'
        vectors: colBasis
        live: false
    subspace.draw clipCube.clipped

    ##################################################
    # Dragging
    snapThreshold = 1.0
    snapped = new THREE.Vector3()
    diff = new THREE.Vector3()

    # Snap to column span
    onDrag = (vec) =>
        subspace.project vec, snapped
        diff.copy(vec).sub snapped
        if diff.lengthSq() <= snapThreshold
            vec.copy snapped

    computeIn = () ->
        inVec = solve outVec
        if inVec?
            # Find solution closest to current vector
            tmpVec.set vector[0]-inVec[0], vector[1]-inVec[1], vector[2]-inVec[2]
            solnspace.project tmpVec, tmpVec
            vector[0] = tmpVec.x + inVec[0]
            vector[1] = tmpVec.y + inVec[1]
            vector[2] = tmpVec.z + inVec[2]
            mathbox1.select("#solnset").set 'visible', params[showSolnsKey]
            labeled.show()
        else
            # So the zero point doesn't show up
            mathbox1.select("#solnset").set 'visible', false
            labeled.hide()
        updateCaption()

    tmpVec = new THREE.Vector3()
    @draggable view,
        points: [outVec]
        onDrag: onDrag
        postDrag: computeIn


