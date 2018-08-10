
types = [
    ["all",             null],
    ["ellipse",         dynamics.Circle],
    ["spiral in",       dynamics.SpiralIn],
    ["spiral out",      dynamics.SpiralOut]
    ["hyperbolas",      dynamics.Hyperbolas]
    ["attract point",   dynamics.Attract]
    ["repel point",     dynamics.Repel]
    ["attract line",    dynamics.AttractLine]
    ["repel line",      dynamics.RepelLine]
    ["shear",           dynamics.Shear]
    ["scale out shear", dynamics.ScaleOutShear]
    ["scale in shear",  dynamics.ScaleInShear]
]
typesList = (t[1] for t in types.slice(1))
select = null
controller = null
dynView = null

ortho = 1e5

setupMathbox = () ->
    three = THREE.Bootstrap
        plugins: ['core']
        mathbox:
            inspect: false
            splash: false
        camera:
            near:    ortho/4
            far:     ortho*4
        element: document.getElementById "mathbox"
    if !three.fallback
      three.install 'time'      if !three.Time
      # Get rid of splash scree
      three.install ['mathbox'] if !three.MathBox
    mathbox = window.mathbox = three.mathbox
    if mathbox.fallback
        throw "WebGL not supported"

    three.renderer.setClearColor new THREE.Color(0xffffff), 1.0
    mathbox.camera
        proxy:    false
        position: [0, 0, ortho]
        lookAt:   [0, 0, 0]
        up:       [1, 0, 0]
        fov:      Math.atan(1/ortho) * 360 / π
    mathbox.set 'focus', ortho/1.5
    mathbox

randElt = (l) -> l[Math.floor(Math.random() * l.length)]

pickType = () ->
    if select
        type = types.filter((x) -> x[0] == select.value)[0][1]
    unless type
        type = randElt typesList
        #type = Shear
    type

makeControls = (elt) ->
    div = document.createElement "div"
    div.id = "cover-controls"
    button = document.createElement "button"
    button.innerText = "Go"
    button.onclick = reset
    select = document.createElement "select"
    for [key, val] in types
        option = document.createElement "option"
        option.innerText = key
        select.appendChild option
    div.appendChild select
    div.appendChild button
    elt.appendChild div

installDOM = (elt) ->
    # Create containers
    div = document.createElement "div"
    div.id = "mathbox-container"
    div2 = document.createElement "div"
    div2.id = "mathbox"
    div.appendChild div2
    elt.appendChild div
    # Adjust width
    main = document.getElementsByClassName("main")[0]
    if main
        elt.style.width = main.clientWidth + "px"
        content = document.getElementById "content"
        elt.style.marginLeft = "-" + getComputedStyle(content, null).marginLeft
    # Add controls
    makeControls elt

reset = () ->
    dynView.randomizeCoords()
    controller.loadDynamics pickType()
    dynView.updateView()

doCover = () ->
    element = document.getElementById "cover"
    if element
        installDOM element

    mathbox = setupMathbox()
    view = mathbox.cartesian
        range: [[-1,1],[-1,1],[-1,1]]
        scale: [1,1,1]

    controller = new dynamics.Controller()
    dynView = new dynamics.DynamicsView
        refColor: [0.2157, 0.4941, 0.7216]
    dynView.randomizeCoords()
    controller.addView dynView
    controller.loadDynamics pickType()
    dynView.updateView mathbox, view
    controller.start()

DomReady.ready doCover

