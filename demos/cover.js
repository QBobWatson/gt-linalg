(function() {
  var controller, doCover, dynView, installDOM, makeControls, ortho, pickType, randElt, reset, select, setupMathbox, t, types, typesList;

  types = [["all", null], ["ellipse", dynamics.Circle], ["spiral in", dynamics.SpiralIn], ["spiral out", dynamics.SpiralOut], ["hyperbolas", dynamics.Hyperbolas], ["attract point", dynamics.Attract], ["repel point", dynamics.Repel], ["attract line", dynamics.AttractLine], ["repel line", dynamics.RepelLine], ["shear", dynamics.Shear], ["scale out shear", dynamics.ScaleOutShear], ["scale in shear", dynamics.ScaleInShear]];

  typesList = (function() {
    var i, len, ref, results;
    ref = types.slice(1);
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      t = ref[i];
      results.push(t[1]);
    }
    return results;
  })();

  select = null;

  controller = null;

  dynView = null;

  ortho = 1e5;

  setupMathbox = function() {
    var mathbox, three;
    three = THREE.Bootstrap({
      plugins: ['core'],
      mathbox: {
        inspect: false,
        splash: false
      },
      camera: {
        near: ortho / 4,
        far: ortho * 4
      },
      element: document.getElementById("mathbox")
    });
    if (!three.fallback) {
      if (!three.Time) {
        three.install('time');
      }
      if (!three.MathBox) {
        three.install(['mathbox']);
      }
    }
    mathbox = window.mathbox = three.mathbox;
    if (mathbox.fallback) {
      throw "WebGL not supported";
    }
    three.renderer.setClearColor(new THREE.Color(0xffffff), 1.0);
    mathbox.camera({
      proxy: false,
      position: [0, 0, ortho],
      lookAt: [0, 0, 0],
      up: [1, 0, 0],
      fov: Math.atan(1 / ortho) * 360 / π
    });
    mathbox.set('focus', ortho / 1.5);
    return mathbox;
  };

  randElt = function(l) {
    return l[Math.floor(Math.random() * l.length)];
  };

  pickType = function() {
    var type;
    if (select) {
      type = types.filter(function(x) {
        return x[0] === select.value;
      })[0][1];
    }
    if (!type) {
      type = randElt(typesList);
    }
    return type;
  };

  makeControls = function(elt) {
    var button, div, i, key, len, option, ref, val;
    div = document.createElement("div");
    div.id = "cover-controls";
    button = document.createElement("button");
    button.innerText = "Go";
    button.onclick = reset;
    select = document.createElement("select");
    for (i = 0, len = types.length; i < len; i++) {
      ref = types[i], key = ref[0], val = ref[1];
      option = document.createElement("option");
      option.innerText = key;
      select.appendChild(option);
    }
    div.appendChild(select);
    div.appendChild(button);
    return elt.appendChild(div);
  };

  installDOM = function(elt) {
    var content, div, div2, main;
    div = document.createElement("div");
    div.id = "mathbox-container";
    div2 = document.createElement("div");
    div2.id = "mathbox";
    div.appendChild(div2);
    elt.appendChild(div);
    main = document.getElementsByClassName("main")[0];
    if (main) {
      elt.style.width = main.clientWidth + "px";
      content = document.getElementById("content");
      elt.style.marginLeft = "-" + getComputedStyle(content, null).marginLeft;
    }
    return makeControls(elt);
  };

  reset = function() {
    dynView.randomizeCoords();
    controller.loadDynamics(pickType());
    return dynView.updateView();
  };

  doCover = function() {
    var element, mathbox, view;
    element = document.getElementById("cover");
    if (element) {
      installDOM(element);
    }
    mathbox = setupMathbox();
    view = mathbox.cartesian({
      range: [[-1, 1], [-1, 1], [-1, 1]],
      scale: [1, 1, 1]
    });
    controller = new dynamics.Controller();
    dynView = new dynamics.DynamicsView({
      refColor: [0.2157, 0.4941, 0.7216]
    });
    dynView.randomizeCoords();
    controller.addView(dynView);
    controller.loadDynamics(pickType());
    dynView.updateView(mathbox, view);
    return controller.start();
  };

  DomReady.ready(doCover);

}).call(this);
