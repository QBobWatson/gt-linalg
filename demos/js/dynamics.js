(function() {
  var Attract, AttractLine, AttractRepel, AttractRepelLine, Circle, Complex, Controller, Diagonalizable, Dynamics, DynamicsView, HSVtoRGB, Hyperbolas, Repel, RepelLine, ScaleInOutShear, ScaleInShear, ScaleOutShear, Shear, Spiral, SpiralIn, SpiralOut, colorShader, diagShader, discLerp, easeCode, expLerp, extend, linLerp, polyLerp, randElt, randSign, rotateShader, shearShader, sizeShader,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend1 = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  easeCode = "#define M_PI 3.1415926535897932384626433832795\n\nfloat easeInOutSine(float pos) {\n#ifdef FLOW\n    return pos;\n#else\n    return 0.5 * (1.0 - cos(M_PI * pos));\n#endif\n}";

  rotateShader = easeCode + "uniform float deltaAngle;\nuniform float scale;\nuniform float time;\nuniform float duration;\nuniform float scaleZ;\n\nvec4 getPointSample(vec4 xyzw);\n\nvec4 rotate(vec4 xyzw) {\n    vec4 point = getPointSample(xyzw);\n\n    float start = point.w;\n    float pos = (time - start) / abs(duration);\n    if(duration < 0.0) pos = 1.0 - pos;\n    if(pos < 0.0) return vec4(point.xyz, 0.0);\n    if(pos > 1.0) pos = 1.0;\n    pos = easeInOutSine(pos);\n    float c = cos(deltaAngle * pos);\n    float s = sin(deltaAngle * pos);\n    point.xy = vec2(point.x * c - point.y * s, point.x * s + point.y * c)\n        * pow(scale, pos);\n    if(scaleZ != 0.0) point.z *= pow(scaleZ, pos);\n    return vec4(point.xyz, 0.0);\n}";

  diagShader = easeCode + "uniform float scaleX;\nuniform float scaleY;\nuniform float scaleZ;\nuniform float time;\nuniform float duration;\n\nvec4 getPointSample(vec4 xyzw);\n\nvec4 rotate(vec4 xyzw) {\n    vec4 point = getPointSample(xyzw);\n\n    float start = point.w;\n    float pos = (time - start) / abs(duration);\n    if(duration < 0.0) pos = 1.0 - pos;\n    if(pos < 0.0) return vec4(point.xyz, 0.0);\n    if(pos > 1.0) pos = 1.0;\n\n    pos = easeInOutSine(pos);\n    point.x *= pow(scaleX, pos);\n    point.y *= pow(scaleY, pos);\n    if(scaleZ != 0.0) point.z *= pow(scaleZ, pos);\n    return vec4(point.xyz, 0.0);\n}";

  shearShader = easeCode + "uniform float scale;\nuniform float translate;\nuniform float time;\nuniform float duration;\nuniform float scaleZ;\n\nvec4 getPointSample(vec4 xyzw);\n\nvec4 shear(vec4 xyzw) {\n    vec4 point = getPointSample(xyzw);\n\n    float start = point.w;\n    float pos = (time - start) / abs(duration);\n    if(duration < 0.0) pos = 1.0 - pos;\n    if(pos < 0.0) return vec4(point.xyz, 0.0);\n    if(pos > 1.0) pos = 1.0;\n\n    pos = easeInOutSine(pos);\n    float s = pow(scale, pos);\n    point.x  = s * (point.x + translate * pos * point.y);\n    point.y *= s;\n    if(scaleZ != 0.0) point.z *= pow(scaleZ, pos);\n    return vec4(point.xyz, 0.0);\n}";

  colorShader = easeCode + "uniform float time;\nuniform float duration;\n\nvec4 getPointSample(vec4 xyzw);\nvec4 getColorSample(vec4 xyzw);\n\nvec3 hsv2rgb(vec3 c) {\n  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);\n  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);\n  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);\n}\n\n#ifdef FLOW\n#define TRANSITION 0.0\n#else\n#define TRANSITION 0.2\n#endif\n\nvec4 getColor(vec4 xyzw) {\n    vec4 color = getColorSample(xyzw);\n    vec4 point = getPointSample(xyzw);\n\n    float start = point.w;\n    float pos, ease;\n    pos = (time - start) / abs(duration);\n    if(duration < 0.0) pos = 1.0 - pos;\n    if(pos < 0.0) pos = 0.0;\n    else if(pos > 1.0) pos = 1.0;\n\n    if(pos < TRANSITION) {\n        ease = easeInOutSine(pos / TRANSITION);\n        color.w *= ease * 0.6 + 0.4;\n        color.y *= ease * 0.6 + 0.4;\n    }\n    else if(pos > 1.0 - TRANSITION) {\n        ease = easeInOutSine((1.0 - pos) / TRANSITION);\n        color.w *= ease * 0.6 + 0.4;\n        color.y *= ease * 0.6 + 0.4;\n    }\n    return vec4(hsv2rgb(color.xyz), color.w);\n}";

  sizeShader = easeCode + "uniform float time;\nuniform float small;\nuniform float duration;\n\nvec4 getPointSample(vec4 xyzw);\n\n#ifdef FLOW\n#define TRANSITION 0.0\n#else\n#define TRANSITION 0.2\n#endif\n#define BIG (small * 7.0 / 5.0)\n\nvec4 getSize(vec4 xyzw) {\n    vec4 point = getPointSample(xyzw);\n\n    float start = point.w;\n    float pos, ease, size = BIG;\n    pos = (time - start) / abs(duration);\n    if(duration < 0.0) pos = 1.0 - pos;\n    if(pos < 0.0) pos = 0.0;\n    else if(pos > 1.0) pos = 1.0;\n\n    if(pos < TRANSITION) {\n        ease = easeInOutSine(pos / TRANSITION);\n        size = small * (1.0-ease) + BIG * ease;\n    }\n    else if(pos > 1.0 - TRANSITION) {\n        ease = easeInOutSine((1.0 - pos) / TRANSITION);\n        size = small * (1.0-ease) + BIG * ease;\n    }\n    return vec4(size, 0.0, 0.0, 0.0);\n}";

  HSVtoRGB = function(h, s, v) {
    var f, i, p, q, t;
    i = Math.floor(h * 6);
    f = h * 6 - i;
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);
    switch (i % 6) {
      case 0:
        return [v, t, p];
      case 1:
        return [q, v, p];
      case 2:
        return [p, v, t];
      case 3:
        return [p, q, v];
      case 4:
        return [t, p, v];
      case 5:
        return [v, p, q];
    }
  };

  expLerp = function(a, b) {
    return function(t) {
      return Math.pow(b, t) * Math.pow(a, 1 - t);
    };
  };

  linLerp = function(a, b) {
    return function(t) {
      return b * t + a * (1 - t);
    };
  };

  polyLerp = function(a, b, n) {
    return function(t) {
      return Math.pow(t, n) * (b - a) + a;
    };
  };

  discLerp = function(a, b, n) {
    return function(t) {
      return Math.floor(Math.random() * (n + 1)) * (b - a) / n + a;
    };
  };

  randElt = function(l) {
    return l[Math.floor(Math.random() * l.length)];
  };

  randSign = function() {
    return randElt([-1, 1]);
  };

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

  DynamicsView = (function() {
    function DynamicsView(opts) {
      this.randomizeCoords = bind(this.randomizeCoords, this);
      this.loadDynamics = bind(this.loadDynamics, this);
      this.updateView = bind(this.updateView, this);
      this.setCoords = bind(this.setCoords, this);
      var base, base1, base2, ref, ref1, ref2, ref3, ref4, ref5;
      if (opts == null) {
        opts = {};
      }
      this.is3D = (ref = opts.is3D) != null ? ref : false;
      this.axisColors = (ref1 = (ref2 = opts.axisColors) != null ? ref2.slice() : void 0) != null ? ref1 : [];
      this.refColor = (ref3 = opts.refColor) != null ? ref3 : "rgb(80, 120, 255)";
      this.timer = (ref4 = opts.timer) != null ? ref4 : true;
      this.axisOpts = {
        end: false,
        width: 3,
        zBias: -1,
        depth: 1,
        color: "black",
        range: [-10, 10]
      };
      extend(this.axisOpts, (ref5 = opts.axisOpts) != null ? ref5 : {});
      if ((base = this.axisColors)[0] == null) {
        base[0] = [0, 0, 0, 0.3];
      }
      if ((base1 = this.axisColors)[1] == null) {
        base1[1] = [0, 0, 0, 0.3];
      }
      if ((base2 = this.axisColors)[2] == null) {
        base2[2] = [0, 0, 0, 0.3];
      }
      this.mathbox = null;
      this.view0 = null;
      this.view = null;
      this.initialized = false;
      this.shaderElt = null;
      this.linesElt = null;
      this.linesDataElt = null;
    }

    DynamicsView.prototype.setCoords = function(v1, v2, v3) {
      var cmi, corners, rad, ref;
      if (v1[2] == null) {
        v1[2] = 0;
      }
      if (v2[2] == null) {
        v2[2] = 0;
      }
      if (v3 == null) {
        v3 = [0, 0, 1];
      }
      this.v1 = v1;
      this.v2 = v2;
      this.v3 = v3;
      this.coordMat = new THREE.Matrix4().set(v1[0], v2[0], v3[0], 0, v1[1], v2[1], v3[1], 0, v1[2], v2[2], v3[2], 0, 0, 0, 0, 1);
      cmi = this.coordMatInv = new THREE.Matrix4().getInverse(this.coordMat);
      corners = [new THREE.Vector3(1, 1, 1), new THREE.Vector3(-1, 1, 1), new THREE.Vector3(1, -1, 1), new THREE.Vector3(1, 1, -1)].map(function(c) {
        return c.applyMatrix4(cmi);
      });
      rad = Math.max.apply(null, corners.map(function(c) {
        return c.length();
      }));
      this.extents = {
        rad: rad,
        x: Math.max.apply(null, corners.map(function(c) {
          return Math.abs(c.x);
        })),
        y: Math.max.apply(null, corners.map(function(c) {
          return Math.abs(c.y);
        })),
        z: Math.max.apply(null, corners.map(function(c) {
          return Math.abs(c.z);
        }))
      };
      return (ref = this.controller) != null ? ref.recomputeExtents() : void 0;
    };

    DynamicsView.prototype.updateView = function(mathbox, view) {
      var canvas, controller, flow, i, k, len1, numPointsCol, numPointsDep, numPointsRow, params, pointsOpts, pointsType, ref, timer;
      if (this.mathbox == null) {
        this.mathbox = mathbox;
      }
      if (this.view0 == null) {
        this.view0 = view;
      }
      if (this.view) {
        this.view.set('matrix', this.coordMat);
      } else {
        this.view = this.view0.transform({
          matrix: this.coordMat
        });
        ref = (this.is3D ? [1, 2, 3] : [1, 2]);
        for (k = 0, len1 = ref.length; k < len1; k++) {
          i = ref[k];
          this.axisOpts.axis = i;
          this.axisOpts.color = this.axisColors[i - 1];
          this.axisOpts.opacity = this.axisColors[i - 1][3];
          this.view.axis(this.axisOpts);
        }
      }
      canvas = this.mathbox._context.canvas;
      flow = this.controller.flow;
      numPointsRow = this.controller.numPointsRow;
      numPointsCol = this.controller.numPointsCol;
      numPointsDep = this.controller.numPointsDep;
      if (this.initialized) {
        params = this.current.shaderParams();
        if (flow) {
          params.code = "#define FLOW\n" + params.code;
        }
        this.shaderElt.set(params);
        return this.linesDataElt.set(this.current.linesParams());
      } else {
        pointsOpts = {
          id: "points-orig",
          channels: 4,
          width: numPointsRow,
          height: numPointsCol,
          data: this.controller.points,
          live: false
        };
        if (this.is3D) {
          pointsOpts.depth = numPointsDep;
          pointsType = this.view.voxel;
        } else {
          pointsType = this.view.matrix;
        }
        this.pointsElt = pointsType(pointsOpts);
        params = this.current.shaderParams();
        if (flow) {
          params.code = "#define FLOW\n" + params.code;
        }
        controller = this.controller;
        if (this.timer) {
          timer = function(t) {
            return controller.curTime = t;
          };
        } else {
          timer = function(t) {
            return controller.curTime;
          };
        }
        this.shaderElt = this.pointsElt.shader(params, {
          time: timer,
          duration: (function(_this) {
            return function() {
              return _this.controller.duration * _this.controller.direction;
            };
          })(this)
        });
        this.shaderElt.resample({
          id: "points"
        });
        pointsOpts = {
          channels: 4,
          width: numPointsRow,
          height: numPointsCol,
          data: this.controller.colors,
          live: false
        };
        if (this.is3D) {
          pointsOpts.depth = numPointsDep;
          pointsType = this.view.voxel;
        } else {
          pointsType = this.view.matrix;
        }
        pointsType(pointsOpts).shader({
          code: (flow ? "#define FLOW\n" : "") + colorShader,
          sources: [this.pointsElt]
        }, {
          time: function() {
            return controller.curTime;
          },
          duration: (function(_this) {
            return function() {
              return _this.controller.duration * _this.controller.direction;
            };
          })(this)
        }).resample({
          id: "colors"
        });
        this.view0.shader({
          code: (flow ? "#define FLOW\n" : "") + sizeShader
        }, {
          time: function() {
            return controller.curTime;
          },
          small: function() {
            return 5 / 739 * canvas.clientWidth;
          },
          duration: (function(_this) {
            return function() {
              return _this.controller.duration * _this.controller.direction;
            };
          })(this)
        }).resample({
          source: this.pointsElt,
          id: "sizes"
        });
        this.view.point({
          points: "#points",
          color: "white",
          colors: "#colors",
          size: 1,
          sizes: "#sizes",
          zBias: 1,
          zIndex: 2
        });
        this.linesDataElt = this.view.matrix(this.current.linesParams());
        this.linesElt = this.view.line({
          color: this.refColor,
          width: this.is3D ? 5 : 2,
          opacity: this.is3D ? 0.8 : 0.4,
          zBias: 0,
          zIndex: 1
        });
        return this.initialized = true;
      }
    };

    DynamicsView.prototype.loadDynamics = function(dynamics) {
      this.current = dynamics;
      return this.matrixOrigCoords = new THREE.Matrix4().multiply(this.coordMat).multiply(this.current.stepMat).multiply(this.coordMatInv);
    };

    DynamicsView.prototype.randomizeCoords = function() {
      var distribution, len, v1, v2, θ, θoff;
      v1 = [0, 0];
      v2 = [0, 0];
      distribution = linLerp(0.5, 2);
      len = distribution(Math.random());
      θ = Math.random() * 2 * π;
      v1[0] = Math.cos(θ) * len;
      v1[1] = Math.sin(θ) * len;
      θoff = randSign() * linLerp(π / 4, 3 * π / 4)(Math.random());
      len = distribution(Math.random());
      v2[0] = Math.cos(θ + θoff) * len;
      v2[1] = Math.sin(θ + θoff) * len;
      return this.setCoords(v1, v2);
    };

    return DynamicsView;

  })();

  Controller = (function() {
    function Controller(opts) {
      this.delay = bind(this.delay, this);
      this.start = bind(this.start, this);
      this.unStep = bind(this.unStep, this);
      this.step = bind(this.step, this);
      this.goForwards = bind(this.goForwards, this);
      this.goBackwards = bind(this.goBackwards, this);
      this.loadDynamics = bind(this.loadDynamics, this);
      this.recomputeExtents = bind(this.recomputeExtents, this);
      this.addView = bind(this.addView, this);
      var ref, ref1, ref2, ref3, ref4, ref5, ref6;
      if (opts == null) {
        opts = {};
      }
      this.numPointsRow = (ref = opts.numPointsRow) != null ? ref : 50;
      this.numPointsCol = (ref1 = opts.numPointsCol) != null ? ref1 : 100;
      this.numPointsDep = (ref2 = opts.numPointsDep) != null ? ref2 : 10;
      this.duration = (ref3 = opts.duration) != null ? ref3 : 3.0;
      this.continuous = (ref4 = opts.continuous) != null ? ref4 : true;
      this.is3D = (ref5 = opts.is3D) != null ? ref5 : false;
      this.flow = (ref6 = opts.flow) != null ? ref6 : false;
      this.views = [];
      this.extents = {
        rad: 0,
        x: 0,
        y: 0,
        z: 0
      };
      this.current = null;
      this.direction = 1;
      if (!this.is3D) {
        this.numPointsDep = 1;
      }
      this.numPoints = this.numPointsRow * this.numPointsCol * this.numPointsDep - 1;
      this.curTime = 0;
      this.startTime = -this.duration;
      this.points = [[0, 0, 0, 1e15]];
      this.colors = [[0, 0, 0, 1]].concat((function() {
        var k, ref7, results;
        results = [];
        for (k = 0, ref7 = this.numPoints; 0 <= ref7 ? k < ref7 : k > ref7; 0 <= ref7 ? k++ : k--) {
          results.push([Math.random(), 1, 0.7, 1]);
        }
        return results;
      }).call(this));
    }

    Controller.prototype.addView = function(view) {
      view.controller = this;
      this.views.push(view);
      return this.recomputeExtents();
    };

    Controller.prototype.recomputeExtents = function() {
      var k, len1, prop, ref, results, view;
      this.extents = {
        rad: 0,
        x: 0,
        y: 0,
        z: 0
      };
      ref = this.views;
      results = [];
      for (k = 0, len1 = ref.length; k < len1; k++) {
        view = ref[k];
        results.push((function() {
          var len2, m, ref1, results1;
          ref1 = ["rad", "x", "y", "z"];
          results1 = [];
          for (m = 0, len2 = ref1.length; m < len2; m++) {
            prop = ref1[m];
            results1.push(this.extents[prop] = Math.max(this.extents[prop], view.extents[prop]));
          }
          return results1;
        }).call(this));
      }
      return results;
    };

    Controller.prototype.loadDynamics = function(type, opts) {
      var i, k, len1, m, ref, ref1, results, view;
      if (opts == null) {
        opts = {};
      }
      if (opts.onPlane == null) {
        opts.onPlane = 1.0 / this.numPointsDep;
      }
      this.current = new type(this.extents, opts);
      for (i = k = 1, ref = this.numPoints; 1 <= ref ? k <= ref : k >= ref; i = 1 <= ref ? ++k : --k) {
        this.points[i] = this.current.newPoint();
        this.points[i][3] = this.curTime + this.delay(true);
      }
      ref1 = this.views;
      results = [];
      for (m = 0, len1 = ref1.length; m < len1; m++) {
        view = ref1[m];
        results.push(view.loadDynamics(this.current));
      }
      return results;
    };

    Controller.prototype.goBackwards = function() {
      var k, len1, point, ref;
      ref = this.points;
      for (k = 0, len1 = ref.length; k < len1; k++) {
        point = ref[k];
        this.current.stepMat.applyToVector3Array(point, 0, 3);
      }
      return this.direction = -1;
    };

    Controller.prototype.goForwards = function() {
      var k, len1, point, ref;
      ref = this.points;
      for (k = 0, len1 = ref.length; k < len1; k++) {
        point = ref[k];
        this.current.inverse.stepMat.applyToVector3Array(point, 0, 3);
      }
      return this.direction = 1;
    };

    Controller.prototype.step = function() {
      var i, k, len1, len2, m, point, ref, ref1, view;
      if (!this.continuous && !this.flow) {
        if (this.startTime + this.duration > this.curTime) {
          return;
        }
        this.startTime = this.curTime;
      }
      if (this.direction === -1) {
        this.goForwards();
      }
      ref = this.points;
      for (i = k = 0, len1 = ref.length; k < len1; i = ++k) {
        point = ref[i];
        if (i === 0) {
          continue;
        }
        if (point[3] + this.duration <= this.curTime) {
          this.current.stepMat.applyToVector3Array(point, 0, 3);
          this.current.updatePoint(point);
          point[3] = this.curTime + this.delay();
        }
      }
      ref1 = this.views;
      for (m = 0, len2 = ref1.length; m < len2; m++) {
        view = ref1[m];
        view.pointsElt.set('data', []);
        view.pointsElt.set('data', this.points);
      }
      return null;
    };

    Controller.prototype.unStep = function() {
      var i, inv, k, len1, len2, m, point, ref, ref1, view;
      if (!this.continuous && !this.flow) {
        if (this.startTime + this.duration > this.curTime) {
          return;
        }
        this.startTime = this.curTime;
      }
      if (this.direction === 1) {
        this.goBackwards();
      }
      inv = this.current.inverse;
      ref = this.points;
      for (i = k = 0, len1 = ref.length; k < len1; i = ++k) {
        point = ref[i];
        if (i === 0) {
          continue;
        }
        if (point[3] + this.duration <= this.curTime) {
          inv.updatePoint(point);
          inv.stepMat.applyToVector3Array(point, 0, 3);
          point[3] = this.curTime + this.delay();
        }
      }
      ref1 = this.views;
      for (m = 0, len2 = ref1.length; m < len2; m++) {
        view = ref1[m];
        view.pointsElt.set('data', []);
        view.pointsElt.set('data', this.points);
      }
      return null;
    };

    Controller.prototype.start = function(interval) {
      if (interval == null) {
        interval = 100;
      }
      return setInterval(this.step, interval);
    };

    Controller.prototype.delay = function(first) {
      var pos, scale;
      if (!this.continuous) {
        if (first) {
          return -this.duration;
        } else {
          return 0;
        }
      }
      scale = this.numPoints / 1000;
      pos = Math.random() * scale;
      if (first) {
        return pos - 0.5 * scale;
      } else {
        return pos;
      }
    };

    return Controller;

  })();

  Dynamics = (function() {
    function Dynamics(extents1, opts) {
      var ref, ref1;
      this.extents = extents1;
      this.linesParams = bind(this.linesParams, this);
      this.updatePoint = bind(this.updatePoint, this);
      this.newPoint = bind(this.newPoint, this);
      this.timeToLeave = bind(this.timeToLeave, this);
      this.scaleZ = (ref = opts.scaleZ) != null ? ref : 0.0;
      this.onPlane = (ref1 = opts.onPlane) != null ? ref1 : 1 / 20;
      if (Math.abs(this.scaleZ) < 1e-5) {
        this.is3D = false;
        this.zAtTime = function(start, t) {
          return 0;
        };
        this.timeToLeaveZ = function(start) {
          return 2e308;
        };
        this.needsResetZ = (function(_this) {
          return function(z) {
            return false;
          };
        })(this);
      } else if (Math.abs(this.scaleZ - 1) < 1e-5) {
        this.is3D = true;
        this.scaleZ = 1.0;
        this.origLerpZ = linLerp(0.01, this.extents.z);
        this.zAtTime = function(start, t) {
          return start;
        };
        this.timeToLeaveZ = function(start) {
          return 2e308;
        };
        this.needsResetZ = (function(_this) {
          return function(z) {
            return false;
          };
        })(this);
      } else if (this.scaleZ < 1.0) {
        this.is3D = true;
        this.origLerpZ = expLerp(0.01, this.extents.z / this.scaleZ);
        this.newLerpZ = expLerp(this.extents.z, this.extents.z / this.scaleZ);
        this.zAtTime = (function(_this) {
          return function(start, t) {
            return start * Math.pow(_this.scaleZ, t);
          };
        })(this);
        this.timeToLeaveZ = (function(_this) {
          return function(start) {
            return Math.log(0.01 / Math.abs(start)) / Math.log(_this.scaleZ);
          };
        })(this);
        this.needsResetZ = (function(_this) {
          return function(z) {
            return Math.abs(z) < 0.01;
          };
        })(this);
      } else if (this.scaleZ > 1.0) {
        this.is3D = true;
        this.origLerpZ = expLerp(0.01 / this.scaleZ, this.extents.z);
        this.newLerpZ = expLerp(0.01 / this.scaleZ, 0.01);
        this.zAtTime = (function(_this) {
          return function(start, t) {
            return start * Math.pow(_this.scaleZ, t);
          };
        })(this);
        this.timeToLeaveZ = (function(_this) {
          return function(start) {
            return Math.log(_this.extents.z / Math.abs(start)) / Math.log(_this.scaleZ);
          };
        })(this);
        this.needsResetZ = (function(_this) {
          return function(z) {
            return Math.abs(z) > _this.extents.z;
          };
        })(this);
      }
      this.invScaleZ = this.is3D ? 1 / this.scaleZ : 0.0;
    }

    Dynamics.prototype.makeStepMat = function(a, b, c, d) {
      var z;
      z = this.scaleZ;
      this.stepMat22 = [[a, b], [c, d]];
      return this.stepMat = new THREE.Matrix4().set(a, b, 0, 0, c, d, 0, 0, 0, 0, z, 0, 0, 0, 0, 1);
    };

    Dynamics.prototype.timeToLeave = function(point) {
      var x;
      x = this.timeToLeaveZ(point[2]);
      if (isFinite(x) && x >= 0 && x <= 25) {
        return x;
      }
      x = this.timeToLeaveXY(point[0], point[1]);
      if (x >= 0 && x <= 25) {
        return x;
      } else {
        return 2e308;
      }
    };

    Dynamics.prototype.newPoint = function() {
      var xy, z;
      if (this.is3D) {
        if (Math.random() < this.onPlane) {
          z = 0.0;
        } else {
          z = randSign() * this.origLerpZ(Math.random());
        }
      } else {
        z = 0;
      }
      xy = this.origDistr();
      return [xy[0], xy[1], z, 0];
    };

    Dynamics.prototype.updatePoint = function(point) {
      var ref;
      if (this.needsResetXY(point[0], point[1])) {
        ref = this.newDistr(point), point[0] = ref[0], point[1] = ref[1];
      }
      if (!(this.is3D && this.scaleZ !== 1.0)) {
        return point;
      }
      if (point[2] === 0.0) {
        return point;
      }
      if (this.needsResetZ(point[2])) {
        point[2] = randSign() * this.newLerpZ(Math.random());
      }
      return point;
    };

    Dynamics.prototype.linesParams = function() {
      var reference;
      reference = this.makeReference();
      return {
        channels: 2,
        height: reference.length,
        width: reference[0].length,
        items: reference[0][0].length,
        live: false,
        data: reference
      };
    };

    Dynamics.prototype.shaderParams = function(params) {
      if (params.uniforms == null) {
        params.uniforms = {};
      }
      params.uniforms.scaleZ = {
        type: 'f',
        value: this.scaleZ
      };
      return params;
    };

    return Dynamics;

  })();

  Complex = (function(superClass) {
    extend1(Complex, superClass);

    function Complex(extents, opts) {
      this.shaderParams = bind(this.shaderParams, this);
      this.distr = bind(this.distr, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      var ref, ref1;
      Complex.__super__.constructor.call(this, extents, opts);
      if (opts == null) {
        opts = {};
      }
      this.θ = (ref = opts.θ) != null ? ref : randSign() * linLerp(π / 6, 5 * π / 6)(Math.random());
      this.scale = (ref1 = opts.scale) != null ? ref1 : this.randomScale();
      this.logScale = Math.log(this.scale);
      this.makeStepMat(Math.cos(this.θ) * this.scale, -Math.sin(this.θ) * this.scale, Math.sin(this.θ) * this.scale, Math.cos(this.θ) * this.scale);
      this.makeDistributions(opts);
    }

    Complex.prototype.origDistr = function() {
      return this.distr(this.origDist);
    };

    Complex.prototype.newDistr = function() {
      return this.distr(this.newDist);
    };

    Complex.prototype.distr = function(distribution) {
      var r, θ;
      r = distribution(Math.random());
      θ = Math.random() * 2 * π;
      return [Math.cos(θ) * r, Math.sin(θ) * r];
    };

    Complex.prototype.shaderParams = function() {
      return Complex.__super__.shaderParams.call(this, {
        code: rotateShader,
        uniforms: {
          deltaAngle: {
            type: 'f',
            value: this.θ
          },
          scale: {
            type: 'f',
            value: this.scale
          }
        }
      });
    };

    return Complex;

  })(Dynamics);

  Circle = (function(superClass) {
    extend1(Circle, superClass);

    Circle.prototype.descr = function() {
      return "Ovals";
    };

    function Circle(extents, opts) {
      this.makePath = bind(this.makePath, this);
      this.makeReference = bind(this.makeReference, this);
      this.makeDistributions = bind(this.makeDistributions, this);
      this.randomScale = bind(this.randomScale, this);
      var ref;
      Circle.__super__.constructor.call(this, extents, opts);
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new Circle(extents, {
        θ: -this.θ,
        scale: 1 / this.scale,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    Circle.prototype.randomScale = function() {
      return 1;
    };

    Circle.prototype.makeDistributions = function(opts) {
      return this.newDist = this.origDist = polyLerp(0.01, this.extents.rad, 1 / 2);
    };

    Circle.prototype.makeReference = function() {
      var k, m, ref, ref1, ref2, ref3, ref4, ret, row, s, t;
      ret = [];
      for (t = k = 0, ref = 2 * π, ref1 = π / 72; ref1 > 0 ? k < ref : k > ref; t = k += ref1) {
        row = [];
        for (s = m = ref2 = this.extents.rad / 10, ref3 = this.extents.rad, ref4 = this.extents.rad / 10; ref4 > 0 ? m < ref3 : m > ref3; s = m += ref4) {
          row.push([s * Math.cos(t), s * Math.sin(t)]);
        }
        ret.push(row);
      }
      ret.push(ret[0]);
      return [ret];
    };

    Circle.prototype.makePath = function(start, path) {
      var c, i, k, ref, s, totalAngle, ttl, α;
      ttl = this.timeToLeave(start);
      if (!isFinite(ttl)) {
        ttl = 2 * π * (path.length + 1) / (path.length * Math.abs(this.θ));
      }
      totalAngle = ttl * this.θ;
      for (i = k = 0, ref = path.length; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        α = totalAngle * i / path.length;
        c = Math.cos(α);
        s = Math.sin(α);
        path[i] = [c * start[0] - s * start[1], s * start[0] + c * start[1], this.zAtTime(start[2], ttl * i / path.length)];
      }
      return path;
    };

    Circle.prototype.needsResetXY = function(x, y) {
      return false;
    };

    Circle.prototype.timeToLeaveXY = function(x, y) {
      return 2e308;
    };

    return Circle;

  })(Complex);

  Spiral = (function(superClass) {
    extend1(Spiral, superClass);

    function Spiral() {
      this.makePath = bind(this.makePath, this);
      this.makeReference = bind(this.makeReference, this);
      return Spiral.__super__.constructor.apply(this, arguments);
    }

    Spiral.prototype.makeReference = function() {
      var close, d, i, items, iters, j, k, m, o, ref, ref1, ref2, ret, rotations, row, s, ss, t, u;
      ret = [];
      close = 0.05;
      s = this.scale > 1 ? this.scale : 1 / this.scale;
      iters = (Math.log(this.extents.rad) - Math.log(close)) / Math.log(s);
      rotations = Math.ceil(this.θ * iters / 2 * π);
      d = this.direction;
      for (i = k = 0, ref = rotations; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
        row = [];
        for (t = m = 0; m <= 100; t = ++m) {
          u = (i + t / 100) * 2 * π;
          ss = close * Math.pow(s, u / this.θ);
          items = [];
          for (j = o = 0, ref1 = 2 * π, ref2 = π / 4; ref2 > 0 ? o < ref1 : o > ref1; j = o += ref2) {
            items.push([ss * Math.cos(d * (u + j)), ss * Math.sin(d * (u + j))]);
          }
          row.push(items);
        }
        ret.push(row);
      }
      return ret;
    };

    Spiral.prototype.makePath = function(start, path) {
      var c, i, k, ref, s, ss, t, totalAngle, ttl, α;
      ttl = this.timeToLeave(start);
      if (!isFinite(ttl)) {
        ttl = 2 * π * (path.length + 1) / (path.length * Math.abs(this.θ));
      }
      totalAngle = ttl * this.θ;
      for (i = k = 0, ref = path.length; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        α = totalAngle * i / path.length;
        c = Math.cos(α);
        s = Math.sin(α);
        t = ttl * i / path.length;
        ss = Math.pow(this.scale, t);
        path[i] = [ss * c * start[0] - ss * s * start[1], ss * s * start[0] + ss * c * start[1], this.zAtTime(start[2], t)];
      }
      return path;
    };

    return Spiral;

  })(Complex);

  SpiralIn = (function(superClass) {
    extend1(SpiralIn, superClass);

    SpiralIn.prototype.descr = function() {
      return "Spiral in";
    };

    function SpiralIn(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.makeDistributions = bind(this.makeDistributions, this);
      var ref;
      SpiralIn.__super__.constructor.call(this, extents, opts);
      this.direction = -1;
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new SpiralOut(extents, {
        θ: -this.θ,
        scale: 1 / this.scale,
        inverse: this,
        dist: this.distType,
        scaleZ: this.invScaleZ
      });
    }

    SpiralIn.prototype.randomScale = function() {
      return linLerp(0.3, 0.8)(Math.random());
    };

    SpiralIn.prototype.makeDistributions = function(opts) {
      var distance, distances, ref;
      this.close = 0.01;
      this.medium = this.extents.rad;
      this.far = this.extents.rad / this.scale;
      this.distType = (ref = opts.dist) != null ? ref : randElt(['cont', 'disc']);
      switch (this.distType) {
        case 'cont':
          this.origDist = expLerp(this.close, this.far);
          return this.newDist = expLerp(this.medium, this.far);
        case 'disc':
          distances = [];
          distance = this.far;
          while (distance > this.close) {
            distances.push(distance);
            distance *= this.scale;
          }
          this.origDist = function(t) {
            return distances[Math.floor(t * distances.length)];
          };
          return this.newDist = (function(_this) {
            return function(t) {
              return _this.far;
            };
          })(this);
      }
    };

    SpiralIn.prototype.needsResetXY = function(x, y) {
      return x * x + y * y < this.close * this.close;
    };

    SpiralIn.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(0.01) - .5 * Math.log(x * x + y * y)) / this.logScale;
    };

    return SpiralIn;

  })(Spiral);

  SpiralOut = (function(superClass) {
    extend1(SpiralOut, superClass);

    SpiralOut.prototype.descr = function() {
      return "Spiral out";
    };

    function SpiralOut(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.makeDistributions = bind(this.makeDistributions, this);
      this.randomScale = bind(this.randomScale, this);
      var ref;
      SpiralOut.__super__.constructor.call(this, extents, opts);
      this.direction = 1;
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new SpiralIn(extents, {
        θ: -this.θ,
        scale: 1 / this.scale,
        inverse: this,
        dist: this.distType,
        scaleZ: this.invScaleZ
      });
    }

    SpiralOut.prototype.randomScale = function() {
      return linLerp(1 / 0.8, 1 / 0.3)(Math.random());
    };

    SpiralOut.prototype.makeDistributions = function(opts) {
      var distance, distances, ref;
      this.veryClose = 0.01 / this.scale;
      this.close = 0.01;
      this.medium = this.extents.rad;
      this.distType = (ref = opts.dist) != null ? ref : randElt(['cont', 'disc']);
      switch (this.distType) {
        case 'cont':
          this.origDist = expLerp(this.veryClose, this.medium);
          return this.newDist = expLerp(this.veryClose, this.close);
        case 'disc':
          distances = [];
          distance = this.veryClose;
          while (distance < this.medium) {
            distances.push(distance);
            distance *= this.scale;
          }
          this.origDist = function(t) {
            return distances[Math.floor(t * distances.length)];
          };
          return this.newDist = (function(_this) {
            return function(t) {
              return _this.veryClose;
            };
          })(this);
      }
    };

    SpiralOut.prototype.needsResetXY = function(x, y) {
      return x * x + y * y > this.medium * this.medium;
    };

    SpiralOut.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(this.extents.rad) - .5 * Math.log(x * x + y * y)) / this.logScale;
    };

    return SpiralOut;

  })(Spiral);

  Diagonalizable = (function(superClass) {
    extend1(Diagonalizable, superClass);

    function Diagonalizable(extents, opts) {
      this.makePath = bind(this.makePath, this);
      this.shaderParams = bind(this.shaderParams, this);
      this.swap = bind(this.swap, this);
      var λ1, λ2;
      Diagonalizable.__super__.constructor.call(this, extents, opts);
      if (opts == null) {
        opts = {};
      }
      this.swapped = false;
      this.makeScales(opts);
      λ1 = this.λ1;
      if (opts.negate1) {
        λ1 *= -1;
      }
      λ2 = this.λ2;
      if (opts.negate2) {
        λ2 *= -1;
      }
      if (this.swapped) {
        this.makeStepMat(λ2, 0, 0, λ1);
      } else {
        this.makeStepMat(λ1, 0, 0, λ2);
      }
    }

    Diagonalizable.prototype.swap = function() {
      var ref;
      ref = [this.λ1, this.λ2], this.λ2 = ref[0], this.λ1 = ref[1];
      this.extents = {
        rad: this.extents.rad,
        x: this.extents.y,
        y: this.extents.x,
        z: this.extents.z
      };
      return this.swapped = true;
    };

    Diagonalizable.prototype.shaderParams = function() {
      return Diagonalizable.__super__.shaderParams.call(this, {
        code: diagShader,
        uniforms: {
          scaleX: {
            type: 'f',
            value: this.swapped ? this.λ2 : this.λ1
          },
          scaleY: {
            type: 'f',
            value: this.swapped ? this.λ1 : this.λ2
          }
        }
      });
    };

    Diagonalizable.prototype.makePath = function(start, path) {
      var i, k, ref, sx, sy, t, ttl;
      ttl = this.timeToLeave(start);
      if (!isFinite(ttl)) {
        ttl = 25;
      }
      if (this.swapped) {
        sx = this.λ2;
        sy = this.λ1;
      } else {
        sx = this.λ1;
        sy = this.λ2;
      }
      for (i = k = 0, ref = path.length; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        t = ttl * i / path.length;
        path[i] = [start[0] * Math.pow(sx, t), start[1] * Math.pow(sy, t), this.zAtTime(start[2], t)];
      }
      return path;
    };

    return Diagonalizable;

  })(Dynamics);

  Hyperbolas = (function(superClass) {
    extend1(Hyperbolas, superClass);

    Hyperbolas.prototype.descr = function() {
      return "Hyperbolas";
    };

    function Hyperbolas(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.makeReference = bind(this.makeReference, this);
      this.distr = bind(this.distr, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      this.makeScales = bind(this.makeScales, this);
      var ref, ref1, λ1, λ2;
      Hyperbolas.__super__.constructor.call(this, extents, opts);
      ref = this.swapped ? [this.λ2, this.λ1] : [this.λ1, this.λ2], λ1 = ref[0], λ2 = ref[1];
      this.inverse = (ref1 = opts != null ? opts.inverse : void 0) != null ? ref1 : new Hyperbolas(extents, {
        λ1: 1 / λ1,
        λ2: 1 / λ2,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    Hyperbolas.prototype.makeScales = function(opts) {
      var ref, ref1;
      this.λ1 = (ref = opts.λ1) != null ? ref : linLerp(0.3, 0.8)(Math.random());
      this.λ2 = (ref1 = opts.λ2) != null ? ref1 : linLerp(1 / 0.8, 1 / 0.3)(Math.random());
      if (this.λ1 > this.λ2) {
        this.swap();
      }
      this.logScaleX = Math.log(this.λ1);
      this.logScaleY = Math.log(this.λ2);
      this.close = 0.05;
      this.closeR = Math.pow(this.close, this.logScaleY - this.logScaleX);
      this.farR = Math.pow(this.extents.x, this.logScaleY) * Math.pow(this.extents.y, -this.logScaleX);
      return this.lerpR = linLerp(this.closeR, this.farR);
    };

    Hyperbolas.prototype.origDistr = function() {
      return this.distr(true);
    };

    Hyperbolas.prototype.newDistr = function() {
      return this.distr(false);
    };

    Hyperbolas.prototype.distr = function(orig) {
      var closeX, r, x, y;
      r = this.lerpR(Math.random());
      if (orig) {
        closeX = Math.pow(r * Math.pow(this.extents.y, this.logScaleX), 1 / this.logScaleY);
        x = expLerp(closeX, this.extents.x / this.λ1)(Math.random());
      } else {
        x = expLerp(this.extents.x, this.extents.x / this.λ1)(Math.random());
      }
      y = Math.pow(1 / r * Math.pow(x, this.logScaleY), 1 / this.logScaleX);
      if (this.swapped) {
        return [randSign() * y, randSign() * x];
      } else {
        return [randSign() * x, randSign() * y];
      }
    };

    Hyperbolas.prototype.makeReference = function() {
      var closeX, i, k, lerp, m, r, ret, row, t, x, y;
      ret = [];
      for (t = k = 0; k < 20; t = ++k) {
        r = this.lerpR(t / 20);
        closeX = Math.pow(r * Math.pow(this.extents.y, this.logScaleX), 1 / this.logScaleY);
        lerp = expLerp(closeX, this.extents.x);
        row = [];
        for (i = m = 0; m <= 100; i = ++m) {
          x = lerp(i / 100);
          y = Math.pow(1 / r * Math.pow(x, this.logScaleY), 1 / this.logScaleX);
          if (this.swapped) {
            row.push([[y, x], [y, -x], [-y, x], [-y, -x]]);
          } else {
            row.push([[x, y], [-x, y], [x, -y], [-x, -y]]);
          }
        }
        ret.push(row);
      }
      return ret;
    };

    Hyperbolas.prototype.needsResetXY = function(x, y) {
      return Math.abs(this.swapped ? x : y) > this.extents.y;
    };

    Hyperbolas.prototype.timeToLeaveXY = function(x, y) {
      if (this.swapped) {
        y = x;
      }
      return (Math.log(this.extents.y) - Math.log(Math.abs(y))) / this.logScaleY;
    };

    return Hyperbolas;

  })(Diagonalizable);

  AttractRepel = (function(superClass) {
    extend1(AttractRepel, superClass);

    function AttractRepel() {
      this.makeReference = bind(this.makeReference, this);
      this.makeScales = bind(this.makeScales, this);
      return AttractRepel.__super__.constructor.apply(this, arguments);
    }

    AttractRepel.prototype.makeScales = function(opts) {
      var a, offset;
      this.logScaleX = Math.log(this.λ1);
      this.logScaleY = Math.log(this.λ2);
      offset = 0.05;
      this.lerpR = function(t) {
        t = linLerp(offset, 1 - offset)(t);
        return Math.pow(t, this.logScaleY) * Math.pow(1 - t, -this.logScaleX);
      };
      a = this.logScaleY / this.logScaleX;
      this.sMin = 0.01;
      this.sMax = Math.pow(this.extents.x, a) + this.extents.y;
      this.yValAt = function(r, s) {
        return s / (1 + Math.pow(r, 1 / this.logScaleX));
      };
      return this.xOfY = function(y, r) {
        return Math.pow(r * Math.pow(y, this.logScaleX), 1 / this.logScaleY);
      };
    };

    AttractRepel.prototype.makeReference = function() {
      var i, k, lerp, m, r, ret, row, x, y;
      ret = [];
      for (i = k = 0; k < 15; i = ++k) {
        r = this.lerpR(i / 15);
        lerp = expLerp(0.01, this.extents.y);
        row = [];
        for (i = m = 0; m <= 100; i = ++m) {
          y = lerp(i / 100);
          x = this.xOfY(y, r);
          row.push([[x, y], [-x, y], [x, -y], [-x, -y]]);
        }
        ret.push(row);
      }
      return ret;
    };

    return AttractRepel;

  })(Diagonalizable);

  Attract = (function(superClass) {
    extend1(Attract, superClass);

    Attract.prototype.descr = function() {
      return "Attracting point";
    };

    function Attract(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.distr = bind(this.distr, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      this.makeScales = bind(this.makeScales, this);
      var ref;
      Attract.__super__.constructor.call(this, extents, opts);
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new Repel(extents, {
        λ1: 1 / this.λ1,
        λ2: 1 / this.λ2,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    Attract.prototype.makeScales = function(opts) {
      var ref, ref1;
      this.λ1 = (ref = opts.λ1) != null ? ref : linLerp(0.3, 0.9)(Math.random());
      this.λ2 = (ref1 = opts.λ2) != null ? ref1 : linLerp(0.3, this.λ1)(Math.random());
      if (this.λ1 < this.λ2) {
        throw "Must pass smaller eigenvalue second";
      }
      return Attract.__super__.makeScales.call(this, opts);
    };

    Attract.prototype.origDistr = function() {
      return this.distr(true);
    };

    Attract.prototype.newDistr = function() {
      return this.distr(false);
    };

    Attract.prototype.distr = function(orig) {
      var closeY, farY, r, x, y;
      r = this.lerpR(Math.random());
      farY = this.yValAt(r, this.sMax / this.λ2);
      if (orig) {
        closeY = this.yValAt(r, this.sMin);
      } else {
        closeY = this.yValAt(r, this.sMax);
      }
      y = expLerp(closeY, farY)(Math.random());
      x = this.xOfY(y, r);
      return [randSign() * x, randSign() * y];
    };

    Attract.prototype.needsResetXY = function(x, y) {
      return Math.abs(y) < .01;
    };

    Attract.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(0.01) - Math.log(Math.abs(y))) / this.logScaleY;
    };

    return Attract;

  })(AttractRepel);

  Repel = (function(superClass) {
    extend1(Repel, superClass);

    Repel.prototype.descr = function() {
      return "Repelling point";
    };

    function Repel(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.distr = bind(this.distr, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      this.makeScales = bind(this.makeScales, this);
      var ref;
      Repel.__super__.constructor.call(this, extents, opts);
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new Attract(extents, {
        λ1: 1 / this.λ1,
        λ2: 1 / this.λ2,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    Repel.prototype.makeScales = function(opts) {
      var ref, ref1;
      this.λ2 = (ref = opts.λ2) != null ? ref : linLerp(1 / 0.9, 1 / 0.3)(Math.random());
      this.λ1 = (ref1 = opts.λ1) != null ? ref1 : linLerp(1 / 0.9, this.λ2)(Math.random());
      if (this.λ1 > this.λ2) {
        throw "Must pass smaller eigenvalue first";
      }
      return Repel.__super__.makeScales.call(this, opts);
    };

    Repel.prototype.origDistr = function() {
      return this.distr(true);
    };

    Repel.prototype.newDistr = function() {
      return this.distr(false);
    };

    Repel.prototype.distr = function(orig) {
      var closeY, farY, r, x, y;
      r = this.lerpR(Math.random());
      closeY = this.yValAt(r, this.sMin / this.λ2);
      if (orig) {
        farY = this.yValAt(r, this.sMax);
      } else {
        farY = this.yValAt(r, this.sMin);
      }
      y = expLerp(closeY, farY)(Math.random());
      x = this.xOfY(y, r);
      return [randSign() * x, randSign() * y];
    };

    Repel.prototype.needsResetXY = function(x, y) {
      return Math.abs(x) > this.extents.x || Math.abs(y) > this.extents.y;
    };

    Repel.prototype.timeToLeaveXY = function(x, y) {
      return Math.min((Math.log(this.extents.x) - Math.log(Math.abs(x))) / this.logScaleX, (Math.log(this.extents.y) - Math.log(Math.abs(y))) / this.logScaleY);
    };

    return Repel;

  })(AttractRepel);

  AttractRepelLine = (function(superClass) {
    extend1(AttractRepelLine, superClass);

    function AttractRepelLine() {
      this.makeReference = bind(this.makeReference, this);
      this.distr = bind(this.distr, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      this.makeScales = bind(this.makeScales, this);
      return AttractRepelLine.__super__.constructor.apply(this, arguments);
    }

    AttractRepelLine.prototype.makeScales = function(opts) {
      this.λ1 = 1;
      return this.lerpX = linLerp(-this.extents.x, this.extents.x);
    };

    AttractRepelLine.prototype.origDistr = function() {
      return this.distr(this.origLerpY);
    };

    AttractRepelLine.prototype.newDistr = function() {
      return this.distr(this.newLerpY);
    };

    AttractRepelLine.prototype.distr = function(distribution) {
      var x, y;
      x = this.lerpX(Math.random());
      y = distribution(Math.random());
      return [x, randSign() * y];
    };

    AttractRepelLine.prototype.makeReference = function() {
      var i, item1, item2, k, x;
      item1 = [];
      item2 = [];
      for (i = k = 0; k < 20; i = ++k) {
        x = this.lerpX((i + .5) / 20);
        item1.push([x, -this.extents.y]);
        item2.push([x, this.extents.y]);
      }
      return [[item1, item2]];
    };

    return AttractRepelLine;

  })(Diagonalizable);

  AttractLine = (function(superClass) {
    extend1(AttractLine, superClass);

    AttractLine.prototype.descr = function() {
      return "Attracting line";
    };

    function AttractLine(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.makeScales = bind(this.makeScales, this);
      var ref;
      AttractLine.__super__.constructor.call(this, extents, opts);
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new RepelLine(extents, {
        λ1: 1 / this.λ1,
        λ2: 1 / this.λ2,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    AttractLine.prototype.makeScales = function(opts) {
      var ref;
      AttractLine.__super__.makeScales.call(this, opts);
      this.λ2 = (ref = opts.λ2) != null ? ref : linLerp(0.3, 0.8)(Math.random());
      this.origLerpY = expLerp(0.01, this.extents.y / this.λ2);
      return this.newLerpY = expLerp(this.extents.y, this.extents.y / this.λ2);
    };

    AttractLine.prototype.needsResetXY = function(x, y) {
      return Math.abs(y) < 0.01;
    };

    AttractLine.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(0.01) - Math.log(Math.abs(y))) / this.logScaleY;
    };

    return AttractLine;

  })(AttractRepelLine);

  RepelLine = (function(superClass) {
    extend1(RepelLine, superClass);

    RepelLine.prototype.descr = function() {
      return "Repelling line";
    };

    function RepelLine(extents, opts) {
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.makeScales = bind(this.makeScales, this);
      var ref;
      RepelLine.__super__.constructor.call(this, extents, opts);
      this.inverse = (ref = opts != null ? opts.inverse : void 0) != null ? ref : new AttractLine(extents, {
        λ1: 1 / this.λ1,
        λ2: 1 / this.λ2,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    RepelLine.prototype.makeScales = function(opts) {
      var ref;
      RepelLine.__super__.makeScales.call(this, opts);
      this.λ2 = (ref = opts.λ2) != null ? ref : linLerp(1 / 0.8, 1 / 0.3)(Math.random());
      this.origLerpY = expLerp(0.01 / this.λ2, this.extents.y);
      return this.newLerpY = expLerp(0.01 / this.λ2, 0.01);
    };

    RepelLine.prototype.needsResetXY = function(x, y) {
      return Math.abs(y) > this.extents.y;
    };

    RepelLine.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(this.extents.y) - Math.log(Math.abs(y))) / this.logScaleY;
    };

    return RepelLine;

  })(AttractRepelLine);

  Shear = (function(superClass) {
    extend1(Shear, superClass);

    Shear.prototype.descr = function() {
      return "Shear";
    };

    function Shear(extents, opts) {
      this.makePath = bind(this.makePath, this);
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      this.makeReference = bind(this.makeReference, this);
      this.shaderParams = bind(this.shaderParams, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      var ref, ref1;
      Shear.__super__.constructor.call(this, extents, opts);
      if (opts == null) {
        opts = {};
      }
      this.translate = (ref = opts.translate) != null ? ref : randSign() * linLerp(0.2, 2.0)(Math.random());
      this.makeStepMat(1, this.translate, 0, 1);
      this.lerpY = linLerp(0.01, this.extents.y);
      this.lerpY2 = linLerp(-this.extents.y, this.extents.y);
      this.inverse = (ref1 = opts != null ? opts.inverse : void 0) != null ? ref1 : new Shear(extents, {
        translate: -this.translate,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    Shear.prototype.origDistr = function() {
      var a, s, x, y;
      a = this.translate;
      y = this.lerpY(Math.random());
      if (Math.random() < 0.005) {
        y = 0;
        x = linLerp(-this.extents.x, this.extents.x)(Math.random());
      } else {
        if (a < 0) {
          x = linLerp(-this.extents.x, this.extents.x - a * y)(Math.random());
        } else {
          x = linLerp(-this.extents.x - a * y, this.extents.x)(Math.random());
        }
      }
      s = randSign();
      return [s * x, s * y];
    };

    Shear.prototype.newDistr = function(oldPoint) {
      var a, s, x, y;
      a = this.translate;
      y = Math.abs(oldPoint[1]);
      if (a < 0) {
        x = linLerp(this.extents.x, this.extents.x - a * y)(Math.random());
      } else {
        x = linLerp(-this.extents.x - a * y, -this.extents.x)(Math.random());
      }
      s = randSign();
      return [s * x, s * y];
    };

    Shear.prototype.shaderParams = function() {
      return Shear.__super__.shaderParams.call(this, {
        code: shearShader,
        uniforms: {
          scale: {
            type: 'f',
            value: 1.0
          },
          translate: {
            type: 'f',
            value: this.translate
          }
        }
      });
    };

    Shear.prototype.makeReference = function() {
      var i, item1, item2, k, y;
      item1 = [];
      item2 = [];
      for (i = k = 0; k < 20; i = ++k) {
        y = this.lerpY2((i + .5) / 20);
        item1.push([-this.extents.x, y]);
        item2.push([this.extents.x, y]);
      }
      return [[item1, item2]];
    };

    Shear.prototype.needsResetXY = function(x, y) {
      return Math.abs(x) > this.extents.x;
    };

    Shear.prototype.timeToLeaveXY = function(x, y) {
      var e;
      e = y > 0 ? this.extents.x : -this.extents.x;
      return (e - x) / (this.translate * y);
    };

    Shear.prototype.makePath = function(start, path) {
      var i, k, ref, t, ttl;
      ttl = this.timeToLeave(start);
      if (!isFinite(ttl)) {
        ttl = 100;
      }
      for (i = k = 0, ref = path.length; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        t = ttl * i / path.length;
        path[i] = [start[0] + t * this.translate * start[1], start[1], this.zAtTime(start[2], t)];
      }
      return path;
    };

    return Shear;

  })(Dynamics);

  ScaleInOutShear = (function(superClass) {
    extend1(ScaleInOutShear, superClass);

    function ScaleInOutShear(extents, opts) {
      this.makePath = bind(this.makePath, this);
      this.makeReference = bind(this.makeReference, this);
      this.shaderParams = bind(this.shaderParams, this);
      this.distr = bind(this.distr, this);
      this.newDistr = bind(this.newDistr, this);
      this.origDistr = bind(this.origDistr, this);
      var a, ref, λ;
      ScaleInOutShear.__super__.constructor.call(this, extents, opts);
      if (opts == null) {
        opts = {};
      }
      this.translate = (ref = opts.translate) != null ? ref : randSign() * linLerp(0.2, 2.0)(Math.random());
      λ = this.scale;
      a = this.translate;
      this.makeStepMat(λ, λ * a, 0, λ);
      this.logScale = Math.log(λ);
      this.xOfY = function(r, y) {
        return y * (r + a * Math.log(y) / this.logScale);
      };
      this.lerpR = function(t) {
        return Math.tan((t - 0.5) * π);
      };
      this.lerpR2 = function(t) {
        return Math.tan((t / 0.99 + 0.005 - 0.5) * π);
      };
    }

    ScaleInOutShear.prototype.origDistr = function() {
      return this.distr(this.lerpY);
    };

    ScaleInOutShear.prototype.newDistr = function() {
      return this.distr(this.lerpYNew);
    };

    ScaleInOutShear.prototype.distr = function(distribution) {
      var r, s, x, y;
      r = this.lerpR2(Math.random());
      y = distribution(Math.random());
      x = this.xOfY(r, y);
      s = randSign();
      return [s * x, s * y];
    };

    ScaleInOutShear.prototype.shaderParams = function() {
      return ScaleInOutShear.__super__.shaderParams.call(this, {
        code: shearShader,
        uniforms: {
          scale: {
            type: 'f',
            value: this.scale
          },
          translate: {
            type: 'f',
            value: this.translate
          }
        }
      });
    };

    ScaleInOutShear.prototype.makeReference = function() {
      var i, j, k, m, numLines, r, ref, ret, row, x, y;
      ret = [];
      numLines = 40;
      for (i = k = 1, ref = numLines; 1 <= ref ? k < ref : k > ref; i = 1 <= ref ? ++k : --k) {
        r = this.lerpR(i / numLines);
        row = [];
        for (j = m = 0; m < 100; j = ++m) {
          y = this.lerpY(j / 100);
          x = this.xOfY(r, y);
          row.push([[x, y], [-x, -y]]);
        }
        ret.push(row);
      }
      return ret;
    };

    ScaleInOutShear.prototype.makePath = function(start, path) {
      var a, i, k, ref, ss, t, ttl, λ;
      ttl = this.timeToLeave(start);
      if (!isFinite(ttl)) {
        ttl = 25;
      }
      λ = this.scale;
      a = this.translate;
      for (i = k = 0, ref = path.length; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
        t = ttl * i / path.length;
        ss = Math.pow(λ, t);
        path[i] = [ss * start[0] + ss * a * t * start[1], ss * start[1], this.zAtTime(start[2], t)];
      }
      return path;
    };

    return ScaleInOutShear;

  })(Dynamics);

  ScaleOutShear = (function(superClass) {
    extend1(ScaleOutShear, superClass);

    ScaleOutShear.prototype.descr = function() {
      return "Scale-out shear";
    };

    function ScaleOutShear(extents1, opts) {
      var ref, ref1;
      this.extents = extents1;
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      if (opts == null) {
        opts = {};
      }
      this.scale = (ref = opts.scale) != null ? ref : linLerp(1 / 0.7, 1 / 0.3)(Math.random());
      this.lerpY = expLerp(0.01 / this.scale, this.extents.y);
      this.lerpYNew = expLerp(0.01 / this.scale, 0.01);
      ScaleOutShear.__super__.constructor.call(this, this.extents, opts);
      this.inverse = (ref1 = opts != null ? opts.inverse : void 0) != null ? ref1 : new ScaleInShear(this.extents, {
        translate: -this.translate,
        scale: 1 / this.scale,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    ScaleOutShear.prototype.needsResetXY = function(x, y) {
      return Math.abs(y) > this.extents.y;
    };

    ScaleOutShear.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(this.extents.y) - Math.log(Math.abs(y))) / this.logScale;
    };

    return ScaleOutShear;

  })(ScaleInOutShear);

  ScaleInShear = (function(superClass) {
    extend1(ScaleInShear, superClass);

    ScaleInShear.prototype.descr = function() {
      return "Scale-in shear";
    };

    function ScaleInShear(extents1, opts) {
      var ref, ref1;
      this.extents = extents1;
      this.timeToLeaveXY = bind(this.timeToLeaveXY, this);
      this.needsResetXY = bind(this.needsResetXY, this);
      if (opts == null) {
        opts = {};
      }
      this.scale = (ref = opts.scale) != null ? ref : linLerp(0.3, 0.7)(Math.random());
      this.lerpY = expLerp(0.01, this.extents.y / this.scale);
      this.lerpYNew = expLerp(this.extents.y, this.extents.y / this.scale);
      ScaleInShear.__super__.constructor.call(this, this.extents, opts);
      this.inverse = (ref1 = opts != null ? opts.inverse : void 0) != null ? ref1 : new ScaleOutShear(this.extents, {
        translate: -this.translate,
        scale: 1 / this.scale,
        inverse: this,
        scaleZ: this.invScaleZ
      });
    }

    ScaleInShear.prototype.needsResetXY = function(x, y) {
      return Math.abs(y) < .01;
    };

    ScaleInShear.prototype.timeToLeaveXY = function(x, y) {
      return (Math.log(0.01) - Math.log(Math.abs(y))) / this.logScale;
    };

    return ScaleInShear;

  })(ScaleInOutShear);

  window.dynamics = {};

  window.dynamics.DynamicsView = DynamicsView;

  window.dynamics.Controller = Controller;

  window.dynamics.Circle = Circle;

  window.dynamics.SpiralIn = SpiralIn;

  window.dynamics.SpiralOut = SpiralOut;

  window.dynamics.Hyperbolas = Hyperbolas;

  window.dynamics.Attract = Attract;

  window.dynamics.Repel = Repel;

  window.dynamics.AttractLine = AttractLine;

  window.dynamics.RepelLine = RepelLine;

  window.dynamics.Shear = Shear;

  window.dynamics.ScaleOutShear = ScaleOutShear;

  window.dynamics.ScaleInShear = ScaleInShear;

}).call(this);
