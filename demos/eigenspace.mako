## -*- coffee -*-

<%! roots=True %>

<%inherit file="base2.mako"/>

<%block name="title">Eigenspaces</%block>

<%block name="inline_style">
${parent.inline_style()}
.espace-0 {
    color: #ff0000;
}
.espace-1 {
    color: #00ff00;
}
.espace-2 {
    color: #000000;
}
.vector {
    color: #ffff00
}
.overlay-popup h3 {
    font-size: 120%;
    text-align: center;
}
.overlay-popup p {
    text-align: center;
}
</%block>

##

matrix = urlParams.get 'mat', 'matrix', [[ 7/2,  0,  3],
                                         [-3/2,  2, -3],
                                         [-3/2,  0, -1]]
size = matrix.length
switch size
    when 2 then matrixT = ([matrix[0][i], matrix[1][i]] for i in [0...size])
    when 3 then matrixT = ([matrix[0][i], matrix[1][i], matrix[2][i]] for i in [0...size])

color1 = [.5, 0,  0]
color2 = [0, .5,  0]
color3 = [0,  0, .5]
colors = [color1, color2, color3]
hexColors = ['#ff0000', '#00ff00', '#0000ff']

window.demo = new (if size == 2 then Demo2D else Demo) {
    mathbox:
        mathbox:
            warmup:  10
            splash:  false
            inspect: false
}, () ->
    window.mathbox = @mathbox

    view = @view
        axes: false
        grid: size == 2

    clipCube = @clipCube view,
        draw:   size == 3
        hilite: size == 3
        material: new THREE.MeshBasicMaterial
            color:       new THREE.Color 0.5, 0, 0
            opacity:     0.5
            transparent: true
            visible:     true
            depthWrite:  false
            depthTest:   true

    ##################################################
    # Compute and draw eigenspaces
    eigenvals = eigenvalues matrix
    eigenvals.sort (x, y) -> x[0] - y[0]
    eigenspaces = []
    for [eigenvalue, mult], j in eigenvals
        console.log("Eigenvalue: #{eigenvalue} (#{mult})")
        matrix2 = (col.slice() for col in matrixT)
        for i in [0...size]
            matrix2[i][i] -= eigenvalue
        [nulBasis] = rowReduce matrix2, epsilon: 1e-6
        console.log(nulBasis)
        if mult == 3
            clipCube.installMesh()
        # nulBasis had better be a nonempty list
        subspace = @subspace
            vectors: nulBasis
            name:    "eigenspace-#{j}"
            live:    false
            color:   colors[j]
            # Lines before planes for transparency
            lineOpts:
                zOrder: 0
            surfaceOpts:
                zOrder: 1
        subspace.draw clipCube.clipped
        eigenspaces.push subspace

    ##################################################
    # Labeled vectors
    vectorIn  = [1, 2, 3].slice 0, size
    vectorOut = [0, 0, 0].slice 0, size
    @labeledVectors view,
        vectors:       [vectorIn, vectorOut]
        colors:        [[1, 1, 0, 1], [.7, .7, 0, .7]]
        labels:        ['x', 'Ax']
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    switch size
        when 2
            computeOut = () ->
                m = matrix
                v = vectorIn
                vectorOut[0] = m[0][0] * v[0] + m[0][1] * v[1]
                vectorOut[1] = m[1][0] * v[0] + m[1][1] * v[1]
                updateCaption()
        when 3
            computeOut = () ->
                m = matrix
                v = vectorIn
                vectorOut[0] = m[0][0]*v[0] + m[0][1]*v[1] + m[0][2]*v[2]
                vectorOut[1] = m[1][0]*v[0] + m[1][1]*v[1] + m[1][2]*v[2]
                vectorOut[2] = m[2][0]*v[0] + m[2][1]*v[1] + m[2][2]*v[2]
                updateCaption()

    ##################################################
    # Dragging and snapping
    snapThreshold = 1.0
    snapped = new THREE.Vector3()
    diff = new THREE.Vector3()
    onSubspace = -1

    # Snap to column span
    snap = (vec) =>
        onSubspace = -1
        if vec.lengthSq() <= snapThreshold
            vec.set 0, 0, 0
            return
        for subspace, i in eigenspaces
            subspace.project vec, snapped
            diff.copy(vec).sub snapped
            if diff.lengthSq() <= snapThreshold
                vec.copy snapped
                onSubspace = i
                return

    if vectorIn[0]*vectorIn[0]+vectorIn[1]*vectorIn[1]+vectorIn[2]*vectorIn[2] >= 1e-8
        for subspace, i in eigenspaces
            if subspace.contains vectorIn
                onSubspace = i
                break

    @draggable view,
        points:   [vectorIn]
        onDrag:   snap
        postDrag: computeOut

    ##################################################
    # Caption
    str = '<p><span id="eqn-here"></span></p>'
    evalStrings = []
    for [eigenvalue, mult], j in eigenvals
        eigenval = eigenvalue.toFixed(2)
        if @urlParams.nospace?
            str += ''
        else if @urlParams.nomult?
            str += "<p>This is the <span class=\"espace-#{j}\">" +
                   "#{eigenval}-eigenspace</span></p>"
        else
            str += "<p>The <span class=\"espace-#{j}\">" +
                   "#{eigenval}-eigenspace</span> " +
                   "has algebraic multiplicity #{mult} " +
                   "and geometric multiplicity #{eigenspaces[j].dim}" +
                   "</p>"
        evalStrings.push katex.renderToString \
            "A\\color{#ffff00}{x} = \\color{#{hexColors[j]}}{#{eigenval}}" + \
            "\\color{#ffff00}{x}"
    @caption str
    eqnElt = document.getElementById 'eqn-here'

    popup = @popup()

    updateCaption = () =>
        str = @texMatrix matrixT
        str += @texVector vectorIn, color: '#ffff00'
        str += '='
        str += @texVector vectorOut, color: '#888800'
        if onSubspace != -1
            eigenval = eigenvals[onSubspace][0].toFixed(2)
            str += "= \\color{#{hexColors[onSubspace]}}{#{eigenval}}"
            str += @texVector vectorIn, color: '#ffff00'
            popup.show "<h3><span class=\"vector\">x</span> is an eigenvector" + \
                       " with eigenvalue <span class=\"espace-#{onSubspace}\">" + \
                       "#{eigenval}</span></h3>" + \
                       "<p>#{evalStrings[onSubspace]}</p>"
        else
            popup.hide()
        katex.render str, eqnElt

    computeOut()
