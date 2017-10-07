# This file contains the code that runs rrinter.html

urlCallback = () ->
urlParams = {}

# This parses the query string every time it changes
window.onpopstate = () ->
    pl     = /\+/g
    search = /([^&=]+)=?([^&]*)/g
    decode = (s) -> decodeURIComponent(s.replace pl, " ")
    query  = window.location.search.substring 1

    urlParams = {}
    while match = search.exec query
        urlParams[decode match[1]] = decode match[2]
    urlCallback()
window.onpopstate()

# Evaluate a math expression; return 0 on error
evExpr = (expr) ->
    try return exprEval.Parser.evaluate expr
    catch
        0

# Parse a matrix out of a URL-encoded matrix
parseMatrix = (str) ->
    if not str
        return null
    inRows = str.split ':'
    maxRow = 0
    mat = []
    for inRow in inRows
        row = []
        entries = inRow.split ','
        for entry, j in entries
            row.push evExpr entry
            maxRow = Math.max maxRow, j+1
        mat.push row
    # Make sure the rows have the same size
    for row in mat
        row.push 0 for [row.length...maxRow]
    if mat.length == 0 or maxRow == 0
        return null
    mat

# Create a slide from a shortOp (from a URL)
parseSlide = (shortOp) ->
    type = shortOp[0]
    vals = shortOp.slice(1).split ':'
    parseFrac = (s) -> evExpr s.replace('.','/')
    if type == 's'
        row1 = parseInt vals[0]
        row2 = parseInt vals[1]
        return rrmat.rowSwap(row1, row2).chain
    if type == 'm'
        rowNum = parseInt vals[0]
        factor = parseFrac vals[1]
        return rrmat.rowMult(rowNum, factor).chain
    if type == 'r'
        sourceRow = parseInt vals[0]
        factor    = parseFrac vals[1]
        targetRow = parseInt vals[2]
        return rrmat.rowRep(sourceRow, factor, targetRow).chain

# Encode the matrix, slideshow, and current slide in a query string
encodeQS = () ->
    # Encode matrix
    mat = slideshow.states[0].matrix
    outRows = []
    for row in mat
        outRow = []
        for ent in row
            [num, den] = RRMatrix.approxFraction ent
            outRow.push num + if den != 1 then "%2F#{den}" else ""
        outRows.push outRow.join ','
    encMat = outRows.join ':'
    # Encode row ops
    encOps = (slide.data.shortOp for slide in slideshow.slides).join ','
    ret = "mat=#{encMat}&ops=#{encOps}&cur=#{slideshow.currentSlideNum}"
    if urlParams.augment
        ret += "&augment=" + urlParams.augment
    ret

# Update the matrix, slideshow, and current slide from a query string
updatingState = false
decodeQS = () ->
    # Changing the matrix on the fly is not supported
    mat = parseMatrix urlParams.mat

    # Current slide
    cur = parseInt urlParams.cur
    cur = 0 if isNaN cur

    # The tricky part is merging the row operations.  We start from the first
    # specified operation, and as long as it's the same as the first operation
    # in 'slideshow', then we do nothing.  Once it's different, we delete
    # everything in 'slideshow' from that point on, and start adding the
    # specified operations
    if urlParams.ops
        ops = urlParams.ops.split ','
    else
        ops = []
    state = slideshow.states[0]
    same = true
    # Prevent the goToSlide callback from adding a history entry
    updatingState = true
    for op, i in ops
        if same
            if i >= slideshow.slides.length or op != slideshow.slides[i].data.shortOp
                same = false
                clearAfter i
        if same
            slide = slideshow.slides[i]
        else
            slide = parseSlide op
            addSlide slide
        state = slide.transform state
        if not same
            addMatrixToHistory state.matrix, slide.data.texOp
    # ops is shorter than slideshow.slides
    if same and ops.length < slideshow.slides.length
        clearAfter ops.length
    slideshow.goToSlide cur
    updatingState = false
    updateRREF()

# Encode the matrix for the "enter new matrix" text area
matToTextarea = (mat) ->
    outRows = []
    for row in mat
        outRow = []
        for ent in row
            [num, den] = RRMatrix.approxFraction ent
            text = num.toString()
            if den != 1
                text += '/' + den.toString()
            outRow.push text
        outRows.push row.join ', '
    return outRows.join '\n'

# Render a matrix to an element, using katex
renderMatrix = (mat, elt) ->
    latex = '\\left[\\begin{array}'
    augment = parseInt(urlParams.augment)
    latex += '{'
    if isNaN(augment)
        latex += 'c' for i in [0...mat[0].length]
    else
        latex += 'c' for i in [0..augment]
        latex += '|'
        latex += 'c' for i in [augment...mat[0].length]
    latex += '}'
    outRows = []
    for row in mat
        outRow = []
        for ent in row
            outRow.push RRMatrix.texFraction ent
        outRows.push outRow.join '&'
    latex += outRows.join '\\\\'
    latex += '\\end{array}\\right]'
    katex.render latex, elt

# Add a matrix to the matrix history area
addMatrixToHistory = (mat, texOp) ->
    child = document.createElement 'div'
    historyElt.appendChild child
    renderMatrix mat, child
    if texOp
        arrow = document.createElement 'div'
        arrow.className = 'arrow'
        katex.render texOp, arrow
        child.insertBefore arrow, child.firstChild

# Remove the last matrix from the history area
popMatrixFromHistory = () ->
    historyElt.lastChild.remove()

# Get the row number selected by a row selector
selectorRow = (selector) ->
    for child, i in selector.children
        if child.classList.contains 'selected'
            return i
    return null

# Clear all slides and history entries after 'slideNum'
clearAfter = (slideNum) ->
    len = slideshow.slides.length
    for i in [slideNum...len]
        slideshow.removeSlide slideNum
        popMatrixFromHistory()

# This just adds a slide to the slideshow
addSlide = (slide) ->
    slides = [slide]
    if slide.data.type == 'rowRep'
        slides.push rrmat.highlightPivots()
    if rrmat.isRREF slide.transform slideshow.getState slideshow.slides.length
        slide.on 'done', updateRREF
        # Make a fun animation
        blink = (col, delay) ->
            bigger =
                transform: "scale(2,2)"
                entries:   ([i, col] for i in [0...rrmat.numRows])
                duration:  0.4
                delay:     delay
                timing:    'linear'
            smaller =
                transform: ""
                entries:   ([i, col] for i in [0...rrmat.numRows])
                duration:  0.4
                delay:     delay + 0.4
                timing:    'linear'
            [bigger, smaller]
        shake = (delay) ->
            entries = [].concat.apply [],
                ([i,j] for i in [0...rrmat.numRows] for j in [0...rrmat.numCols])
            left =
                transform: "rotate(-20deg)"
                entries:   entries
                duration:  .1
                delay:     delay
                timing:    'linear'
            right =
                transform: "rotate(20deg)"
                entries:   entries
                duration:  .2
                delay:     delay + .1
                timing:    'linear'
            center =
                transform: ""
                entries:   entries
                duration:  .1
                delay:     delay + .3
                timing:    'linear'
            [left, right, center]
        anim = [].concat.apply [],
            (blink col, col * 0.2 for col in [0...rrmat.numCols])
        anim = anim.concat.apply anim,
            (blink col, (rrmat.numCols - col - 1) * 0.2 + rrmat.numCols * 0.4 - 0.2 \
             for col in [rrmat.numCols-1..0])
        anim = anim.concat.apply anim,
            (shake i*.4 + rrmat.numCols * 0.8 - 0.2 for i in [0...5])
        slides.push rrmat.setStyle anim
    slideshow.addSlide s for s in slides
    slideshow.break()

# This is called when a new slide is created by the UI
newSlide = (slide) ->
    slideshow.nextSlide() if slideshow.playing
    clearAfter slideshow.currentSlideNum
    addSlide slide
    slideshow.nextSlide()

# Add or remove the autodetected row echelon form box
updateRREF = () ->
    if rrmat.isRREF()
        refDiv.classList.add 'inactive'
        rrefDiv.classList.remove 'inactive'
    else if rrmat.isREF()
        rrefDiv.classList.add 'inactive'
        refDiv.classList.remove 'inactive'
    else
        rrefDiv.classList.add 'inactive'
        refDiv.classList.add 'inactive'

# This is called when the slideshow changes slides
onSlideChange = () ->
    # Don't push a history entry after the history entry was just changed
    return if updatingState
    updateRREF()
    history.pushState {}, pageTitle, '?' + encodeQS()
    current = slideshow.currentSlideNum
    matrices = historyElt.children.length
    if current >= matrices
        # Need to add matrix history
        for i in [matrices..current]
            addMatrixToHistory slideshow.states[i].matrix,
                slideshow.slides[i-1].data.texOp

# UI elements are global to this module
historyElt = null
pageTitle  = null
historyElt = null
swapBtn    = null
multBtn    = null
rrepBtn    = null
swapRow1   = null
swapRow2   = null
multRow    = null
multFactor = null
rrepFactor = null
rrepRow1   = null
rrepRow2   = null
newMatBtn  = null
newMatDiv  = null
newMatrix  = null
useMatBtn  = null
refDiv     = null
rrefDiv    = null
selectors  = null

# Install everything after the DOM is ready
install = () ->
    # The base matrix
    startMatrix = parseMatrix urlParams.mat
    # Find UI elements
    pageTitle  = document.querySelector('title').innerText
    historyElt = document.querySelector 'div.history'
    swapBtn    = document.querySelector '.ops-label.row-swap button'
    multBtn    = document.querySelector '.ops-label.row-mult button'
    rrepBtn    = document.querySelector '.ops-label.row-rrep button'
    [swapRow1, swapRow2] \
               = document.querySelectorAll '.ops-control.row-swap .row-selector'
    multRow    = document.querySelector '.ops-control.row-mult .row-selector'
    multFactor = document.querySelector '.ops-control.row-mult input'
    rrepFactor = document.querySelector '.ops-control.row-rrep input'
    [rrepRow1, rrepRow2] \
               = document.querySelectorAll '.ops-control.row-rrep .row-selector'
    newMatBtn  = document.querySelector '.newmat-button button'
    newMatDiv  = document.querySelector 'div.newmat'
    newMatrix  = document.querySelector '.newmat textarea'
    useMatBtn  = document.querySelector '.newmat div > button'
    refDiv     = document.querySelector '.row-ref'
    rrefDiv    = document.querySelector '.row-rref'
    selectors  = document.querySelectorAll '.slideshow .row-selector'

    # Reload the page with a new matrix
    useMatBtn.onclick = () ->
        val = newMatrix.value
            .replace(/\n/g, ":")
            .replace(/\s/g, "")
            .replace(/:+$/, "")
        val = encodeURIComponent(val).replace /%(?:2C|3A)/g, unescape
        window.location.href = "?mat=" + val

    if not startMatrix
        newMatDiv.classList.add 'active'
        document.getElementById("rrmat-ui").style.display = 'none'
        document.getElementById("mathbox").style.display = 'none'
        return

    # Add and attach row selector buttons
    for selector in selectors
        # This function enables mutually exclusive selection
        select = do (selector) -> (ev) ->
            for child in selector.children
                if child == ev.target
                    child.classList.add 'selected'
                else
                    child.classList.remove 'selected'
        # Create selection buttons
        for j in [1..startMatrix.length]
            elt = document.createElement 'button'
            elt.className = 'row-button'
            elt.innerText = j.toString()
            elt.onclick = select
            selector.appendChild elt

    # Attach UI elements
    newMatrix.value = matToTextarea startMatrix

    # Do a row swap
    swapBtn.onclick = () ->
        row1 = selectorRow swapRow1
        row2 = selectorRow swapRow2
        return if !row1? or !row2? or row1 == row2
        newSlide rrmat.rowSwap(row1, row2).chain

    # Do a row multiplication
    multBtn.onclick = () ->
        row = selectorRow multRow
        factor = evExpr multFactor.value
        return if !row? or isNaN(factor) or factor == 0
        newSlide rrmat.rowMult(row, factor).chain

    # Do a row replacement
    rrepBtn.onclick = () ->
        row1 = selectorRow rrepRow1
        row2 = selectorRow rrepRow2
        factor = evExpr rrepFactor.value
        return if !row1? or !row2? or row1 == row2 or isNaN(factor)
        newSlide rrmat.rowRep(row1, factor, row2).chain

    # Toggle 'enter new matrix' area
    newMatBtn.onclick = () ->
        if newMatDiv.classList.contains 'active'
            newMatDiv.classList.remove 'active'
        else
            newMatDiv.classList.add 'active'

    # Add initial matrix
    addMatrixToHistory startMatrix
    startMatrix

finalize = () ->
    # Update the URI and the state of the matrix history when
    # navigating slides.
    slideshow.on 'slide.new', onSlideChange
    urlCallback = decodeQS
    decodeQS()

window.RRInter = {}
window.RRInter.install = install
window.RRInter.finalize = finalize
window.RRInter.urlParams = urlParams
