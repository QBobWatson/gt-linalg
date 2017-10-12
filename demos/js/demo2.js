(function() {
  "use strict";
  var Caption, ClipCube, Demo, View, clipFragment, clipShader, extend;

  extend = function(obj, src) {
    var key, results, val;
    results = [];
    for (key in src) {
      val = src[key];
      if (src.hasOwnProperty(key)) {
        results.push(obj[key] = val);
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  clipShader = "// Enable STPQ mapping\n#define POSITION_STPQ\nvoid getPosition(inout vec4 xyzw, inout vec4 stpq) {\n  // Store XYZ per vertex in STPQ\nstpq = xyzw;\n}";

  clipFragment = "// Enable STPQ mapping\n#define POSITION_STPQ\nuniform float range;\nuniform int hilite;\n\nvec4 getColor(vec4 rgba, inout vec4 stpq) {\n    stpq = abs(stpq);\n\n    // Discard pixels outside of clip box\n    if(stpq.x > range || stpq.y > range || stpq.z > range)\n        discard;\n\n    if(hilite != 0 &&\n       (range - stpq.x < range * 0.002 ||\n        range - stpq.y < range * 0.002 ||\n        range - stpq.z < range * 0.002)) {\n        rgba.xyz *= 10.0;\n        rgba.w = 1.0;\n    }\n\n    return rgba;\n}";

  Caption = (function() {
    function Caption(mathbox, text) {
      this.mathbox = mathbox;
      this.div = this.mathbox._context.overlays.div;
      this.label = document.createElement('div');
      this.label.className = "overlay-text";
      this.label.innerHTML = text;
      this.div.appendChild(this.label);
    }

    return Caption;

  })();

  View = (function() {
    function View(mathbox, opts1) {
      var axisOpts, doAxes, doAxisLabels, doGrid, gridOpts, i, k, labelOpts, ref, ref1, ref10, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, viewOpts, viewRange, viewScale;
      this.mathbox = mathbox;
      this.opts = opts1;
      if (this.opts == null) {
        this.opts = {};
      }
      this.name = (ref = this.opts.name) != null ? ref : "view";
      viewRange = (ref1 = this.opts.viewRange) != null ? ref1 : [[-10, 10], [-10, 10], [-10, 10]];
      this.numDims = viewRange.length;
      viewScale = (ref2 = this.opts.viewScale) != null ? ref2 : [1, 1, 1];
      doAxes = (ref3 = this.opts.axes) != null ? ref3 : true;
      axisOpts = {
        classes: [this.name + "-axes"],
        end: true,
        width: 3,
        depth: 1,
        color: "white",
        opacity: 0.75,
        zBias: -1,
        size: 5
      };
      extend(axisOpts, (ref4 = this.opts.axisOpts) != null ? ref4 : {});
      doGrid = (ref5 = this.opts.grid) != null ? ref5 : true;
      gridOpts = {
        classes: [this.name + "-axes", this.name + "-grid"],
        axes: [1, 2],
        width: 2,
        depth: 1,
        color: "white",
        opacity: 0.5,
        zBias: 0
      };
      extend(gridOpts, (ref6 = this.opts.gridOpts) != null ? ref6 : {});
      doAxisLabels = ((ref7 = this.opts.axisLabels) != null ? ref7 : true) && doAxes;
      labelOpts = {
        classes: [this.name + "-axes"],
        size: 20,
        color: "white",
        opacity: 1,
        outline: 2,
        background: "black",
        offset: [0, 0]
      };
      extend(labelOpts, (ref8 = this.opts.labelOpts) != null ? ref8 : {});
      viewScale[0] = -viewScale[0];
      viewOpts = {
        range: viewRange,
        scale: viewScale,
        rotation: [-π / 2, 0, 0],
        id: this.name + "-view"
      };
      extend(viewOpts, (ref9 = this.opts.viewOpts) != null ? ref9 : {});
      this.view = this.mathbox.cartesian(viewOpts);
      if (doAxes) {
        for (i = k = 1, ref10 = this.numDims; 1 <= ref10 ? k <= ref10 : k >= ref10; i = 1 <= ref10 ? ++k : --k) {
          axisOpts.axis = i;
          this.view.axis(axisOpts);
        }
      }
      if (doGrid) {
        this.view.grid(gridOpts);
      }
      if (doAxisLabels) {
        this.view.array({
          channels: this.numDims,
          width: this.numDims,
          live: false,
          expr: (function(_this) {
            return function(emit, i) {
              var arr, j, l, ref11;
              arr = [];
              for (j = l = 0, ref11 = _this.numDims; 0 <= ref11 ? l < ref11 : l > ref11; j = 0 <= ref11 ? ++l : --l) {
                if (i === j) {
                  arr.push(viewRange[i][1] * 1.04);
                } else {
                  arr.push(0);
                }
              }
              return emit.apply(null, arr);
            };
          })(this)
        }).text({
          live: false,
          width: this.numDims,
          data: ['x', 'y', 'z'].slice(0, this.numDims)
        }).label(labelOpts);
      }
    }

    return View;

  })();

  ClipCube = (function() {
    function ClipCube(view1, opts1) {
      var color, draw, hilite, material, pass, range, ref, ref1, ref2, ref3, ref4, ref5;
      this.view = view1;
      this.opts = opts1;
      if (this.opts == null) {
        this.opts = {};
      }
      range = (ref = this.opts.range) != null ? ref : 1.0;
      pass = (ref1 = this.opts.pass) != null ? ref1 : "world";
      hilite = (ref2 = this.opts.hilite) != null ? ref2 : true;
      draw = (ref3 = this.opts.draw) != null ? ref3 : false;
      if (draw) {
        material = (ref4 = this.opts.material) != null ? ref4 : new THREE.MeshBasicMaterial();
        color = (ref5 = this.opts.color) != null ? ref5 : new THREE.Color(1, 1, 1);
        this.clipCubeMesh = (function(_this) {
          return function() {
            var cube, geo, mesh;
            geo = new THREE.BoxGeometry(2, 2, 2);
            mesh = new THREE.Mesh(geo, material);
            cube = new THREE.BoxHelper(mesh);
            cube.material.color = color;
            _this.view._context.api.three.scene.add(cube);
            return mesh;
          };
        })(this)();
      }
      this.clipped = this.view.shader({
        code: clipShader
      }).vertex({
        pass: pass
      }).shader({
        code: clipFragment,
        uniforms: {
          range: {
            type: 'f',
            value: range
          },
          hilite: {
            type: 'i',
            value: hilite ? 1 : 0
          }
        }
      }).fragment();
    }

    return ClipCube;

  })();

  Demo = (function() {
    function Demo(opts1, callback) {
      var cameraOpts, clearColor, clearOpacity, doFullScreen, focusDist, image, key, mathboxOpts, onPreloaded, p, preload, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, scaleUI, toPreload, value;
      this.opts = opts1;
      if (this.opts == null) {
        this.opts = {};
      }
      mathboxOpts = {
        plugins: ['core', 'controls', 'cursor'],
        controls: {
          klass: THREE.OrbitControls,
          parameters: {
            noKeys: true
          }
        },
        mathbox: {
          inspect: false
        },
        splash: {
          fancy: true,
          color: "blue"
        }
      };
      extend(mathboxOpts, (ref = this.opts.mathbox) != null ? ref : {});
      clearColor = (ref1 = this.opts.clearColor) != null ? ref1 : 0x000000;
      clearOpacity = (ref2 = this.opts.clearOpacity) != null ? ref2 : 1.0;
      cameraOpts = {
        proxy: true,
        position: [3, 1.5, 1.5],
        lookAt: [0, 0, 0]
      };
      extend(cameraOpts, (ref3 = this.opts.camera) != null ? ref3 : {});
      p = cameraOpts.position;
      cameraOpts.position = [-p[0], p[2], -p[1]];
      focusDist = (ref4 = this.opts.focusDist) != null ? ref4 : 1.5;
      scaleUI = (ref5 = this.opts.scaleUI) != null ? ref5 : true;
      doFullScreen = (ref6 = this.opts.fullscreen) != null ? ref6 : true;
      onPreloaded = (function(_this) {
        return function() {
          _this.mathbox = mathBox(mathboxOpts);
          _this.three = _this.mathbox.three;
          _this.three.renderer.setClearColor(new THREE.Color(clearColor), clearOpacity);
          _this.camera = _this.mathbox.camera(cameraOpts)[0].controller.camera;
          _this.canvas = _this.mathbox._context.canvas;
          if (scaleUI) {
            _this.mathbox.bind('focus', function() {
              return focusDist / 1000 * Math.min(_this.canvas.clientWidth, _this.canvas.clientHeight);
            });
          }
          if (doFullScreen) {
            document.body.addEventListener('keypress', function(event) {
              if (event.charCode === 'f'.charCodeAt(0 && screenfull.enabled)) {
                return screenfull.toggle();
              }
            });
          }
          return callback.apply(_this);
        };
      })(this);
      this.decodeQS();
      preload = (ref7 = this.opts.preload) != null ? ref7 : {};
      toPreload = 0;
      if (preload) {
        for (key in preload) {
          value = preload[key];
          toPreload++;
          image = new Image();
          this[key] = image;
          image.src = value;
          image.addEventListener('load', function() {
            if (--toPreload === 0) {
              return onPreloaded();
            }
          });
        }
      }
      if (!(toPreload > 0)) {
        onPreloaded();
      }
    }

    Demo.prototype.decodeQS = function() {
      var decode, match, pl, query, search;
      pl = /\+/g;
      search = /([^&=]+)=?([^&]*)/g;
      decode = function(s) {
        return decodeURIComponent(s.replace(pl, " "));
      };
      query = window.location.search.substring(1);
      this.urlParams = {};
      while (match = search.exec(query)) {
        this.urlParams[decode(match[1])] = decode(match[2]);
      }
      return this.urlParams;
    };

    Demo.prototype.view = function(opts) {
      return new View(this.mathbox, opts).view;
    };

    Demo.prototype.caption = function(text) {
      return new Caption(this.mathbox, text);
    };

    Demo.prototype.clipCube = function(view, opts) {
      return new ClipCube(view, opts);
    };

    return Demo;

  })();

  window.Demo = Demo;

}).call(this);
