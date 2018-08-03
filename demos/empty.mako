## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Empty axes</%block>

##

new Demo2D {}, () ->
    window.mathbox = @mathbox

    view = @view grid: false

    cube = @clipCube view,
        hilite: false

    vectors = [[1,1], [-1, 1]]
    colors  = [new Color "red", new Color "green"]
    labels  = ['v', 'w']

    subspace = @subspace
        vectors: vectors
        noPlane: true
    subspace.draw cube.clipped

    params =
        x: 1.2
        y: -2.5

    @linearCombo view,
        vectors: vectors
        colors:  colors
        labels:  labels
        coeffs:  params

    @labeledVectors view,
        vectors:       vectors
        colors:        colors
        labels:        labels
        zeroPoints:    true
        zeroThreshold: 0.05
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    @draggable view,
        points: vectors
        size:   20

    @grid cube.clipped,
        vectors: vectors

    @caption "Test caption"

