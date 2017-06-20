"use strict"

# TODO: Make this interactive!!!  The student can do their own row reduction.

deepCopy = (x) ->
    if x instanceof Array
        out = []
        for v in x
            out.push(deepCopy v)
        return out
    else if x? and typeof x == 'object'
        out = {}
        for k, v of x
            out[k] = deepCopy v
        return out
    else
        return x

arraysEqual = (a, b) ->
    if a instanceof Array && b instanceof Array
        if a.length != b.length
            return false
        for i in [0...a.length]
            if !arraysEqual a[i], b[i]
                return false
        return true
    else
        return a == b

# Find best fractional approximation by walking the Stern-Brocot tree
# https://stackoverflow.com/a/5128558
approxFraction = (x, error) ->
    n = Math.floor x
    x -= n
    if x < error
        return [n, 1]
    else if 1 - error < x
        return [n+1, 1]
    # The lower fraction is 0/1
    lower_n = 0
    lower_d = 1
    # The upper fraction is 1/1
    upper_n = 1
    upper_d = 1
    while true
        # The middle fraction is (lower_n + upper_n) / (lower_d + upper_d)
        middle_n = lower_n + upper_n
        middle_d = lower_d + upper_d
        # If x + error < middle
        if middle_d * (x + error) < middle_n
            # middle is our new upper
            upper_n = middle_n
            upper_d = middle_d
        # Else If middle < x - error
        else if middle_n < (x - error) * middle_d
            # middle is our new lower
            lower_n = middle_n
            lower_d = middle_d
        # Else middle is our best fraction
        else
            return [n * middle_d + middle_n, middle_d]

# Turn decimals that want to be fractions into fractions
texFraction = (x, error=0.00001) ->
    [num, den] = approxFraction x, error
    if den == 1
        return num.toString()
    return "\\frac{#{num}}{#{den}}"


# This class animates a row reduction sequnce on a matrix.
class RRMatrix

    constructor: (@numRows, @numCols, opts) ->
        {@name, @fontSize, @rowHeight, @rowSpacing, @colSpacing} = opts? || {}

        @name       ?= "rrmat"
        @fontSize   ?= 20
        @rowHeight  ?= @fontSize * 1.2
        @rowSpacing ?= @fontSize
        @colSpacing ?= @fontSize

        @matHeight = @rowHeight * @numRows + @rowSpacing * (@numCols-1)

        @domClass = MathBox.DOM.createClass render:
            (el, props, children) =>
                props.innerHTML = katex.renderToString(children)
                props.innerHTML += '<span class="baseline-detect"></span>'
                if props.i? && props.j?
                    props.id = "#{@name}-#{props.i}-#{props.j}"
                    props.className =
                        "#{@name}-col-#{props.j}" +
                        " #{@name}-row-#{props.i}" +
                        " #{@name} bound-entry #{@name}-matrix-entry"
                    delete props.i
                    delete props.j
                else
                    otherClasses = if props.className? then ' ' + props.className else ''
                    props.className = "#{@name} bound-entry" + otherClasses
                return el('span', props)

        @swapLineSamples = 30
        mathbox.three.on 'pre', @frame
        mathbox.three.on 'post', @frame

        @animState =
            # All text element positions go hear.  This is because pixel
            # position readback is slow (gl.readPixels is slow).
            # First come the matrix entries.  The next row only uses the first
            # entry, which is the multiplication flyer position.  The next row
            # is the row addition flyer.  The next two rows are the opening and
            # closing parens for the row replacement multiplication factor.
            positions: []
            # These are the contents of the DOM entries, in the order described
            # above.
            html: []
            # Matrix entries (as decimal numbers)
            matrix: []
            # Bracket path
            bracket: []
            # Multiplication factor opacity
            multOpacity: 0.0
            # Row replacement factor opacity
            rrepOpacity: 0.0
            rrepParenOpacity: 0.0

        # Zero out the original matrix
        @animState.matrix =
            (Array.apply(null, Array @numCols).map Number.prototype.valueOf, 0 \
                for [0...@numRows])
        # @animState.html is set in install()

        [positions, @animState.bracket, @matWidth] = @computePositions()
        for j in [0..@numRows+3]
            @animState.positions[j] = []
            @animState.positions[j][i] = [1000,-1000,0] for i in [0...@numCols]
        @animState.positions =
            @_insertMatrixPositions positions, @animState.positions

        mathbox.select('root')[0].clock.on 'clock.tick', @multEffect
        @doMultEffect = null
        mathbox.select('root')[0].clock.on 'clock.tick', @repEffect
        @doRepEffect = null

    _id: (element) => "#{@name}-#{element}"

    # We have to keep the matrix positions inside a larger matrix, so...
    _insertMatrixPositions: (matPos, allPos) ->
        allPos = deepCopy allPos
        allPos[i][j][k] = row[j][k] for row, i in matPos \
            for j in [0...@numCols] for k in [0,1]
        allPos
    _extractMatrixPositions: (allPos) ->
        allPos[i] for i in [0...@numRows]

    computePositions: () =>
        #console.log "recomputing matrix sizes..."
        positions = []
        bracket = []
        matWidth = 0
        colWidths = []

        # Compute column widths
        for j in [0...@numCols]
            col = document.getElementsByClassName "#{@name}-col-#{j}"
            max = @fontSize # default / minimum width
            for elt in col
                max = Math.max max, elt.getBoundingClientRect().width
            colWidths.push max
            matWidth += max
        matWidth += 3 * @colSpacing

        # Compute entry positions
        y = -@matHeight / 2 + @rowHeight
        for i in [0...@numRows]
            x = -matWidth / 2
            rowPos = []
            for j in [0...@numCols]
                x += colWidths[j]/2
                rowPos.push [x,-y]
                x += colWidths[j]/2
                x += @colSpacing
            y += @rowHeight + @rowSpacing
            positions.push rowPos

        # Compute bracket path
        x1 = -matWidth/2 - @colSpacing + 7
        x2 = -matWidth/2 - @colSpacing
        y1 = @matHeight / 2
        y2 = -(@matHeight + @fontSize) / 2
        bracket = [[x1,y1], [x2,y1], [x2,y2], [x1,y2]]

        return [positions, bracket, matWidth]

    resize: () ->
        [positions, bracket, @matWidth] = @computePositions()
        if !arraysEqual positions, @_extractMatrixPositions @animState.positions
            @animState.positions =
                @_insertMatrixPositions positions, @animState.positions
            play1 = @play @positions,
                script:
                    0:   {props: {data: Array.from @positions.get 'data'}}
                    0.2: {props: {data: @animState.positions}}
            play1.on 'play.done', (e) =>
                play1.remove()
                @positions.set 'data', @animState.positions
        if !arraysEqual bracket, @animState.bracket
            @animState.bracket = bracket
            play2 = @play @bracket,
                script:
                    0:   {props: {data: Array.from @bracket.get 'data'}}
                    0.2: {props: {data: bracket}}
            play2.on 'play.done', (e) =>
                play2.remove()
                @bracket.set 'data', @animState.bracket

    play: (element, opts) ->
        # Thin wrapper around mathbox.play
        return unless @view?
        id = "#{@name}-play-#{element[0].id}"
        mathbox.remove "#" + id
        opts.target  = element
        opts.id      = id
        opts.classes = [@name]
        opts.to     ?= Math.max.apply null, (k for k of opts.script)
        play = @view.play opts
        # Don't auto-remove, as there may be other listeners for play.done
        #play.on 'play.done', (e) -> play.remove(); console.log "Play done"
        play

    fade: (element, script) ->
        # Fade an element in or out
        script2 = {}
        script2[k] = {props: {opacity: v}} for k, v of script
        @play element, script: script2

    onNextFrame: (after, callback, stage='pre') ->
        # Execute 'callback' after 'after' frames
        @nextFrame ?= {}
        @nextFrame[stage] ?= {}
        @nextFrame[stage][mathbox.three.Time.frames + (after-1)] = callback
    frame: (event) =>
        return unless @nextFrame?[event.type]?
        frames = mathbox.three.Time.frames
        for f, callback of @nextFrame[event.type]
            if f < frames
                delete @nextFrame[event.type][f]
                callback()

    newState: (nextState) =>
        # Set all displayed elements to a new state
        @animState = nextState
        @htmlMatrix @animState.matrix, @animState.html
        # Stop/delete any animations
        mathbox.remove "play.#{@name}"
        @positions.set 'data', @animState.positions
        @bracket.set 'data', @animState.bracket
        @doMultEffect = null
        @doRepEffect = null
        # Clean up opacity effects
        document.getElementById(@_id 'multFlyer').style.opacity =
            @animState.multOpacity
        for elt in document.getElementsByClassName @_id('rrepFactor')
            elt.style.opacity = @animState.rrepParenOpacity
        for elt in document.getElementsByClassName @_id('addFlyer')
            elt.style.opacity = @animState.rrepOpacity
        for elt in document.getElementsByClassName "#{@name}-matrix-entry"
            elt.style.opacity = 1
        @resize()

    htmlMatrix: (matrix, html) =>
        # Render matrix in html
        htmlMat = []
        for i in [0...@numRows]
            row = []
            for j in [0...@numCols]
                row.push(@domEl @domClass, {i: i, j: j}, texFraction matrix[i][j])
            html[i] = row
        html

    install: (@view) ->
        @positions = @view.matrix
            data:     @animState.positions,
            width:    @numCols
            height:   @numRows+4
            channels: 3
            classes:  [@name]
            id:       @_id 'positions'

        html = @view.html
            width:   @numCols
            height:  @numRows+4
            classes: [@name]
            live:    true

        # This is the element factory.  No good way to get at this.
        @domEl = html[0].controller.dom.el
        @htmlMatrix @animState.matrix, @animState.html

        # Multiply-by number flyer
        @animState.html[@numRows] = []
        @animState.html[@numRows][0] =
            @domEl @domClass, {id: @_id('multFlyer'), className: 'mult-flyer'}, ''
        # Nothing in the rest of the row
        for i in [1...@numCols]
            @animState.html[@numRows][i] =
                @domEl @domClass, {style: display: 'none'}, ''

        # Add row flyer
        @animState.html[@numRows+1] = []
        for i in [0...@numCols]
            @animState.html[@numRows+1][i] =
                @domEl @domClass, {className: @_id 'addFlyer'}, ''
        # Opening and closing parens for row replacement factor
        for j in [@numRows+2..@numRows+3]
            @animState.html[j] = []
            for i in [1...@numCols]
                # Empty
                @animState.html[j][i] =
                    @domEl @domClass, {style: display: 'none'}, ''
        @animState.html[@numRows+2][0] =
            @domEl @domClass, {
                className: 'rrep-factor ' + @_id('rrepFactor')
                id: @_id 'rrepParenLeft'}, ''
        @animState.html[@numRows+3][0] =
            @domEl @domClass, {
                className: 'rrep-factor ' + @_id('rrepFactor')
                id: @_id 'rrepParenRight'}, ''

        html.set
            # This is an expr so mathbox.inspect() isn't a million lines
            expr:    (emit, el, j, i) => emit(@animState.html[i][j])

        @view.dom
            snap:    false
            offset:  [0,0]
            depth:   0
            zoom:    1
            outline: 2
            size:    @fontSize
            classes: [@name]
            attributes: style: height: "0px"

        # @view.matrix
        #     width:    @numCols
        #     height:   @numRows
        #     channels: 4
        #     id:       "colors"
        #     expr: (emit, i, j) ->
        #         emit(1,0,0,1) if j == 0
        #         emit(0,1,0,1) if j == 1
        #         emit(0,0,1,1) if j == 2
        #         emit(0,0,0,1) if j == 3

        # @view.point
        #     points: "#rrmat-positions"
        #     colors: "#colors"

        # Brackets
        @bracket = @view.array
            channels: 2
            width:    4
            classes:  [@name]
            id:       @_id 'bracket'
            data: @animState.bracket

        @view.line
            color:   "black"
            width:   2
            classes: [@name]
        .transform
            scale:   [-1, 1, 1]
            classes: [@name]
        .line
            color:   "black"
            width:   2
            classes: [@name]

        # Swap-points arrow
        @swapLine = @view.array
            channels: 2
            width:    @swapLineSamples + 1
            classes:  [@name]
            id:       @_id 'swapLine'
            data:     @swapLinePoints(100,-100)[0]

        @swapLineGeom = @view.line
            color:   "green"
            width:   4
            start:   true
            end:     true
            visible: false
            id:       @_id 'swapLineGeom'
            classes:  [@name]

        # This gets run once after the DOM elements are added
        observer = new MutationObserver (mutations, observer) =>
            elts = document.querySelectorAll ".#{@name} > .baseline-detect"
            # There are the matrix entries, the mult flyer, the row flyer, and
            # the row replacement factor opening and closing parens
            if elts.length >= (@numRows + 4) * @numCols
                @alignBaselines elts
                @resize()
                observer.disconnect()
        observer.observe document.getElementById('mathbox'),
               childList:     true
               subtree:       true

        # This only runs on DOM element updates
        observer = new MutationObserver (mutations) =>
            for mutation in mutations
                continue unless mutation.target.classList.contains 'bound-entry'
                @alignBaselines mutation.target.getElementsByClassName 'baseline-detect'
        observer.observe document.getElementById('mathbox'),
               childList:     true
               subtree:       true


        @

    alignBaselines: (elts) =>
        # Align baselines with the reference points (javascript hack)
        elts ?= document.querySelectorAll ".#{@name} > .baseline-detect"
        for elt in elts
            elt.parentElement.style.top = -elt.offsetTop + "px"

    swapLinePoints: (top, bot) ->
        # Get points for the swap-arrows line
        samples = @swapLineSamples
        lineHeight = Math.abs(top - bot)
        center = (top + bot) / 2
        points = ([Math.sin(π * i/samples) * @colSpacing * 3 + @matWidth/2 +
                      @colSpacing + 2,
                   Math.cos(π * i/samples) * lineHeight/2 + center] \
                  for i in [0..samples])
        swapPoints = ([x,-y+2*center] for [x,y] in points)
        return [points, swapPoints]

    rowSwap: (row1, row2) ->
        nextState = deepCopy @animState
        [nextState.matrix[row1], nextState.matrix[row2]] =
            [nextState.matrix[row2], nextState.matrix[row1]]

        # Put moving rows on top
        for i in [row1, row2]
            for j in [0...@numCols]
                @animState.positions[i][j][2] = 10

        # Transition
        transPos = deepCopy @animState.positions
        [transPos[row1], transPos[row2]] =
            [transPos[row2], transPos[row1]]

        fadeTime = 0.3
        swapTime = 1

        play = @play @positions,
            delay: fadeTime
            pace:  swapTime
            script:
                0: {props: {data: @animState.positions}}
                1: {props: {data: transPos}}

        top = @animState.positions[row1][0][1] + @fontSize/3
        bot = @animState.positions[row2][0][1] + @fontSize/3
        [@animState.swapLine, transLine] = @swapLinePoints top, bot
        @swapLine.set 'data', @animState.swapLine
        @swapLineGeom.set 'visible', true

        script = {}
        script[0]                   = 0
        script[fadeTime]            = 1
        script[fadeTime+swapTime]   = 1
        script[2*fadeTime+swapTime] = 0
        @fade @swapLineGeom, script
            .on 'play.done', (e) =>
                @newState nextState
                @swapLineGeom.set 'visible', false

        play = @play @swapLine,
            delay: fadeTime
            pace:  swapTime
            script:
                0: {props: {data: @animState.swapLine}}
                1: {props: {data: transLine}}

    multEffect: () =>
        # Fade numbers in and out when multiplying
        return unless @doMultEffect
        {row, rowNum, flyer, start, clock,
            rowPos, past, opacity, nextState} = @doMultEffect
        elapsed = clock.getTime().clock - start
        flyer.style.opacity = Math.min(elapsed/0.3, 1)
        box = flyer.getBoundingClientRect()
        flyerPos = (box.left + box.right) / 2
        for elt, i in row
            if flyerPos < rowPos[i] && !past[i]
                # Change the number as the flyer flies past
                past[i] = true
                @animState.html[rowNum][i] = nextState.html[rowNum][i]
            elt.style.opacity = opacity(Math.abs(flyerPos - rowPos[i]))
        if past[0]
            # Fade out the flyer
            flyer.style.opacity =
                Math.max(1 - (rowPos[0] - flyerPos)/@fontSize/5, 0)

    rowMult: (rowNum, factor) ->
        startX = @matWidth/2 + @colSpacing + 10
        rowY = @animState.positions[rowNum][0][1]
        @animState.html[@numRows][0] =
            @domEl @domClass, {id: @_id('multFlyer'), className: 'mult-flyer'},
                '\\times' + texFraction factor
        nextState = deepCopy @animState
        nextState.matrix[rowNum] = (r * factor for r in nextState.matrix[rowNum])
        @htmlMatrix nextState.matrix, nextState.html

        flyer = document.getElementById @_id('multFlyer')
        flyer.style.opacity = 1
        # Put the flyer text to the right of the reference point
        flyer.parentElement.style.width = "0px"
        # Precomputations
        row = document.getElementsByClassName "#{@name}-row-#{rowNum}"
        pos = []
        past = []
        for elt in row
            box = elt.getBoundingClientRect()
            pos.push (box.left + box.right) / 2
            past.push false
        @doMultEffect =
            row:       row
            rowNum:    rowNum
            rowPos:    pos
            past:      past
            flyer:     flyer
            start:     @positions[0].clock.getTime().clock
            clock:     @positions[0].clock
            fadeIn:    0.3
            opacity:   (distance) => Math.min (distance/(@fontSize*2))**3, 1
            nextState: nextState

        pos1 = deepCopy @animState.positions
        pos1[@numRows][0] = [startX, rowY, 10]
        pos2 = deepCopy @animState.positions
        pos2[@numRows][0] = [-@matWidth*2, rowY, 10]
        @play @positions,
            delay: 0.3
            script:
                0: {props: {data: pos1}}
                1.75: {props: {data: pos2}}
        .on 'play.done', (e) => @newState nextState

    repEffect: () =>
        # Opacity effects for row replacement
        return unless @doRepEffect
        {start, clock, parenLeft, parenRight, row, flyer,
            opacity, nextState, targetRow} = @doRepEffect
        elapsed = clock.getTime().clock - start
        if elapsed < 0.3
            # First fade in the parentheses
            parenLeft.style.opacity = elapsed / 0.3
            parenRight.style.opacity = elapsed / 0.3
            return
        if elapsed < 1.5
            return
        elapsed -= 1.5
        if elapsed < 1.5
            # Decrease opacity of flyer and row as the former covers the latter
            right = row[@numCols-1].getBoundingClientRect().right
            for elt in flyer
                pos = elt.getBoundingClientRect().left
                elt.style.opacity = opacity(pos - right)
            left = parenLeft.getBoundingClientRect().left
            for elt in row
                pos = elt.getBoundingClientRect().right
                elt.style.opacity = opacity(left - pos)
            return
        elapsed -= 1.5
        if elapsed < 0.3
            for elt in flyer
                elt.style.opacity = 0.5 - elapsed/(2*0.3)
            for elt in row
                elt.style.opacity = 0.5 - elapsed/(2*0.3)
            parenLeft.style.opacity = 1 - elapsed/0.3
            parenRight.style.opacity = 1 - elapsed/0.3
            return
        elapsed -= 0.3
        if elapsed < 0.3
            for i in [0...@numCols]
                @animState.html[targetRow][i] = nextState.html[targetRow][i]
            for elt in row
                elt.style.opacity = elapsed/0.3
            return
        if !@doRepEffect.finished
            @onNextFrame 1, () => @newState nextState, 'post'
            @doRepEffect.finished = true

    rowRep: (sourceRow, factor, targetRow) ->
        # Set the text of rrepParenLeft, then run the rest in a couple of frames
        # when we can measure its width
        plus = if factor >= 0 then '+' else '-'
        @animState.html[@numRows+2][0] =
            @domEl @domClass, {
                className: 'rrep-factor ' + @_id('rrepFactor')
                id: @_id 'rrepParenLeft'},
                plus + texFraction(factor) + '\\times\\bigl('
        @animState.html[@numRows+3][0] =
            @domEl @domClass, {
                className: 'rrep-factor ' + @_id('rrepFactor')
                id: @_id 'rrepParenRight'}, '\\bigr)'

        nextState = deepCopy @animState
        for i in [0...@numCols]
            nextState.matrix[targetRow][i] += factor * nextState.matrix[sourceRow][i]
        @htmlMatrix nextState.matrix, nextState.html

        @onNextFrame 2, () =>
            # Initialize row replacement factor
            leftParen = document.getElementById(@_id 'rrepParenLeft')
            leftParenWidth = leftParen.getBoundingClientRect().width
            rowY = @animState.positions[targetRow][0][1]
            padding = 7
            matWidth = @matWidth + padding*2
            for elt in document.getElementsByClassName @_id('rrepFactor')
                # Put these to the right of the reference point
                elt.parentElement.style.width = "0px"
                elt.style.opacity = 0
            leftParenX = @matWidth/2 + @colSpacing + 10
            @animState.positions[@numRows+2][0][0] = leftParenX
            @animState.positions[@numRows+2][0][1] = rowY
            @animState.positions[@numRows+2][0][2] = 5
            @animState.positions[@numRows+3][0][0] =
                leftParenX + leftParenWidth + matWidth
            @animState.positions[@numRows+3][0][1] = rowY
            @animState.positions[@numRows+3][0][2] = 5

            # Initialize row flyer
            offsetX = @matWidth + @colSpacing + 10 + leftParenWidth + padding
            pos2 = deepCopy @animState.positions
            for i in [0...@numCols]
                @animState.html[@numRows+1][i] =
                    @domEl @domClass, {className: @_id 'addFlyer'},
                        @animState.html[sourceRow][i].children
                @animState.positions[@numRows+1][i] =
                    @animState.positions[sourceRow][i]
                pos2[@numRows+1][i][0] = @animState.positions[@numRows+1][i][0] + offsetX
                pos2[@numRows+1][i][1] = rowY
                pos2[@numRows+1][i][2] = 10

            pos3 = deepCopy pos2
            for i in [0...@numCols]
                pos3[@numRows+1][i][0] -= offsetX
            pos3[@numRows+2][0][0] -= offsetX
            pos3[@numRows+3][0][0] -= offsetX

            @play @positions,
                script:
                    0.0: {props: {data: @animState.positions}}
                    1.5: {props: {data: pos2}}
                    3.0: {props: {data: pos3}}

            addFlyer = document.getElementsByClassName(@_id 'addFlyer')
            elt.style.opacity = 1 for elt in addFlyer

            # Opacity effects
            @doRepEffect =
                start:      @positions[0].clock.getTime().clock
                clock:      @positions[0].clock
                parenLeft:  document.getElementById(@_id 'rrepParenLeft')
                parenRight: document.getElementById(@_id 'rrepParenRight')
                row:        document.getElementsByClassName("#{@name}-row-#{targetRow}")
                flyer:      addFlyer
                nextState:  nextState
                targetRow:  targetRow
                finished:   false
                opacity:    (right) =>
                    return 0.5 if right < 0
                    Math.max(0.5, Math.min (right/(@fontSize)), 1)

window.RRMatrix = RRMatrix
