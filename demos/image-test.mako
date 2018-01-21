## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">image element test</%block>

## */

new Demo {
    camera:
        proxy:     true
        lookAt:   [.5, .5, .5]
        position: [3, .5, .5]
    preload: {theo : 'img/theo7.jpg'}
    focusDist: 3
}, () ->
    view = @view
        axes: false
        grid: false
        viewRange: [[0, 1], [0, 1], [0, 1]]

    view
        .array
            width:    2
            items:    3
            channels: 4
            data:     [[0,0,0,1],[0,0,0,1],[0,0,0,1],
                       [1,0,0,1],[0,1,0,1],[0,0,1,1]]
        .line
            end:    true
            color:  "white"
            colors: "<"
            points: "<"
            width:  4
            size:   5
            zIndex: 1
        .grid
            divideX: 8
            divideY: 8
            width:   1
        .grid
            divideX: 8
            divideY: 8
            axes:    [1,3]
            width:   1
        .grid
            divideX: 8
            divideY: 8
            axes:    [2,3]
            width:   1

    view
    # The image data source allows an arbitrary image or texture to be sampled as
    # data.
        .image
            image: this.theo
            # width: 1280,
            # height: 914,
            minFilter: 'nearest'
            magFilter: 'nearest'
            id: "imagesrc"
        .point
            color:  "white"
            size:   1
            points: "#imagesrc"
            colors: "#imagesrc"
            zIndex: 1
    # Wavy plane
        .area
            id:       "points"
            width:    20
            height:   2
            channels: 3
            expr: (emit, x, y, i, j, t) ->
                wave = Math.sin(x*10+t*10)/15.0 + 1.0
                emit Math.cos(x*(-3*π/4+.700*1.5) + (1-x)*(-3*π/4-.700*1.5)) \
                     * wave + .5,
                     Math.sin(x*(-3*π/4+.700*1.5) + (1-x)*(-3*π/4-.700*1.5)) \
                     * wave + .5,
                     y*1.5 - .25
        .surface
            color:   0xffffff
            points:  '#points'
            map:     '#imagesrc'
            opacity: 1.0
            fill:    true
