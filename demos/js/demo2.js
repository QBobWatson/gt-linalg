(function() {
  "use strict";
  var Caption, ClipCube, Demo, Draggable, LabeledVectors, View, clipFragment, clipShader, extend,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

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

  Draggable = (function() {
    function Draggable(view1, opts1) {
      var getMatrix, hiliteColor, hiliteOpts, i, indices, name, ref, ref1, ref2, ref3, ref4, ref5, ref6, rtt, size;
      this.view = view1;
      this.opts = opts1;
      this.getIndexAt = bind(this.getIndexAt, this);
      this.post = bind(this.post, this);
      this.onMouseUp = bind(this.onMouseUp, this);
      this.onMouseMove = bind(this.onMouseMove, this);
      this.onMouseDown = bind(this.onMouseDown, this);
      if (this.opts == null) {
        this.opts = {};
      }
      name = (ref = this.opts.name) != null ? ref : "draggable";
      this.points = this.opts.points;
      size = (ref1 = this.opts.size) != null ? ref1 : 30;
      this.onDrag = (ref2 = this.opts.onDrag) != null ? ref2 : function() {};
      hiliteColor = (ref3 = this.opts.hiliteColor) != null ? ref3 : [0, .5, .5, .75];
      this.eyeMatrix = (ref4 = this.opts.eyeMatrix) != null ? ref4 : new THREE.Matrix4();
      getMatrix = (ref5 = this.opts.getMatrix) != null ? ref5 : function(d) {
        return d.view[0].controller.viewMatrix;
      };
      hiliteOpts = {
        id: name + "-hilite",
        color: "white",
        points: "#" + name + "-points",
        colors: "#" + name + "-colors",
        size: size,
        zIndex: 2,
        zTest: false,
        zWrite: false
      };
      extend(hiliteOpts, (ref6 = this.opts.hiliteOpts) != null ? ref6 : {});
      this.three = this.view._context.api.three;
      this.canvas = this.three.canvas;
      this.camera = this.view._context.api.select("camera")[0].controller.camera;
      this.hovered = -1;
      this.dragging = -1;
      this.mouse = [-1, -1];
      this.activePoint = void 0;
      this.projected = new THREE.Vector3();
      this.vector = new THREE.Vector3();
      this.matrix = new THREE.Matrix4();
      this.matrixInv = new THREE.Matrix4();
      this.scale = 1 / 4;
      this.viewMatrix = getMatrix(this);
      this.viewMatrixInv = new THREE.Matrix4().getInverse(this.viewMatrix);
      this.viewMatrixTrans = this.viewMatrix.clone().transpose();
      this.eyeMatrixTrans = this.eyeMatrix.clone().transpose();
      this.eyeMatrixInv = new THREE.Matrix4().getInverse(this.eyeMatrix);
      indices = (function() {
        var k, ref7, results;
        results = [];
        for (i = k = 0, ref7 = this.points.length; 0 <= ref7 ? k < ref7 : k > ref7; i = 0 <= ref7 ? ++k : --k) {
          results.push([(i + 1) / 255, 1.0, 0, 0]);
        }
        return results;
      }).call(this);
      this.view.array({
        id: name + "-points",
        channels: 3,
        width: this.points.length,
        data: this.points
      }).array({
        id: name + "-index",
        channels: 4,
        width: this.points.length,
        data: indices,
        live: false
      });
      rtt = this.view.rtt({
        id: name + "-rtt",
        size: 'relative',
        width: this.scale,
        height: this.scale
      });
      rtt.transform({
        pass: 'eye',
        matrix: Array.prototype.slice.call(this.eyeMatrixTrans.elements)
      }).transform({
        matrix: Array.prototype.slice.call(this.viewMatrixTrans.elements)
      }).point({
        points: "#" + name + "-points",
        colors: "#" + name + "-index",
        color: 'white',
        size: size,
        blending: 'no'
      }).end();
      this.view.array({
        id: name + "-colors",
        channels: 4,
        width: this.points.length,
        expr: (function(_this) {
          return function(emit, i, t) {
            if (_this.dragging === i || _this.hovered === i) {
              return emit.apply(null, hiliteColor);
            } else {
              return emit(1, 1, 1, 0);
            }
          };
        })(this)
      }).point(hiliteOpts);
      this.readback = this.view.readback({
        source: "#" + name + "-rtt",
        type: 'unsignedByte'
      });
      this.canvas.addEventListener('mousedown', this.onMouseDown, false);
      this.canvas.addEventListener('mousemove', this.onMouseMove, false);
      this.canvas.addEventListener('mouseup', this.onMouseUp, false);
      this.three.on('post', this.post);
    }

    Draggable.prototype.onMouseDown = function(event) {
      if (this.hovered < 0) {
        return;
      }
      event.preventDefault();
      this.dragging = this.hovered;
      return this.activePoint = this.points[this.dragging];
    };

    Draggable.prototype.onMouseMove = function(event) {
      var mouseX, mouseY;
      this.mouse = [event.offsetX * window.devicePixelRatio, event.offsetY * window.devicePixelRatio];
      this.hovered = this.getIndexAt(this.mouse[0], this.mouse[1]);
      if (this.dragging < 0) {
        return;
      }
      event.preventDefault();
      mouseX = event.offsetX / this.canvas.offsetWidth * 2 - 1.0;
      mouseY = -(event.offsetY / this.canvas.offsetHeight * 2 - 1.0);
      this.projected.set(this.activePoint[0], this.activePoint[1], this.activePoint[2]).applyMatrix4(this.viewMatrix);
      this.matrix.multiplyMatrices(this.camera.projectionMatrix, this.eyeMatrix);
      this.matrix.multiply(this.matrixInv.getInverse(this.camera.matrixWorld));
      this.projected.applyProjection(this.matrix);
      this.vector.set(mouseX, mouseY, this.projected.z);
      this.vector.applyProjection(this.matrixInv.getInverse(this.matrix));
      this.vector.applyMatrix4(this.viewMatrixInv);
      this.onDrag.call(this, this.vector);
      this.activePoint[0] = this.vector.x;
      this.activePoint[1] = this.vector.y;
      return this.activePoint[2] = this.vector.z;
    };

    Draggable.prototype.onMouseUp = function(event) {
      if (this.dragging < 0) {
        return;
      }
      event.preventDefault();
      this.dragging = -1;
      return this.activePoint = void 0;
    };

    Draggable.prototype.post = function() {
      if (this.dragging >= 0) {
        this.canvas.style.cursor = 'pointer';
      } else if (this.hovered >= 0) {
        this.canvas.style.cursor = 'pointer';
      } else if (this.three.controls) {
        this.canvas.style.cursor = 'move';
      } else {
        this.canvas.style.cursor = '';
      }
      if (this.three.controls) {
        return this.three.controls.enabled = this.hovered < 0 && this.dragging < 0;
      }
    };

    Draggable.prototype.getIndexAt = function(x, y) {
      var a, data, h, o, r, w;
      data = this.readback.get('data');
      if (!data) {
        return -1;
      }
      x = Math.floor(x * this.scale);
      y = Math.floor(y * this.scale);
      w = this.readback.get('width');
      h = this.readback.get('height');
      o = (x + w * (h - y - 1)) * 4;
      r = data[o];
      a = data[o + 3];
      if (r != null) {
        if (a === 0) {
          return r - 1;
        } else {
          return -1;
        }
      } else {
        return -1;
      }
    };

    return Draggable;

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

  LabeledVectors = (function() {
    function LabeledVectors(view, opts1) {
      var colors, doZero, i, k, labelOpts, labels, name, origins, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, vectorData, vectorOpts, vectors, zeroData, zeroOpts, zeroThreshold;
      this.opts = opts1;
      if (this.opts == null) {
        this.opts = {};
      }
      name = (ref = this.opts.name) != null ? ref : "labeled";
      vectors = this.opts.vectors;
      colors = this.opts.colors;
      labels = this.opts.labels;
      origins = (ref1 = this.opts.origins) != null ? ref1 : (function() {
        var k, ref2, results;
        results = [];
        for (k = 0, ref2 = vectors.length; 0 <= ref2 ? k < ref2 : k > ref2; 0 <= ref2 ? k++ : k--) {
          results.push([0, 0, 0]);
        }
        return results;
      })();
      vectorOpts = {
        id: name + "-vectors-drawn",
        points: "#" + name + "-vectors",
        colors: "#" + name + "-colors",
        color: "white",
        end: true,
        size: 5,
        width: 5
      };
      extend(vectorOpts, (ref2 = this.opts.vectorOpts) != null ? ref2 : {});
      labelOpts = {
        id: name + "-vector-labels",
        colors: "#" + name + "-colors",
        color: "white",
        outline: 2,
        background: "black",
        size: 15,
        offset: [0, 25]
      };
      extend(labelOpts, (ref3 = this.opts.labelOpts) != null ? ref3 : {});
      doZero = (ref4 = this.opts.zeroPoints) != null ? ref4 : false;
      zeroOpts = {
        id: name + "-zero-points",
        points: "#" + name + "-zeros",
        colors: "#" + name + "-zero-colors",
        color: "white",
        size: 20,
        visible: false
      };
      extend(zeroOpts, (ref5 = this.opts.zeroOpts) != null ? ref5 : {});
      zeroThreshold = (ref6 = this.opts.zeroThreshold) != null ? ref6 : 0.0;
      vectorData = [];
      for (i = k = 0, ref7 = vectors.length; 0 <= ref7 ? k < ref7 : k > ref7; i = 0 <= ref7 ? ++k : --k) {
        vectorData.push(origins[i]);
        vectorData.push(vectors[i]);
      }
      view.array({
        id: name + "-vectors",
        channels: 3,
        width: vectors.length,
        items: 2,
        data: vectorData
      }).array({
        id: name + "-colors",
        channels: 4,
        width: colors.length,
        data: colors
      }).vector(vectorOpts);
      if (labels != null) {
        view.array({
          channels: 3,
          width: vectors.length,
          expr: function(emit, i) {
            return emit((vectors[i][0] + origins[i][0]) / 2, (vectors[i][1] + origins[i][1]) / 2, (vectors[i][2] + origins[i][2]) / 2);
          }
        }).text({
          id: name + "-text",
          live: false,
          width: labels.length,
          data: labels
        }).label(labelOpts);
      }
      if (doZero) {
        zeroData = (function() {
          var l, ref8, results;
          results = [];
          for (l = 0, ref8 = vectors.length; 0 <= ref8 ? l < ref8 : l > ref8; 0 <= ref8 ? l++ : l--) {
            results.push([0, 0, 0]);
          }
          return results;
        })();
        view.array({
          id: name + "-zero-colors",
          channels: 4,
          width: vectors.length,
          expr: function(emit, i) {
            if (Math.abs(vectors[i][0]) < zeroThreshold && Math.abs(vectors[i][1]) < zeroThreshold && Math.abs(vectors[i][2]) < zeroThreshold) {
              return emit.apply(null, colors[i]);
            } else {
              return emit(0, 0, 0, 0);
            }
          }
        }).array({
          id: name + "-zeros",
          channels: 3,
          width: vectors.length,
          data: zeroData
        });
        this.zeroPoints = view.point(zeroOpts);
      }
    }

    return LabeledVectors;

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

    Demo.prototype.texVector = function(x, y, z, opts) {
      var precision, ref, ret;
      if (opts == null) {
        opts = {};
      }
      precision = (ref = opts.precision) != null ? ref : 2;
      ret = '';
      if (opts.color != null) {
        ret += "\\color{" + opts.color + "}{";
      }
      ret += "\\begin{bmatrix}\n    " + (x.toFixed(precision)) + " \\\\\n    " + (y.toFixed(precision)) + " \\\\\n    " + (z.toFixed(precision)) + "\n\\end{bmatrix}";
      if (opts.color != null) {
        ret += "}";
      }
      return ret;
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

    Demo.prototype.draggable = function(view, opts) {
      return new Draggable(view, opts);
    };

    Demo.prototype.labeledVectors = function(view, opts) {
      return new LabeledVectors(view, opts);
    };

    return Demo;

  })();

  window.Demo = Demo;

}).call(this);
