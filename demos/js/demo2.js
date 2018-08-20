(function() {
  "use strict";
  var Animation, Caption, ClipCube, Color, Demo, Demo2D, Draggable, Grid, LabeledPoints, LabeledVectors, LinearCombo, MathboxAnimation, OrbitControls, Popup, Subspace, URLParams, View, addEvents, clipFragment, clipShader, color, e, eigenvalues, evExpr, extend, groupControls, makeTvec, name, noShadeFragment, opts, orthogonalize, palette, rowReduce, setTvec, shadeFragment, supportsPassive, urlParams,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    slice = [].slice,
    extend1 = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  palette = {
    red: [0.8941, 0.1020, 0.1098],
    blue: [0.2157, 0.4941, 0.7216],
    green: [0.3020, 0.6863, 0.2902],
    violet: [0.5961, 0.3059, 0.6392],
    orange: [1.0000, 0.4980, 0.0000],
    yellow: [0.7000, 0.7000, 0.0000],
    brown: [0.6510, 0.3373, 0.1569],
    pink: [0.9686, 0.5059, 0.7490]
  };

  Color = (function() {
    function Color() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      this.darken = bind(this.darken, this);
      this.brighten = bind(this.brighten, this);
      this.fromHSL = bind(this.fromHSL, this);
      this.hsl = bind(this.hsl, this);
      this.three = bind(this.three, this);
      this.arr = bind(this.arr, this);
      this.str = bind(this.str, this);
      this.hex = bind(this.hex, this);
      this.set = bind(this.set, this);
      this.r = 1;
      this.g = 1;
      this.b = 1;
      if (args.length > 0) {
        this.set.apply(this, args);
      }
    }

    Color.prototype.set = function() {
      var args, color, hex, ref, style;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (args.length === 3 || args.length === 4) {
        this.r = args[0], this.g = args[1], this.b = args[2];
      } else if (args[0] instanceof Array) {
        this.set.apply(this, args[0]);
      } else if (args[0] instanceof Color || args[0] instanceof THREE.Color) {
        ref = [args[0].r, args[0].g, args[0].b], this.r = ref[0], this.g = ref[1], this.b = ref[2];
      } else if (typeof args[0] === 'number') {
        hex = Math.floor(args[0]);
        this.r = (hex >> 16 & 255) / 255;
        this.g = (hex >> 8 & 255) / 255;
        this.b = (hex & 255) / 255;
      } else if (typeof args[0] === 'string') {
        style = args[0];
        if (/^rgb\((\d+), ?(\d+), ?(\d+)\)$/i.test(style)) {
          color = /^rgb\((\d+), ?(\d+), ?(\d+)\)$/i.exec(style);
          this.r = Math.min(255, parseInt(color[1], 10)) / 255;
          this.g = Math.min(255, parseInt(color[2], 10)) / 255;
          this.b = Math.min(255, parseInt(color[3], 10)) / 255;
        } else if (/^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$/i.test(style)) {
          color = /^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$/i.exec(style);
          this.r = Math.min(100, parseInt(color[1], 10)) / 100;
          this.g = Math.min(100, parseInt(color[2], 10)) / 100;
          this.b = Math.min(100, parseInt(color[3], 10)) / 100;
        } else if (/^\#([0-9a-f]{6})$/i.test(style)) {
          color = /^\#([0-9a-f]{6})$/i.exec(style);
          this.set(parseInt(color[1], 16));
        } else if (/^\#([0-9a-f])([0-9a-f])([0-9a-f])$/i.test(style)) {
          color = /^\#([0-9a-f])([0-9a-f])([0-9a-f])$/i.exec(style);
          this.set(parseInt(color[1] + color[1] + color[2] + color[2] + color[3] + color[3], 16));
        } else if (/^(\w+)$/i.test(style)) {
          this.set(palette[style]);
        }
      }
      this.r = Math.min(1.0, Math.max(0.0, this.r));
      this.g = Math.min(1.0, Math.max(0.0, this.g));
      this.b = Math.min(1.0, Math.max(0.0, this.b));
      return this;
    };

    Color.prototype.hex = function() {
      return (this.r * 255) << 16 ^ (this.g * 255) << 8 ^ (this.b * 255) << 0;
    };

    Color.prototype.str = function() {
      return '#' + ('000000' + this.hex().toString(16)).slice(-6);
    };

    Color.prototype.arr = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (args.length === 0) {
        return [this.r, this.g, this.b];
      }
      return [this.r, this.g, this.b, args[0]];
    };

    Color.prototype.three = function() {
      return new THREE.Color(this.r, this.g, this.b);
    };

    Color.prototype.hsl = function() {
      var d, h, l, max, min, s;
      max = Math.max(this.r, this.g, this.b);
      min = Math.min(this.r, this.g, this.b);
      l = (max + min) / 2;
      h = s = 0;
      if (max !== min) {
        d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
          case this.r:
            h = (this.g - this.b) / d + (this.g < this.b ? 6 : 0);
            break;
          case this.g:
            h = (this.b - this.r) / d + 2;
            break;
          case this.b:
            h = (this.r - this.g) / d + 4;
        }
        h /= 6;
      }
      return [h, s, l];
    };

    Color.prototype.fromHSL = function(h, s, l) {
      var hue2rgb, p, q;
      h = Math.min(1.0, Math.max(0.0, h));
      s = Math.min(1.0, Math.max(0.0, s));
      l = Math.min(1.0, Math.max(0.0, l));
      if (s === 0) {
        this.r = this.g = this.b = l;
      } else {
        hue2rgb = function(p, q, t) {
          if (t < 0) {
            t += 1;
          }
          if (t > 1) {
            t -= 1;
          }
          if (t < 1 / 6) {
            return p + (q - p) * 6 * t;
          }
          if (t < 1 / 2) {
            return q;
          }
          if (t < 2 / 3) {
            return p + (q - p) * (2 / 3 - t) * 6;
          }
          return p;
        };
        q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        p = 2 * l - q;
        this.r = hue2rgb(p, q, h + 1 / 3);
        this.g = hue2rgb(p, q, h);
        this.b = hue2rgb(p, q, h - 1 / 3);
      }
      return this;
    };

    Color.prototype.brighten = function(pct) {
      var h, l, ref, s;
      ref = this.hsl(), h = ref[0], s = ref[1], l = ref[2];
      return new Color().fromHSL(h, s, l + pct);
    };

    Color.prototype.darken = function(pct) {
      return this.brighten(-pct);
    };

    return Color;

  })();

  supportsPassive = false;

  try {
    opts = Object.defineProperty({}, 'passive', {
      get: function() {
        return supportsPassive = true;
      }
    });
    window.addEventListener("testPassive", null, opts);
    window.removeEventListener("testPassive", null, opts);
  } catch (error) {
    e = error;
  }

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

  orthogonalize = (function() {
    var tmpVec;
    tmpVec = null;
    return function(vec1, vec2) {
      if (tmpVec == null) {
        tmpVec = new THREE.Vector3();
      }
      tmpVec.copy(vec1.normalize());
      return vec2.sub(tmpVec.multiplyScalar(vec2.dot(vec1))).normalize();
    };
  })();

  makeTvec = function(vec) {
    var ref, ret;
    if (vec instanceof THREE.Vector3) {
      return vec;
    }
    ret = new THREE.Vector3();
    return ret.set(vec[0], vec[1], (ref = vec[2]) != null ? ref : 0);
  };

  setTvec = function(orig, vec) {
    var ref;
    if (vec instanceof THREE.Vector3) {
      return orig.copy(vec);
    } else {
      return orig.set(vec[0], vec[1], (ref = vec[2]) != null ? ref : 0);
    }
  };

  rowReduce = function(M, opts) {
    var E, c, col, colBasis, f, fn, i, i1, j, j1, k, k1, l1, lastPivot, len, len1, m, m1, maxEl, maxRow, n, n1, noPivots, nulBasis, o1, orig, p1, pivot, pivots, q1, r1, ref, ref1, ref10, ref11, ref12, ref13, ref14, ref15, ref16, ref17, ref18, ref19, ref2, ref20, ref21, ref22, ref23, ref24, ref25, ref3, ref4, ref5, ref6, ref7, ref8, ref9, row, s1, t1, u, v, z, ε;
    orig = (function() {
      var len, results, u;
      results = [];
      for (u = 0, len = M.length; u < len; u++) {
        c = M[u];
        results.push(c.slice());
      }
      return results;
    })();
    if (opts == null) {
      opts = {};
    }
    m = (ref = opts.rows) != null ? ref : M[0].length;
    n = (ref1 = opts.cols) != null ? ref1 : M.length;
    ε = (ref2 = opts.epsilon) != null ? ref2 : 1e-5;
    row = 0;
    col = 0;
    pivots = [];
    lastPivot = -1;
    noPivots = [];
    colBasis = [];
    nulBasis = [];
    E = (function() {
      var ref3, results, u;
      results = [];
      for (u = 0, ref3 = m; 0 <= ref3 ? u < ref3 : u > ref3; 0 <= ref3 ? u++ : u--) {
        results.push((function() {
          var ref4, results1, v;
          results1 = [];
          for (v = 0, ref4 = m; 0 <= ref4 ? v < ref4 : v > ref4; 0 <= ref4 ? v++ : v--) {
            results1.push(0);
          }
          return results1;
        })());
      }
      return results;
    })();
    for (i = u = 0, ref3 = m; 0 <= ref3 ? u < ref3 : u > ref3; i = 0 <= ref3 ? ++u : --u) {
      E[i][i] = 1;
    }
    while (true) {
      if (col === n) {
        break;
      }
      if (row === m) {
        for (k = v = ref4 = col, ref5 = n; ref4 <= ref5 ? v < ref5 : v > ref5; k = ref4 <= ref5 ? ++v : --v) {
          noPivots.push(k);
        }
        break;
      }
      maxEl = Math.abs(M[col][row]);
      maxRow = row;
      for (k = z = ref6 = row + 1, ref7 = m; ref6 <= ref7 ? z < ref7 : z > ref7; k = ref6 <= ref7 ? ++z : --z) {
        if (Math.abs(M[col][k]) > maxEl) {
          maxEl = Math.abs(M[col][k]);
          maxRow = k;
        }
      }
      if (Math.abs(maxEl) < ε) {
        noPivots.push(col);
        col++;
        continue;
      }
      for (k = i1 = 0, ref8 = n; 0 <= ref8 ? i1 < ref8 : i1 > ref8; k = 0 <= ref8 ? ++i1 : --i1) {
        ref9 = [M[k][row], M[k][maxRow]], M[k][maxRow] = ref9[0], M[k][row] = ref9[1];
      }
      for (k = j1 = 0, ref10 = m; 0 <= ref10 ? j1 < ref10 : j1 > ref10; k = 0 <= ref10 ? ++j1 : --j1) {
        ref11 = [E[k][row], E[k][maxRow]], E[k][maxRow] = ref11[0], E[k][row] = ref11[1];
      }
      pivots.push([row, col]);
      colBasis.push(orig[col]);
      lastPivot = row;
      pivot = M[col][row];
      for (k = k1 = ref12 = row + 1, ref13 = m; ref12 <= ref13 ? k1 < ref13 : k1 > ref13; k = ref12 <= ref13 ? ++k1 : --k1) {
        c = M[col][k] / pivot;
        if (c === 0) {
          continue;
        }
        M[col][k] = 0;
        for (j = l1 = ref14 = col + 1, ref15 = n; ref14 <= ref15 ? l1 < ref15 : l1 > ref15; j = ref14 <= ref15 ? ++l1 : --l1) {
          M[j][k] -= c * M[j][row];
        }
        for (j = m1 = 0, ref16 = m; 0 <= ref16 ? m1 < ref16 : m1 > ref16; j = 0 <= ref16 ? ++m1 : --m1) {
          E[j][k] -= c * E[j][row];
        }
      }
      row++;
      col++;
    }
    ref17 = pivots.reverse();
    for (n1 = 0, len = ref17.length; n1 < len; n1++) {
      ref18 = ref17[n1], row = ref18[0], col = ref18[1];
      pivot = M[col][row];
      M[col][row] = 1;
      for (k = o1 = ref19 = col + 1, ref20 = n; ref19 <= ref20 ? o1 < ref20 : o1 > ref20; k = ref19 <= ref20 ? ++o1 : --o1) {
        M[k][row] /= pivot;
      }
      for (k = p1 = 0, ref21 = m; 0 <= ref21 ? p1 < ref21 : p1 > ref21; k = 0 <= ref21 ? ++p1 : --p1) {
        E[k][row] /= pivot;
      }
      for (k = q1 = 0, ref22 = row; 0 <= ref22 ? q1 < ref22 : q1 > ref22; k = 0 <= ref22 ? ++q1 : --q1) {
        c = M[col][k];
        M[col][k] = 0;
        for (j = r1 = ref23 = col + 1, ref24 = n; ref23 <= ref24 ? r1 < ref24 : r1 > ref24; j = ref23 <= ref24 ? ++r1 : --r1) {
          M[j][k] -= c * M[j][row];
        }
        for (j = s1 = 0, ref25 = m; 0 <= ref25 ? s1 < ref25 : s1 > ref25; j = 0 <= ref25 ? ++s1 : --s1) {
          E[j][k] -= c * E[j][row];
        }
      }
    }
    fn = function() {
      var len2, ref26, u1, vec;
      vec = (function() {
        var ref26, results, u1;
        results = [];
        for (u1 = 0, ref26 = n; 0 <= ref26 ? u1 < ref26 : u1 > ref26; 0 <= ref26 ? u1++ : u1--) {
          results.push(0);
        }
        return results;
      })();
      vec[i] = 1;
      for (u1 = 0, len2 = pivots.length; u1 < len2; u1++) {
        ref26 = pivots[u1], row = ref26[0], col = ref26[1];
        vec[col] = -M[i][row];
      }
      return nulBasis.push(vec);
    };
    for (t1 = 0, len1 = noPivots.length; t1 < len1; t1++) {
      i = noPivots[t1];
      fn();
    }
    f = function(b, ret) {
      var Eb, len2, ref26, ref27, ref28, ref29, ref30, u1, v1, w1, x, x1;
      Eb = [];
      for (i = u1 = 0, ref26 = m; 0 <= ref26 ? u1 < ref26 : u1 > ref26; i = 0 <= ref26 ? ++u1 : --u1) {
        x = 0;
        for (j = v1 = 0, ref27 = m; 0 <= ref27 ? v1 < ref27 : v1 > ref27; j = 0 <= ref27 ? ++v1 : --v1) {
          x += E[j][i] * b[j];
        }
        Eb.push(x);
      }
      for (i = w1 = ref28 = lastPivot + 1, ref29 = m; ref28 <= ref29 ? w1 < ref29 : w1 > ref29; i = ref28 <= ref29 ? ++w1 : --w1) {
        if (Math.abs(Eb[i]) > ε) {
          return null;
        }
      }
      if (ret == null) {
        ret = (function() {
          var ref30, results, x1;
          results = [];
          for (x1 = 0, ref30 = n; 0 <= ref30 ? x1 < ref30 : x1 > ref30; 0 <= ref30 ? x1++ : x1--) {
            results.push(0);
          }
          return results;
        })();
      }
      for (x1 = 0, len2 = pivots.length; x1 < len2; x1++) {
        ref30 = pivots[x1], row = ref30[0], col = ref30[1];
        ret[col] = Eb[row];
      }
      return ret;
    };
    return [nulBasis, colBasis, E, f];
  };

  eigenvalues = function(mat) {
    var a, b, c, charPoly, d, f, g, h, i, ref, ref1, ref2, ref3, ref4;
    switch (mat.length) {
      case 2:
        (ref = mat[0], a = ref[0], b = ref[1]), (ref1 = mat[1], c = ref1[0], d = ref1[1]);
        charPoly = [a * d - b * c, -a - d, 1];
        return findRoots(1, -a - d, a * d - b * c);
      case 3:
        (ref2 = mat[0], a = ref2[0], b = ref2[1], c = ref2[2]), (ref3 = mat[1], d = ref3[0], e = ref3[1], f = ref3[2]), (ref4 = mat[2], g = ref4[0], h = ref4[1], i = ref4[2]);
        return findRoots(1, -a - e - i, a * e + a * i + e * i - b * d - c * g - f * h, -a * e * i - b * f * g - c * d * h + a * f * h + b * d * i + c * e * g);
    }
  };

  addEvents = function(cls) {
    cls.prototype.on = function(types, callback) {
      var base, len, type, u;
      if (!(types instanceof Array)) {
        types = [types];
      }
      if (this._listeners == null) {
        this._listeners = {};
      }
      for (u = 0, len = types.length; u < len; u++) {
        type = types[u];
        if ((base = this._listeners)[type] == null) {
          base[type] = [];
        }
        this._listeners[type].push(callback);
      }
      return this;
    };
    cls.prototype.off = function(types, callback) {
      var idx, len, ref, ref1, type, u;
      if (!(types instanceof Array)) {
        types = [types];
      }
      for (u = 0, len = types.length; u < len; u++) {
        type = types[u];
        idx = (ref = this._listeners) != null ? (ref1 = ref[type]) != null ? ref1.indexOf(callback) : void 0 : void 0;
        if ((idx != null) && idx >= 0) {
          this._listeners[type].splice(idx, 1);
        }
      }
      return this;
    };
    return cls.prototype.trigger = function(event) {
      var callback, len, listeners, ref, ref1, type, u;
      type = event.type;
      event.target = this;
      listeners = (ref = this._listeners) != null ? (ref1 = ref[type]) != null ? ref1.slice() : void 0 : void 0;
      if (listeners == null) {
        return;
      }
      for (u = 0, len = listeners.length; u < len; u++) {
        callback = listeners[u];
        callback.call(this, event, this);
        if (callback.triggerOnce) {
          this.off(type, callback);
        }
      }
      return this;
    };
  };

  clipShader = "// Enable STPQ mapping\n#define POSITION_STPQ\nvoid getPosition(inout vec4 xyzw, inout vec4 stpq) {\n  // Store XYZ per vertex in STPQ\nstpq = xyzw;\n}";

  clipFragment = "// Enable STPQ mapping\n#define POSITION_STPQ\nuniform float range;\nuniform int hilite;\n\nvec4 getColor(vec4 rgba, inout vec4 stpq) {\n    stpq = abs(stpq);\n    rgba = getShadedColor(rgba);\n\n    // Discard pixels outside of clip box\n    if(stpq.x > range || stpq.y > range || stpq.z > range)\n        discard;\n\n    if(hilite != 0 &&\n       (range - stpq.x < range * 0.002 ||\n        range - stpq.y < range * 0.002 ||\n        range - stpq.z < range * 0.002)) {\n        rgba.xyz *= 10.0;\n        rgba.w = 1.0;\n    }\n\n    return rgba;\n}";

  noShadeFragment = "vec4 getShadedColor(vec4 rgba) {\n    return rgba;\n}";

  shadeFragment = "varying vec3 vNormal;\nvarying vec3 vLight;\nvarying vec3 vPosition;\n\nvec3 offSpecular(vec3 color) {\n  vec3 c = 1.0 - color;\n  return 1.0 - c * c;\n}\n\nvec4 getShadedColor(vec4 rgba) {\n\n  vec3 color = rgba.xyz;\n  vec3 color2 = offSpecular(rgba.xyz);\n\n  vec3 normal = normalize(vNormal);\n  vec3 light = normalize(vLight);\n  vec3 position = normalize(vPosition);\n\n  float side    = gl_FrontFacing ? -1.0 : 1.0;\n  float cosine  = side * dot(normal, light);\n  float diffuse = mix(max(0.0, cosine), .5 + .5 * cosine, .1);\n\n  vec3  halfLight = normalize(light + position);\n	float cosineHalf = max(0.0, side * dot(normal, halfLight));\n	float specular = pow(cosineHalf, 16.0);\n\n	return vec4(color * (diffuse * .9 + .05) + .25 * color2 * specular, rgba.a);\n}";

  evExpr = function(expr) {
    try {
      return exprEval.Parser.evaluate(expr);
    } catch (error) {
      return 0;
    }
  };

  URLParams = (function() {
    function URLParams() {
      this.get = bind(this.get, this);
      var decode, match, pl, query, search;
      pl = /\+/g;
      search = /([^&=]+)=?([^&]*)/g;
      decode = function(s) {
        return decodeURIComponent(s.replace(pl, " "));
      };
      query = window.location.search.substring(1);
      while (match = search.exec(query)) {
        this[decode(match[1])] = decode(match[2]);
      }
    }

    URLParams.prototype.get = function(key, type, def) {
      var val;
      if (type == null) {
        type = 'str';
      }
      if (def == null) {
        def = void 0;
      }
      val = this[key];
      if (val != null) {
        switch (type) {
          case 'str':
            return val;
          case 'str[]':
            return val.split(',');
          case 'float':
            return evExpr(val);
          case 'float[]':
            return val.split(',').map(evExpr);
          case 'int':
            return parseInt(val);
          case 'int[]':
            return val.split(',').map(parseInt);
          case 'bool':
            if (val === 'true' || val === 'yes' || val === 'on') {
              return true;
            }
            if (val === 'false' || val === 'no' || val === 'off') {
              return false;
            }
            if (def != null) {
              return def;
            }
            return false;
          case 'matrix':
            return val.split(':').map(function(s) {
              return s.split(',').map(evExpr);
            });
        }
      } else {
        if (def != null) {
          return def;
        }
        switch (type) {
          case 'str':
            return '';
          case 'float':
            return 0.0;
          case 'int':
            return 0;
          case 'str[]':
          case 'float[]':
          case 'int[]':
          case 'matrix':
            return [];
          case 'bool':
            return false;
        }
      }
    };

    return URLParams;

  })();

  urlParams = new URLParams();

  OrbitControls = (function() {
    function OrbitControls(camera, domElement) {
      this.camera = camera;
      this.touchEnd = bind(this.touchEnd, this);
      this.touchMove = bind(this.touchMove, this);
      this.touchStart = bind(this.touchStart, this);
      this.onKeyDown = bind(this.onKeyDown, this);
      this.onMouseWheel = bind(this.onMouseWheel, this);
      this.onMouseUp = bind(this.onMouseUp, this);
      this.onMouseMove = bind(this.onMouseMove, this);
      this.onMouseDown = bind(this.onMouseDown, this);
      this.reset = bind(this.reset, this);
      this.update = bind(this.update, this);
      this.pan = bind(this.pan, this);
      this.panUp = bind(this.panUp, this);
      this.panLeft = bind(this.panLeft, this);
      this.dollyOut = bind(this.dollyOut, this);
      this.dollyIn = bind(this.dollyIn, this);
      this.getZoomScale = bind(this.getZoomScale, this);
      this.rotateUp = bind(this.rotateUp, this);
      this.rotateLeft = bind(this.rotateLeft, this);
      this.getAutoRotationAngle = bind(this.getAutoRotationAngle, this);
      this.updateCamera = bind(this.updateCamera, this);
      this.enable = bind(this.enable, this);
      THREE.EventDispatcher.prototype.apply(this);
      this.domElement = domElement != null ? domElement : document;
      this.enabled = true;
      this.target = new THREE.Vector3();
      this.noZoom = false;
      this.zoomSpeed = 1.0;
      this.minDistance = 0;
      this.maxDistance = 2e308;
      this.noRotate = false;
      this.rotateSpeed = 1.0;
      this.noPan = false;
      this.keyPanSpeed = 7.0;
      this.autoRotate = false;
      this.autoRotateSpeed = 2.0;
      this.minPolarAngle = 0;
      this.maxPolarAngle = Math.PI;
      this.noKeys = true;
      this.keys = {
        LEFT: 37,
        UP: 38,
        RIGHT: 39,
        BOTTOM: 40
      };
      this.clones = [];
      this.EPS = 0.000001;
      this.rotateStart = new THREE.Vector2();
      this.rotateEnd = new THREE.Vector2();
      this.rotateDelta = new THREE.Vector2();
      this.panStart = new THREE.Vector2();
      this.panEnd = new THREE.Vector2();
      this.panDelta = new THREE.Vector2();
      this.panOffset = new THREE.Vector3();
      this.panCurrent = new THREE.Vector3();
      this.offset = new THREE.Vector3();
      this.dollyStart = new THREE.Vector2();
      this.dollyEnd = new THREE.Vector2();
      this.dollyDelta = new THREE.Vector2();
      this.phiDelta = 0;
      this.thetaDelta = 0;
      this.scale = 1;
      this.lastPosition = new THREE.Vector3();
      this.STATE = {
        NONE: -1,
        ROTATE: 0,
        DOLLY: 1,
        PAN: 2,
        TOUCH_ROTATE: 3,
        TOUCH_DOLLY: 4,
        TOUCH_PAN: 5
      };
      this.state = this.STATE.NONE;
      this.target0 = this.target.clone();
      this.position0 = this.camera.position.clone();
      this.updateCamera();
      this.changeEvent = {
        type: 'change'
      };
      this.startEvent = {
        type: 'start'
      };
      this.endEvent = {
        type: 'end'
      };
      this.domElement.addEventListener('contextmenu', (function(event) {
        return event.preventDefault();
      }), false);
      this.domElement.addEventListener('mousedown', this.onMouseDown, false);
      this.domElement.addEventListener('mousewheel', this.onMouseWheel, false);
      this.domElement.addEventListener('touchstart', this.touchStart, false);
      window.addEventListener('keydown', this.onKeyDown, false);
      this.update();
    }

    OrbitControls.prototype.enable = function(val) {
      var de, ref, ref1;
      this.enabled = val;
      if (!this.enabled) {
        de = document.documentElement;
        if ((ref = this.state) === this.STATE.ROTATE || ref === this.STATE.DOLLY || ref === this.STATE.PAN) {
          de.removeEventListener('mousemove', this.onMouseMove, false);
          de.removeEventListener('mouseup', this.onMouseUp, false);
          this.dispatchEvent(this.endEvent);
        } else if ((ref1 = this.state) === this.STATE.TOUCH_ROTATE || ref1 === this.STATE.TOUCH_DOLLY || ref1 === this.STATE.TOUCH_PAN) {
          de.removeEventListener('touchend', this.touchEnd, false);
          de.removeEventListener('touchmove', this.touchMove, false);
          de.removeEventListener('touchcancel', this.touchEnd, false);
          this.dispatchEvent(this.endEvent);
        }
        return this.state = this.STATE.NONE;
      }
    };

    OrbitControls.prototype.updateCamera = function() {
      this.quat = new THREE.Quaternion().setFromUnitVectors(this.camera.up, new THREE.Vector3(0, 1, 0));
      this.quatInverse = this.quat.clone().inverse();
      return this.update();
    };

    OrbitControls.prototype.getAutoRotationAngle = function() {
      return 2 * Math.PI / 60 / 60 * this.autoRotateSpeed;
    };

    OrbitControls.prototype.rotateLeft = function(angle) {
      return this.thetaDelta -= angle != null ? angle : this.getAutoRotationAngle();
    };

    OrbitControls.prototype.rotateUp = function(angle) {
      return this.phiDelta -= angle != null ? angle : this.getAutoRotationAngle();
    };

    OrbitControls.prototype.getZoomScale = function() {
      return Math.pow(0.95, this.zoomSpeed);
    };

    OrbitControls.prototype.dollyIn = function(dollyScale) {
      return this.scale /= dollyScale != null ? dollyScale : this.getZoomScale();
    };

    OrbitControls.prototype.dollyOut = function(dollyScale) {
      return this.scale *= dollyScale != null ? dollyScale : this.getZoomScale();
    };

    OrbitControls.prototype.panLeft = function(distance) {
      var te;
      te = this.camera.matrix.elements;
      this.panOffset.set(te[0], te[1], te[2]);
      this.panOffset.multiplyScalar(-distance);
      return this.panCurrent.add(this.panOffset);
    };

    OrbitControls.prototype.panUp = function(distance) {
      var te;
      te = this.camera.matrix.elements;
      this.panOffset.set(te[4], te[5], te[6]);
      this.panOffset.multiplyScalar(distance);
      return this.panCurrent.add(this.panOffset);
    };

    OrbitControls.prototype.pan = function(deltaX, deltaY) {
      var element, offset, position, targetDistance;
      element = this.domElement === document ? document.body : this.domElement;
      if (this.camera.fov != null) {
        position = this.camera.position;
        offset = position.clone().sub(this.target);
        targetDistance = offset.length();
        targetDistance *= Math.tan(this.camera.fov / 2 * Math.PI / 180.0);
        this.panLeft(2 * deltaX * targetDistance / element.clientHeight);
        return this.panUp(2 * deltaY * targetDistance / element.clientHeight);
      } else if (this.camera.top != null) {
        this.panLeft(deltaX * (this.camera.right - this.camera.left) / element.clientWidth);
        return this.panUp(deltaY * (this.camera.top - this.camera.bottom) / element.clientHeight);
      } else {
        return console.warn('WARNING: OrbitControls encountered unknown camera type; pan disabled');
      }
    };

    OrbitControls.prototype.update = function(delta, state) {
      var clone, len, panCurrent, phi, phiDelta, position, radius, ref, scale, theta, thetaDelta, u;
      if (state == null) {
        ref = this.clones;
        for (u = 0, len = ref.length; u < len; u++) {
          clone = ref[u];
          clone.update(0, this);
        }
      }
      if (state == null) {
        state = this;
      }
      thetaDelta = state.thetaDelta, phiDelta = state.phiDelta, panCurrent = state.panCurrent, scale = state.scale;
      position = this.camera.position;
      this.offset.copy(position).sub(this.target);
      this.offset.applyQuaternion(this.quat);
      theta = Math.atan2(this.offset.x, this.offset.z);
      phi = Math.atan2(Math.sqrt(this.offset.x * this.offset.x + this.offset.z * this.offset.z), this.offset.y);
      if (this.autoRotate) {
        this.rotateLeft(this.getAutoRotationAngle());
      }
      theta += thetaDelta;
      phi += phiDelta;
      phi = Math.max(this.minPolarAngle, Math.min(this.maxPolarAngle, phi));
      phi = Math.max(this.EPS, Math.min(Math.PI - this.EPS, phi));
      radius = this.offset.length() * scale;
      radius = Math.max(this.minDistance, Math.min(this.maxDistance, radius));
      this.target.add(panCurrent);
      this.offset.x = radius * Math.sin(phi) * Math.sin(theta);
      this.offset.y = radius * Math.cos(phi);
      this.offset.z = radius * Math.sin(phi) * Math.cos(theta);
      this.offset.applyQuaternion(this.quatInverse);
      position.copy(this.target).add(this.offset);
      this.camera.lookAt(this.target);
      this.thetaDelta = 0;
      this.phiDelta = 0;
      this.scale = 1;
      this.panCurrent.set(0, 0, 0);
      if (this.lastPosition.distanceToSquared(position) > this.EPS) {
        this.dispatchEvent(this.changeEvent);
        return this.lastPosition.copy(position);
      }
    };

    OrbitControls.prototype.reset = function() {
      this.state = this.STATE.NONE;
      this.target.copy(this.target0);
      this.camera.position.copy(this.position0);
      return this.update();
    };

    OrbitControls.prototype.onMouseDown = function(event) {
      if (!this.enabled) {
        return;
      }
      event.preventDefault();
      switch (event.button) {
        case 0:
          if (this.noRotate) {
            return;
          }
          this.state = this.STATE.ROTATE;
          this.rotateStart.set(event.clientX, event.clientY);
          break;
        case 1:
          if (this.noZoom) {
            return;
          }
          this.state = this.STATE.DOLLY;
          this.dollyStart.set(event.clientX, event.clientY);
          break;
        case 2:
          if (this.noPan) {
            return;
          }
          this.state = this.STATE.PAN;
          this.panStart.set(event.clientX, event.clientY);
      }
      document.documentElement.addEventListener('mousemove', this.onMouseMove, false);
      document.documentElement.addEventListener('mouseup', this.onMouseUp, false);
      return this.dispatchEvent(this.startEvent);
    };

    OrbitControls.prototype.onMouseMove = function(event) {
      var element;
      if (!this.enabled) {
        return;
      }
      event.preventDefault();
      element = this.domElement === document ? document.body : this.domElement;
      switch (this.state) {
        case this.STATE.ROTATE:
          if (this.noRotate) {
            return;
          }
          this.rotateEnd.set(event.clientX, event.clientY);
          this.rotateDelta.subVectors(this.rotateEnd, this.rotateStart);
          this.rotateLeft(2 * Math.PI * this.rotateDelta.x / element.clientWidth * this.rotateSpeed);
          this.rotateUp(2 * Math.PI * this.rotateDelta.y / element.clientHeight * this.rotateSpeed);
          this.rotateStart.copy(this.rotateEnd);
          break;
        case this.STATE.DOLLY:
          if (this.noZoom) {
            return;
          }
          this.dollyEnd.set(event.clientX, event.clientY);
          this.dollyDelta.subVectors(this.dollyEnd, this.dollyStart);
          if (this.dollyDelta.y > 0) {
            this.dollyIn();
          } else {
            this.dollyOut();
          }
          this.dollyStart.copy(this.dollyEnd);
          break;
        case this.STATE.PAN:
          if (this.noPan) {
            return;
          }
          this.panEnd.set(event.clientX, event.clientY);
          this.panDelta.subVectors(this.panEnd, this.panStart);
          this.pan(this.panDelta.x, this.panDelta.y);
          this.panStart.copy(this.panEnd);
          break;
        default:
          return;
      }
      return this.update();
    };

    OrbitControls.prototype.onMouseUp = function() {
      if (!this.enabled) {
        return;
      }
      document.documentElement.removeEventListener('mousemove', this.onMouseMove, false);
      document.documentElement.removeEventListener('mouseup', this.onMouseUp, false);
      this.dispatchEvent(this.endEvent);
      return this.state = this.STATE.NONE;
    };

    OrbitControls.prototype.onMouseWheel = function(event) {
      var delta, ref;
      if (!(this.enabled && !this.noZoom)) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      delta = (ref = event.wheelDelta) != null ? ref : -event.detail;
      if (delta > 0) {
        this.dollyOut();
      } else {
        this.dollyIn();
      }
      this.update();
      this.dispatchEvent(this.startEvent);
      return this.dispatchEvent(this.endEvent);
    };

    OrbitControls.prototype.onKeyDown = function(event) {
      if (!this.enabled || this.noKeys || this.noPan) {
        return;
      }
      switch (event.keyCode) {
        case this.keys.UP:
          this.pan(0, this.keyPanSpeed);
          break;
        case this.keys.BOTTOM:
          this.pan(0, -this.keyPanSpeed);
          break;
        case this.keys.LEFT:
          this.pan(this.keyPanSpeed, 0);
          break;
        case this.keys.RIGHT:
          this.pan(-this.keyPanSpeed, 0);
          break;
        default:
          return;
      }
      return this.update();
    };

    OrbitControls.prototype.touchStart = function(event) {
      var distance, dx, dy;
      if (!this.enabled) {
        return;
      }
      event.preventDefault();
      switch (event.touches.length) {
        case 1:
          if (this.noRotate) {
            return;
          }
          this.state = this.STATE.TOUCH_ROTATE;
          this.rotateStart.set(event.touches[0].clientX, event.touches[0].clientY);
          break;
        case 2:
          if (this.noZoom) {
            return;
          }
          this.state = this.STATE.TOUCH_DOLLY;
          dx = event.touches[0].clientX - event.touches[1].clientX;
          dy = event.touches[0].clientY - event.touches[1].clientY;
          distance = Math.sqrt(dx * dx + dy * dy);
          this.dollyStart.set(0, distance);
          break;
        case 3:
          if (this.noPan) {
            return;
          }
          this.state = this.STATE.TOUCH_PAN;
          this.panStart.set(event.touches[0].clientX, event.touches[0].clientY);
          break;
        default:
          this.state = this.STATE.NONE;
      }
      document.documentElement.addEventListener('touchend', this.touchEnd, false);
      document.documentElement.addEventListener('touchmove', this.touchMove, false);
      document.documentElement.addEventListener('touchcancel', this.touchEnd, false);
      return this.dispatchEvent(this.startEvent);
    };

    OrbitControls.prototype.touchMove = function(event) {
      var distance, dx, dy, element;
      if (!this.enabled) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      element = this.domElement === document ? document.body : this.domElement;
      switch (event.touches.length) {
        case 1:
          if (this.noRotate || this.state !== this.STATE.TOUCH_ROTATE) {
            return;
          }
          this.rotateEnd.set(event.touches[0].clientX, event.touches[0].clientY);
          this.rotateDelta.subVectors(this.rotateEnd, this.rotateStart);
          this.rotateLeft(2 * Math.PI * this.rotateDelta.x / element.clientWidth * this.rotateSpeed);
          this.rotateUp(2 * Math.PI * this.rotateDelta.y / element.clientHeight * this.rotateSpeed);
          this.rotateStart.copy(this.rotateEnd);
          break;
        case 2:
          if (this.noZoom || this.state !== this.STATE.TOUCH_DOLLY) {
            return;
          }
          dx = event.touches[0].clientX - event.touches[1].clientX;
          dy = event.touches[0].clientY - event.touches[1].clientY;
          distance = Math.sqrt(dx * dx + dy * dy);
          this.dollyEnd.set(0, distance);
          this.dollyDelta.subVectors(this.dollyEnd, this.dollyStart);
          if (this.dollyDelta.y > 0) {
            this.dollyOut();
          } else {
            this.dollyIn();
          }
          this.dollyStart.copy(this.dollyEnd);
          break;
        case 3:
          if (this.noPan || this.state !== this.STATE.TOUCH_PAN) {
            return;
          }
          this.panEnd.set(event.touches[0].clientX, event.touches[0].clientY);
          this.panDelta.subVectors(this.panEnd, this.panStart);
          this.pan(this.panDelta.x, this.panDelta.y);
          this.panStart.copy(this.panEnd);
          break;
        default:
          this.touchEnd();
          return;
      }
      return this.update();
    };

    OrbitControls.prototype.touchEnd = function() {
      if (!this.enabled) {
        return;
      }
      document.documentElement.removeEventListener('touchend', this.touchEnd, false);
      document.documentElement.removeEventListener('touchmove', this.touchMove, false);
      document.documentElement.removeEventListener('touchcancel', this.touchEnd, false);
      this.dispatchEvent(this.endEvent);
      return this.state = this.STATE.NONE;
    };

    return OrbitControls;

  })();

  groupControls = function() {
    var demos, i, j, ref, results, u;
    demos = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    demos = demos.filter(function(x) {
      return x.three.controls != null;
    });
    results = [];
    for (i = u = 0, ref = demos.length; 0 <= ref ? u < ref : u > ref; i = 0 <= ref ? ++u : --u) {
      results.push((function() {
        var ref1, results1, v;
        results1 = [];
        for (j = v = 0, ref1 = demos.length; 0 <= ref1 ? v < ref1 : v > ref1; j = 0 <= ref1 ? ++v : --v) {
          if (j === i) {
            continue;
          }
          results1.push(demos[i].three.controls.clones.push(demos[j].three.controls));
        }
        return results1;
      })());
    }
    return results;
  };

  Animation = (function() {
    function Animation() {
      this.running = false;
    }

    Animation.prototype.start = function() {
      this.running = true;
      return this;
    };

    Animation.prototype.stop = function() {
      if (!this.running) {
        return;
      }
      this.running = false;
      this.trigger({
        type: 'stopped'
      });
      return this;
    };

    Animation.prototype.done = function() {
      this.running = false;
      this.trigger({
        type: 'done'
      });
      return this;
    };

    return Animation;

  })();

  addEvents(Animation);

  MathboxAnimation = (function(superClass) {
    extend1(MathboxAnimation, superClass);

    function MathboxAnimation(element, opts1) {
      var base, k;
      this.opts = opts1;
      this.opts.target = element;
      if ((base = this.opts).to == null) {
        base.to = Math.max.apply(null, (function() {
          var results;
          results = [];
          for (k in this.opts.script) {
            results.push(k);
          }
          return results;
        }).call(this));
      }
      MathboxAnimation.__super__.constructor.apply(this, arguments);
    }

    MathboxAnimation.prototype.start = function() {
      this._play = this.opts.target.play(this.opts);
      this._play.on('play.done', (function(_this) {
        return function() {
          _this._play.remove();
          delete _this._play;
          return _this.done();
        };
      })(this));
      return MathboxAnimation.__super__.start.apply(this, arguments);
    };

    MathboxAnimation.prototype.stop = function() {
      var ref;
      if ((ref = this._play) != null) {
        ref.remove();
      }
      delete this._play;
      return MathboxAnimation.__super__.stop.apply(this, arguments);
    };

    return MathboxAnimation;

  })(Animation);

  Subspace = (function() {
    function Subspace(opts1) {
      var i, ref, ref1, ref2, u;
      this.opts = opts1;
      this.updateDim = bind(this.updateDim, this);
      this.setVisibility = bind(this.setVisibility, this);
      this.draw = bind(this.draw, this);
      this.contains = bind(this.contains, this);
      this.complementFull = bind(this.complementFull, this);
      this.complement = bind(this.complement, this);
      this.project = bind(this.project, this);
      this.update = bind(this.update, this);
      this.setVecs = bind(this.setVecs, this);
      this.onDimChange = (ref = this.opts.onDimChange) != null ? ref : function() {};
      this.ortho = [new THREE.Vector3(), new THREE.Vector3()];
      this.zeroThreshold = (ref1 = this.opts.zeroThreshold) != null ? ref1 : 0.00001;
      this.numVecs = this.opts.vectors.length;
      this.vectors = [];
      for (i = u = 0, ref2 = this.numVecs; 0 <= ref2 ? u < ref2 : u > ref2; i = 0 <= ref2 ? ++u : --u) {
        this.vectors[i] = makeTvec(this.opts.vectors[i]);
      }
      this.mesh = this.opts.mesh;
      this.tmpVec1 = new THREE.Vector3();
      this.tmpVec2 = new THREE.Vector3();
      this.tmpVec3 = new THREE.Vector3();
      this.drawn = false;
      this.dim = -1;
      this.update();
    }

    Subspace.prototype.setVecs = function(vecs) {
      var i, ref, u;
      for (i = u = 0, ref = this.numVecs; 0 <= ref ? u < ref : u > ref; i = 0 <= ref ? ++u : --u) {
        setTvec(this.vectors[i], vecs[i]);
      }
      return this.update();
    };

    Subspace.prototype.update = function() {
      var cross, oldDim, ortho1, ortho2, ref, ref1, vec1, vec1Zero, vec2, vec2Zero, vec3;
      ref = this.vectors, vec1 = ref[0], vec2 = ref[1], vec3 = ref[2];
      ref1 = this.ortho, ortho1 = ref1[0], ortho2 = ref1[1];
      cross = this.tmpVec1;
      oldDim = this.dim;
      switch (this.numVecs) {
        case 0:
          this.dim = 0;
          break;
        case 1:
          if (vec1.lengthSq() <= this.zeroThreshold) {
            this.dim = 0;
          } else {
            this.dim = 1;
            ortho1.copy(vec1).normalize();
          }
          break;
        case 2:
          cross.crossVectors(vec1, vec2);
          if (cross.lengthSq() <= this.zeroThreshold) {
            vec1Zero = vec1.lengthSq() <= this.zeroThreshold;
            vec2Zero = vec2.lengthSq() <= this.zeroThreshold;
            if (vec1Zero && vec2Zero) {
              this.dim = 0;
            } else if (vec1Zero) {
              this.dim = 1;
              ortho1.copy(vec2).normalize();
            } else {
              this.dim = 1;
              ortho1.copy(vec1).normalize();
            }
          } else {
            this.dim = 2;
            orthogonalize(ortho1.copy(vec1), ortho2.copy(vec2));
          }
          break;
        case 3:
          cross.crossVectors(vec1, vec2);
          if (Math.abs(cross.dot(vec3)) > this.zeroThreshold) {
            this.dim = 3;
          } else {
            if (cross.lengthSq() > this.zeroThreshold) {
              this.dim = 2;
              orthogonalize(ortho1.copy(vec1), ortho2.copy(vec2));
            } else {
              cross.crossVectors(vec1, vec3);
              if (cross.lengthSq() > this.zeroThreshold) {
                this.dim = 2;
                orthogonalize(ortho1.copy(vec1), ortho2.copy(vec3));
              } else {
                cross.crossVectors(vec2, vec3);
                if (cross.lengthSq() > this.zeroThreshold) {
                  this.dim = 2;
                  orthogonalize(ortho1.copy(vec2), ortho2.copy(vec3));
                } else if (vec1.lengthSq() > this.zeroThreshold) {
                  this.dim = 1;
                  ortho1.copy(vec1);
                } else if (vec2.lengthSq() > this.zeroThreshold) {
                  this.dim = 1;
                  ortho1.copy(vec2);
                } else if (vec3.lengthSq() > this.zeroThreshold) {
                  this.dim = 1;
                  ortho1.copy(vec3);
                } else {
                  this.dim = 0;
                }
              }
            }
          }
      }
      if (oldDim !== this.dim) {
        return this.updateDim(oldDim);
      }
    };

    Subspace.prototype.project = function(vec, projected) {
      var ortho1, ortho2, ref;
      vec = setTvec(this.tmpVec1, vec);
      ref = this.ortho, ortho1 = ref[0], ortho2 = ref[1];
      switch (this.dim) {
        case 0:
          return projected.set(0, 0, 0);
        case 1:
          return projected.copy(ortho1).multiplyScalar(ortho1.dot(vec));
        case 2:
          projected.copy(ortho1).multiplyScalar(ortho1.dot(vec));
          this.tmpVec2.copy(ortho2).multiplyScalar(ortho2.dot(vec));
          return projected.add(this.tmpVec2);
        case 3:
          return projected.copy(vec);
      }
    };

    Subspace.prototype.complement = function() {
      var a, b, c, cross, ortho1, ortho2, ref, ref1;
      ref = this.ortho, ortho1 = ref[0], ortho2 = ref[1];
      switch (this.dim) {
        case 0:
          return [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
        case 1:
          ref1 = [ortho1.x, ortho1.y, ortho1.z], a = ref1[0], b = ref1[1], c = ref1[2];
          if (Math.abs(a) < this.zeroThreshold) {
            if (Math.abs(b) < this.zeroThreshold) {
              return [[1, 0, 0], [0, 1, 0]];
            }
            if (Math.abs(c) < this.zeroThreshold) {
              return [[1, 0, 0], [0, 0, 1]];
            }
            return [[1, 0, 0], [0, c, -b]];
          }
          setTvec(this.tmpVec1, [b, -a, 0]);
          setTvec(this.tmpVec2, [c, 0, -a]);
          orthogonalize(this.tmpVec1, this.tmpVec2);
          return [[this.tmpVec1.x, this.tmpVec1.y, this.tmpVec1.z], [this.tmpVec2.x, this.tmpVec2.y, this.tmpVec2.z]];
        case 2:
          cross = this.tmpVec1;
          cross.crossVectors(ortho1, ortho2);
          return [[cross.x, cross.y, cross.z]];
        case 3:
          return [];
      }
    };

    Subspace.prototype.complementFull = function(twod) {
      var vecs;
      vecs = this.complement().concat([[0, 0, 0], [0, 0, 0], [0, 0, 0]]);
      if (twod) {
        vecs[0][2] = 0;
        vecs[1][2] = 0;
        return [vecs[0], vecs[1]];
      }
      return vecs.slice(0, 3);
    };

    Subspace.prototype.contains = function(vec) {
      this.project(vec, this.tmpVec3);
      setTvec(this.tmpVec1, vec);
      this.tmpVec1.sub(this.tmpVec3);
      return this.tmpVec1.lengthSq() < this.zeroThreshold;
    };

    Subspace.prototype.draw = function(view) {
      var color, lineOpts, live, name, pointOpts, ref, ref1, ref2, ref3, ref4, ref5, ref6, surfaceOpts;
      name = (ref = this.opts.name) != null ? ref : 'subspace';
      this.range = (ref1 = this.opts.range) != null ? ref1 : 10.0;
      color = (ref2 = this.opts.color) != null ? ref2 : new Color("violet");
      live = (ref3 = this.opts.live) != null ? ref3 : true;
      if (color instanceof Color) {
        color = color.arr();
      }
      this.range *= 2;
      pointOpts = {
        id: name + "-point",
        classes: [name],
        color: color,
        opacity: 1.0,
        size: 15,
        visible: false
      };
      extend(pointOpts, (ref4 = this.opts.pointOpts) != null ? ref4 : {});
      lineOpts = {
        id: name + "-line",
        classes: [name],
        color: color,
        opacity: 1.0,
        stroke: 'solid',
        width: 5,
        visible: false
      };
      extend(lineOpts, (ref5 = this.opts.lineOpts) != null ? ref5 : {});
      surfaceOpts = {
        id: name + "-plane",
        classes: [name],
        color: color,
        opacity: 0.25,
        lineX: false,
        lineY: false,
        fill: true,
        visible: false
      };
      extend(surfaceOpts, (ref6 = this.opts.surfaceOpts) != null ? ref6 : {});
      if (live || this.dim === 0) {
        view.array({
          channels: 3,
          width: 1,
          live: live,
          data: [[0, 0, 0]]
        });
        this.point = view.point(pointOpts);
      }
      if ((live && this.numVecs >= 1) || this.dim === 1) {
        view.array({
          channels: 3,
          width: 2,
          live: live,
          expr: (function(_this) {
            return function(emit, i) {
              if (i === 0) {
                return emit(-_this.ortho[0].x * _this.range, -_this.ortho[0].y * _this.range, -_this.ortho[0].z * _this.range);
              } else {
                return emit(_this.ortho[0].x * _this.range, _this.ortho[0].y * _this.range, _this.ortho[0].z * _this.range);
              }
            };
          })(this)
        });
        this.line = view.line(lineOpts);
      }
      if ((live && this.numVecs >= 2) || this.dim === 2) {
        if (!this.opts.noPlane) {
          view.matrix({
            channels: 3,
            width: 2,
            height: 2,
            live: live,
            expr: (function(_this) {
              return function(emit, i, j) {
                var sign1, sign2;
                sign1 = i === 0 ? -1 : 1;
                sign2 = j === 0 ? -1 : 1;
                return emit(sign1 * _this.ortho[0].x * _this.range + sign2 * _this.ortho[1].x * _this.range, sign1 * _this.ortho[0].y * _this.range + sign2 * _this.ortho[1].y * _this.range, sign1 * _this.ortho[0].z * _this.range + sign2 * _this.ortho[1].z * _this.range);
              };
            })(this)
          });
          this.plane = view.surface(surfaceOpts);
        }
      }
      this.objects = [this.point, this.line, this.plane];
      this.drawn = true;
      return this.updateDim(-1);
    };

    Subspace.prototype.setVisibility = function(val) {
      var ref, ref1;
      if (!this.drawn) {
        return;
      }
      if ((ref = this.objects[this.dim]) != null) {
        ref.set('visible', val);
      }
      if (this.dim === 3) {
        return (ref1 = this.mesh) != null ? ref1.material.visible = val : void 0;
      }
    };

    Subspace.prototype.updateDim = function(oldDim) {
      var ref;
      this.onDimChange(this);
      if (!this.drawn) {
        return;
      }
      if (oldDim >= 0 && oldDim < 3 && (this.objects[oldDim] != null)) {
        this.objects[oldDim].set('visible', false);
      }
      if (this.dim < 3 && (this.objects[this.dim] != null)) {
        this.objects[this.dim].set('visible', true);
      }
      return (ref = this.mesh) != null ? ref.material.visible = this.dim === 3 : void 0;
    };

    return Subspace;

  })();

  LinearCombo = (function() {
    function LinearCombo(view, opts) {
      var c, coeffVars, coeffs, col, color1, color2, color3, colors, combine, i, labelOpts, labels, len, len1, lineOpts, name, numVecs, pointColor, pointOpts, ref, ref1, ref2, ref3, ref4, ref5, u, v, vec, vector1, vector2, vector3, vectors;
      name = (ref = opts.name) != null ? ref : 'lincombo';
      vectors = opts.vectors;
      colors = opts.colors;
      pointColor = (ref1 = opts.pointColor) != null ? ref1 : new Color("red");
      labels = opts.labels;
      coeffs = opts.coeffs;
      coeffVars = (ref2 = opts.coeffVars) != null ? ref2 : ['x', 'y', 'z'];
      if (pointColor instanceof Color) {
        pointColor = pointColor.arr();
      }
      c = function(i) {
        return coeffs[coeffVars[i]];
      };
      lineOpts = {
        classes: [name],
        points: "#" + name + "-points",
        colors: "#" + name + "-colors",
        color: "white",
        opacity: 0.75,
        width: 3,
        zIndex: 1
      };
      extend(lineOpts, (ref3 = opts.lineOpts) != null ? ref3 : {});
      pointOpts = {
        classes: [name],
        points: "#" + name + "-combo",
        color: pointColor,
        zIndex: 2,
        size: 15
      };
      extend(pointOpts, (ref4 = opts.pointOpts) != null ? ref4 : {});
      labelOpts = {
        classes: [name],
        outline: 0,
        background: [0, 0, 0, 0],
        color: pointColor,
        offset: [0, 25],
        zIndex: 3,
        size: 15
      };
      extend(labelOpts, (ref5 = opts.labelOpts) != null ? ref5 : {});
      numVecs = vectors.length;
      for (u = 0, len = vectors.length; u < len; u++) {
        vec = vectors[u];
        if (vec[2] == null) {
          vec[2] = 0;
        }
      }
      vector1 = vectors[0];
      vector2 = vectors[1];
      vector3 = vectors[2];
      for (i = v = 0, len1 = colors.length; v < len1; i = ++v) {
        col = colors[i];
        if (col instanceof Color) {
          colors[i] = col.arr(1);
        }
      }
      color1 = colors[0];
      color2 = colors[1];
      color3 = colors[2];
      switch (numVecs) {
        case 1:
          combine = (function(_this) {
            return function() {
              return _this.combo = [vector1[0] * c(0), vector1[1] * c(0), vector1[2] * c(0)];
            };
          })(this);
          view.array({
            id: name + "-points",
            channels: 3,
            width: 2,
            items: 1,
            expr: function(emit, i) {
              if (i === 0) {
                return emit(0, 0, 0);
              } else {
                return emit(vector1[0] * c(0), vector1[1] * c(0), vector1[2] * c(0));
              }
            }
          }).array({
            id: name + "-colors",
            channels: 4,
            width: 1,
            items: 1,
            data: [color1]
          }).array({
            id: name + "-combo",
            channels: 3,
            width: 1,
            expr: function(emit) {
              return emit.apply(null, combine());
            }
          });
          break;
        case 2:
          combine = (function(_this) {
            return function() {
              return _this.combo = [vector1[0] * c(0) + vector2[0] * c(1), vector1[1] * c(0) + vector2[1] * c(1), vector1[2] * c(0) + vector2[2] * c(1)];
            };
          })(this);
          view.array({
            id: name + "-points",
            channels: 3,
            width: 2,
            items: 4,
            expr: function(emit, i) {
              var vec1, vec12, vec2;
              vec1 = [vector1[0] * c(0), vector1[1] * c(0), vector1[2] * c(0)];
              vec2 = [vector2[0] * c(1), vector2[1] * c(1), vector2[2] * c(1)];
              vec12 = [vec1[0] + vec2[0], vec1[1] + vec2[1], vec1[2] + vec2[2]];
              if (i === 0) {
                emit(0, 0, 0);
                emit(0, 0, 0);
                emit.apply(null, vec1);
                return emit.apply(null, vec2);
              } else {
                emit.apply(null, vec1);
                emit.apply(null, vec2);
                emit.apply(null, vec12);
                return emit.apply(null, vec12);
              }
            }
          }).array({
            id: name + "-colors",
            channels: 4,
            width: 2,
            items: 4,
            data: [color1, color2, color2, color1, color1, color2, color2, color1]
          }).array({
            id: name + "-combo",
            channels: 3,
            width: 1,
            expr: function(emit) {
              return emit.apply(null, combine());
            }
          });
          break;
        case 3:
          combine = (function(_this) {
            return function() {
              return _this.combo = [vector1[0] * c(0) + vector2[0] * c(1) + vector3[0] * c(2), vector1[1] * c(0) + vector2[1] * c(1) + vector3[1] * c(2), vector1[2] * c(0) + vector2[2] * c(1) + vector3[2] * c(2)];
            };
          })(this);
          view.array({
            id: name + "-points",
            channels: 3,
            width: 2,
            items: 12,
            expr: function(emit, i) {
              var vec1, vec12, vec123, vec13, vec2, vec23, vec3;
              vec1 = [vector1[0] * c(0), vector1[1] * c(0), vector1[2] * c(0)];
              vec2 = [vector2[0] * c(1), vector2[1] * c(1), vector2[2] * c(1)];
              vec3 = [vector3[0] * c(2), vector3[1] * c(2), vector3[2] * c(2)];
              vec12 = [vec1[0] + vec2[0], vec1[1] + vec2[1], vec1[2] + vec2[2]];
              vec13 = [vec1[0] + vec3[0], vec1[1] + vec3[1], vec1[2] + vec3[2]];
              vec23 = [vec2[0] + vec3[0], vec2[1] + vec3[1], vec2[2] + vec3[2]];
              vec123 = [vec1[0] + vec2[0] + vec3[0], vec1[1] + vec2[1] + vec3[1], vec1[2] + vec2[2] + vec3[2]];
              if (i === 0) {
                emit(0, 0, 0);
                emit(0, 0, 0);
                emit(0, 0, 0);
                emit.apply(null, vec1);
                emit.apply(null, vec1);
                emit.apply(null, vec2);
                emit.apply(null, vec2);
                emit.apply(null, vec3);
                emit.apply(null, vec3);
                emit.apply(null, vec12);
                emit.apply(null, vec13);
                return emit.apply(null, vec23);
              } else {
                emit.apply(null, vec1);
                emit.apply(null, vec2);
                emit.apply(null, vec3);
                emit.apply(null, vec12);
                emit.apply(null, vec13);
                emit.apply(null, vec12);
                emit.apply(null, vec23);
                emit.apply(null, vec13);
                emit.apply(null, vec23);
                emit.apply(null, vec123);
                emit.apply(null, vec123);
                return emit.apply(null, vec123);
              }
            }
          }).array({
            id: name + "-colors",
            channels: 4,
            width: 2,
            items: 12,
            data: [color1, color2, color3, color2, color3, color1, color3, color1, color2, color3, color2, color1, color1, color2, color3, color2, color3, color1, color3, color1, color2, color3, color2, color1]
          }).array({
            id: name + "-combo",
            channels: 3,
            width: 1,
            expr: function(emit) {
              return emit.apply(null, combine());
            }
          });
      }
      view.line(lineOpts).point(pointOpts);
      if (labels != null) {
        view.text({
          live: true,
          width: 1,
          expr: function(emit) {
            var add, b, cc, ret;
            ret = c(0).toFixed(2) + labels[0];
            if (numVecs >= 2) {
              b = Math.abs(c(1));
              add = c(1) >= 0 ? "+" : "-";
              ret += add + b.toFixed(2) + labels[1];
            }
            if (numVecs >= 3) {
              cc = Math.abs(c(2));
              add = c(2) >= 0 ? "+" : "-";
              ret += add + cc.toFixed(2) + labels[2];
            }
            return emit(ret);
          }
        }).label(labelOpts);
      }
      this.combine = combine;
    }

    return LinearCombo;

  })();

  Grid = (function() {
    function Grid(view, opts) {
      var doLines, len, lineOpts, live, name, numLines, numVecs, perSide, ref, ref1, ref2, ref3, ref4, ticksOpts, totLines, u, vec, vector1, vector2, vector3, vectors;
      name = (ref = opts.name) != null ? ref : "vecgrid";
      vectors = opts.vectors;
      numLines = (ref1 = opts.numLines) != null ? ref1 : 40;
      live = (ref2 = opts.live) != null ? ref2 : true;
      ticksOpts = {
        id: name,
        opacity: 1,
        size: 20,
        normal: false,
        color: 0xcc0000
      };
      extend(ticksOpts, (ref3 = opts.ticksOpts) != null ? ref3 : {});
      if (ticksOpts["color"] instanceof Color) {
        ticksOpts["color"] = ticksOpts["color"].arr();
      }
      lineOpts = {
        id: name,
        opacity: .5,
        stroke: 'solid',
        width: 2,
        color: 0x880000,
        zBias: 2
      };
      extend(lineOpts, (ref4 = opts.lineOpts) != null ? ref4 : {});
      if (lineOpts["color"] instanceof Color) {
        lineOpts["color"] = lineOpts["color"].arr();
      }
      numVecs = vectors.length;
      for (u = 0, len = vectors.length; u < len; u++) {
        vec = vectors[u];
        if (vec[2] == null) {
          vec[2] = 0;
        }
      }
      vector1 = vectors[0], vector2 = vectors[1], vector3 = vectors[2];
      perSide = numLines / 2;
      if (numVecs === 1) {
        view.array({
          channels: 3,
          live: live,
          width: numLines + 1,
          expr: function(emit, i) {
            i -= perSide;
            return emit(i * vector1[0], i * vector1[1], i * vector1[2]);
          }
        });
        this.ticks = view.ticks(ticksOpts);
        return;
      }
      if (numVecs === 2) {
        totLines = (numLines + 1) * 2;
        doLines = function(emit, i) {
          var j, ref5, ref6, results, start, v;
          results = [];
          for (j = v = ref5 = -perSide, ref6 = perSide; ref5 <= ref6 ? v <= ref6 : v >= ref6; j = ref5 <= ref6 ? ++v : --v) {
            start = i === 0 ? -perSide : perSide;
            emit(start * vector1[0] + j * vector2[0], start * vector1[1] + j * vector2[1], start * vector1[2] + j * vector2[2]);
            results.push(emit(start * vector2[0] + j * vector1[0], start * vector2[1] + j * vector1[1], start * vector2[2] + j * vector1[2]));
          }
          return results;
        };
      }
      if (numVecs === 3) {
        totLines = (numLines + 1) * (numLines + 1) * 3;
        doLines = function(emit, i) {
          var j, k, ref5, ref6, results, start, v;
          results = [];
          for (j = v = ref5 = -perSide, ref6 = perSide; ref5 <= ref6 ? v <= ref6 : v >= ref6; j = ref5 <= ref6 ? ++v : --v) {
            results.push((function() {
              var ref7, ref8, results1, z;
              results1 = [];
              for (k = z = ref7 = -perSide, ref8 = perSide; ref7 <= ref8 ? z <= ref8 : z >= ref8; k = ref7 <= ref8 ? ++z : --z) {
                start = i === 0 ? -perSide : perSide;
                emit(start * vector1[0] + j * vector2[0] + k * vector3[0], start * vector1[1] + j * vector2[1] + k * vector3[1], start * vector1[2] + j * vector2[2] + k * vector3[2]);
                emit(start * vector2[0] + j * vector1[0] + k * vector3[0], start * vector2[1] + j * vector1[1] + k * vector3[1], start * vector2[2] + j * vector1[2] + k * vector3[2]);
                results1.push(emit(start * vector3[0] + j * vector1[0] + k * vector2[0], start * vector3[1] + j * vector1[1] + k * vector2[1], start * vector3[2] + j * vector1[2] + k * vector2[2]));
              }
              return results1;
            })());
          }
          return results;
        };
      }
      view.array({
        channels: 3,
        live: live,
        width: 2,
        items: totLines,
        expr: doLines
      });
      this.lines = view.line(lineOpts);
    }

    return Grid;

  })();

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

  Popup = (function() {
    function Popup(mathbox, text) {
      this.mathbox = mathbox;
      this.div = this.mathbox._context.overlays.div;
      this.popup = document.createElement('div');
      this.popup.className = "overlay-popup";
      this.popup.style.display = 'none';
      if (text != null) {
        this.popup.innerHTML = text;
      }
      this.div.appendChild(this.popup);
    }

    Popup.prototype.show = function(text) {
      if (text != null) {
        this.popup.innerHTML = text;
      }
      return this.popup.style.display = '';
    };

    Popup.prototype.hide = function() {
      return this.popup.style.display = 'none';
    };

    return Popup;

  })();

  View = (function() {
    function View(mathbox, opts1) {
      var axisOpts, doAxes, doAxisLabels, doGrid, gridOpts, i, labelOpts, ref, ref1, ref10, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, u, viewOpts, viewRange, viewScale;
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
        color: "black",
        opacity: 0.5,
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
        color: "black",
        opacity: 0.25,
        zBias: 0
      };
      extend(gridOpts, (ref6 = this.opts.gridOpts) != null ? ref6 : {});
      doAxisLabels = ((ref7 = this.opts.axisLabels) != null ? ref7 : true) && doAxes;
      labelOpts = {
        classes: [this.name + "-axes"],
        size: 20,
        color: "black",
        opacity: 0.5,
        outline: 0,
        background: [0, 0, 0, 0],
        offset: [0, 0]
      };
      extend(labelOpts, (ref8 = this.opts.labelOpts) != null ? ref8 : {});
      if (this.numDims === 3) {
        viewOpts = {
          range: viewRange,
          scale: viewScale,
          id: this.name + "-view"
        };
      } else {
        viewOpts = {
          range: viewRange,
          scale: viewScale,
          id: this.name + "-view"
        };
      }
      extend(viewOpts, (ref9 = this.opts.viewOpts) != null ? ref9 : {});
      this.view = this.mathbox.cartesian(viewOpts);
      if (doAxes) {
        for (i = u = 1, ref10 = this.numDims; 1 <= ref10 ? u <= ref10 : u >= ref10; i = 1 <= ref10 ? ++u : --u) {
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
              var arr, j, ref11, v;
              arr = [];
              for (j = v = 0, ref11 = _this.numDims; 0 <= ref11 ? v < ref11 : v > ref11; j = 0 <= ref11 ? ++v : --v) {
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
      var getMatrix, hiliteColor, hiliteOpts, i, indices, len, name, point, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, rtt, size, u;
      this.view = view1;
      this.opts = opts1;
      this.getIndexAt = bind(this.getIndexAt, this);
      this.post = bind(this.post, this);
      this.touchEnd = bind(this.touchEnd, this);
      this.touchMove = bind(this.touchMove, this);
      this.touchStart = bind(this.touchStart, this);
      this.movePoint = bind(this.movePoint, this);
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
      this.postDrag = (ref3 = this.opts.postDrag) != null ? ref3 : function() {};
      this.is2D = (ref4 = this.opts.is2D) != null ? ref4 : false;
      hiliteColor = (ref5 = this.opts.hiliteColor) != null ? ref5 : [0, .5, .5, .75];
      this.eyeMatrix = (ref6 = this.opts.eyeMatrix) != null ? ref6 : new THREE.Matrix4();
      getMatrix = (ref7 = this.opts.getMatrix) != null ? ref7 : function(d) {
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
      extend(hiliteOpts, (ref8 = this.opts.hiliteOpts) != null ? ref8 : {});
      this.three = this.view._context.api.three;
      this.canvas = this.three.canvas;
      this.camera = this.view._context.api.select("camera")[0].controller.camera;
      this.enabled = true;
      ref9 = this.points;
      for (u = 0, len = ref9.length; u < len; u++) {
        point = ref9[u];
        if (point[2] == null) {
          point[2] = 0;
        }
      }
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
        var ref10, results, v;
        results = [];
        for (i = v = 0, ref10 = this.points.length; 0 <= ref10 ? v < ref10 : v > ref10; i = 0 <= ref10 ? ++v : --v) {
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
            if (!_this.enabled) {
              emit(1, 1, 1, 0);
              return;
            }
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
      this.canvas.addEventListener('touchstart', this.touchStart, false);
      this.three.on('post', this.post);
    }

    Draggable.prototype.onMouseDown = function(event) {
      if (this.hovered < 0 || !this.enabled) {
        return;
      }
      event.preventDefault();
      this.dragging = this.hovered;
      return this.activePoint = this.points[this.dragging];
    };

    Draggable.prototype.onMouseMove = function(event) {
      var dpr;
      dpr = window.devicePixelRatio;
      this.mouse = [event.offsetX * dpr, event.offsetY * dpr];
      this.hovered = this.getIndexAt(this.mouse[0], this.mouse[1]);
      if (this.dragging < 0 || !this.enabled) {
        return;
      }
      event.preventDefault();
      return this.movePoint(event.offsetX, event.offsetY);
    };

    Draggable.prototype.onMouseUp = function(event) {
      if (this.dragging < 0 || !this.enabled) {
        return;
      }
      event.preventDefault();
      this.dragging = -1;
      return this.activePoint = void 0;
    };

    Draggable.prototype.movePoint = function(x, y) {
      var screenX, screenY;
      screenX = x / this.canvas.offsetWidth * 2 - 1.0;
      screenY = -(y / this.canvas.offsetHeight * 2 - 1.0);
      this.projected.set(this.activePoint[0], this.activePoint[1], this.activePoint[2]).applyMatrix4(this.viewMatrix);
      this.matrix.multiplyMatrices(this.camera.projectionMatrix, this.eyeMatrix);
      this.matrix.multiply(this.matrixInv.getInverse(this.camera.matrixWorld));
      this.projected.applyProjection(this.matrix);
      this.vector.set(screenX, screenY, this.projected.z);
      this.vector.applyProjection(this.matrixInv.getInverse(this.matrix));
      this.vector.applyMatrix4(this.viewMatrixInv);
      if (this.is2D) {
        this.vector.z = 0;
      }
      this.onDrag.call(this, this.vector);
      this.activePoint[0] = this.vector.x;
      this.activePoint[1] = this.vector.y;
      this.activePoint[2] = this.vector.z;
      return this.postDrag.call(this);
    };

    Draggable.prototype.touchStart = function(event) {
      var dpr, offsetX, offsetY, rect, touch;
      if (!(event.touches.length === 1 && event.targetTouches.length === 1)) {
        return;
      }
      if (!this.enabled) {
        return;
      }
      touch = event.targetTouches[0];
      rect = event.target.getBoundingClientRect();
      offsetX = touch.pageX - rect.left;
      offsetY = touch.pageY - rect.top;
      dpr = window.devicePixelRatio;
      this.dragging = this.getIndexAt(offsetX * dpr, offsetY * dpr);
      if (this.dragging < 0) {
        return;
      }
      this.activePoint = this.points[this.dragging];
      event.preventDefault();
      this.canvas.addEventListener('touchend', this.touchEnd, false);
      this.canvas.addEventListener('touchmove', this.touchMove, false);
      return this.canvas.addEventListener('touchcancel', this.touchEnd, false);
    };

    Draggable.prototype.touchMove = function(event) {
      var offsetX, offsetY, rect, touch;
      if (!(event.touches.length === 1 && event.targetTouches.length === 1)) {
        return;
      }
      if (this.dragging < 0 || !this.enabled) {
        return;
      }
      event.preventDefault();
      touch = event.targetTouches[0];
      rect = event.target.getBoundingClientRect();
      offsetX = touch.pageX - rect.left;
      offsetY = touch.pageY - rect.top;
      return this.movePoint(offsetX, offsetY);
    };

    Draggable.prototype.touchEnd = function(event) {
      if (this.dragging < 0 || !this.enabled) {
        return;
      }
      event.preventDefault();
      this.dragging = -1;
      return this.activePoint = void 0;
    };

    Draggable.prototype.post = function() {
      var ref, ref1;
      if (!this.enabled) {
        if ((ref = this.three.controls) != null) {
          ref.enable(true);
        }
        return;
      }
      if (this.dragging >= 0) {
        this.canvas.style.cursor = 'pointer';
      } else if (this.hovered >= 0) {
        this.canvas.style.cursor = 'pointer';
      } else if (this.three.controls) {
        this.canvas.style.cursor = 'move';
      } else {
        this.canvas.style.cursor = '';
      }
      return (ref1 = this.three.controls) != null ? ref1.enable(this.hovered < 0 && this.dragging < 0) : void 0;
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
      var color, draw, fragment, hilite, material, pass, range, ref, ref1, ref2, ref3, ref4, ref5, ref6, shaded;
      this.view = view1;
      this.opts = opts1;
      if (this.opts == null) {
        this.opts = {};
      }
      range = (ref = this.opts.range) != null ? ref : 1.0;
      pass = (ref1 = this.opts.pass) != null ? ref1 : "world";
      hilite = (ref2 = this.opts.hilite) != null ? ref2 : true;
      draw = (ref3 = this.opts.draw) != null ? ref3 : false;
      shaded = (ref4 = this.opts.shaded) != null ? ref4 : false;
      this.three = this.view._context.api.three;
      this.camera = this.view._context.api.select("camera")[0].controller.camera;
      if (draw) {
        material = (ref5 = this.opts.material) != null ? ref5 : new THREE.MeshBasicMaterial();
        if (this.opts.color != null) {
          this.opts.color = new Color(this.opts.color);
        }
        color = (ref6 = this.opts.color) != null ? ref6 : new Color(.7, .7, .7);
        this.mesh = (function(_this) {
          return function() {
            var cube, geo, mesh;
            geo = new THREE.BoxGeometry(2, 2, 2);
            mesh = new THREE.Mesh(geo, material);
            cube = new THREE.BoxHelper(mesh);
            cube.material.color = color.three();
            _this.three.scene.add(cube);
            return mesh;
          };
        })(this)();
      }
      this.uniforms = {
        range: {
          type: 'f',
          value: range
        },
        hilite: {
          type: 'i',
          value: hilite ? 1 : 0
        }
      };
      if (this.opts.fragmentShader != null) {
        fragment = this.opts.fragmentShader;
      } else if (shaded) {
        fragment = shadeFragment + "\n" + clipFragment;
      } else {
        fragment = noShadeFragment + "\n" + clipFragment;
      }
      this.clipped = this.view.shader({
        code: clipShader
      }).vertex({
        pass: pass
      }).shader({
        code: fragment,
        uniforms: this.uniforms
      }).fragment();
    }

    ClipCube.prototype.installMesh = function() {
      this.three.scene.add(this.mesh);
      return this.three.on('pre', (function(_this) {
        return function() {
          if (Math.abs(_this.camera.position.x < 1.0) && Math.abs(_this.camera.position.y < 1.0) && Math.abs(_this.camera.position.z < 1.0)) {
            return _this.mesh.material.side = THREE.BackSide;
          } else {
            return _this.mesh.material.side = THREE.FrontSide;
          }
        };
      })(this));
    };

    return ClipCube;

  })();

  LabeledVectors = (function() {
    function LabeledVectors(view, opts1) {
      var col, colors, doZero, i, i1, labelOpts, labels, labelsLive, len, len1, len2, live, name, origins, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, u, v, vec, vectorData, vectorOpts, vectors, z, zeroData, zeroOpts, zeroThreshold;
      this.opts = opts1;
      this.show = bind(this.show, this);
      this.hide = bind(this.hide, this);
      if (this.opts == null) {
        this.opts = {};
      }
      name = (ref = this.opts.name) != null ? ref : "labeled";
      vectors = this.opts.vectors;
      colors = this.opts.colors;
      labels = this.opts.labels;
      origins = (ref1 = this.opts.origins) != null ? ref1 : (function() {
        var ref2, results, u;
        results = [];
        for (u = 0, ref2 = vectors.length; 0 <= ref2 ? u < ref2 : u > ref2; 0 <= ref2 ? u++ : u--) {
          results.push([0, 0, 0]);
        }
        return results;
      })();
      live = (ref2 = this.opts.live) != null ? ref2 : true;
      labelsLive = (ref3 = this.opts.labelsLive) != null ? ref3 : false;
      vectorOpts = {
        id: name + "-vectors-drawn",
        classes: [name],
        points: "#" + name + "-vectors",
        colors: "#" + name + "-colors",
        color: "white",
        end: true,
        size: 5,
        width: 5
      };
      extend(vectorOpts, (ref4 = this.opts.vectorOpts) != null ? ref4 : {});
      labelOpts = {
        id: name + "-vector-labels",
        classes: [name],
        colors: "#" + name + "-colors",
        color: "white",
        outline: 0,
        background: [0, 0, 0, 0],
        size: 15,
        offset: [0, 25]
      };
      extend(labelOpts, (ref5 = this.opts.labelOpts) != null ? ref5 : {});
      doZero = (ref6 = this.opts.zeroPoints) != null ? ref6 : false;
      zeroOpts = {
        id: name + "-zero-points",
        classes: [name],
        points: "#" + name + "-zeros",
        colors: "#" + name + "-zero-colors",
        color: "white",
        size: 20
      };
      extend(zeroOpts, (ref7 = this.opts.zeroOpts) != null ? ref7 : {});
      zeroThreshold = (ref8 = this.opts.zeroThreshold) != null ? ref8 : 0.0;
      for (i = u = 0, len = colors.length; u < len; i = ++u) {
        col = colors[i];
        if (col instanceof Color) {
          colors[i] = col.arr(1);
        }
      }
      this.hidden = false;
      vectorData = [];
      for (v = 0, len1 = vectors.length; v < len1; v++) {
        vec = vectors[v];
        if (vec[2] == null) {
          vec[2] = 0;
        }
      }
      for (z = 0, len2 = origins.length; z < len2; z++) {
        vec = origins[z];
        if (vec[2] == null) {
          vec[2] = 0;
        }
      }
      for (i = i1 = 0, ref9 = vectors.length; 0 <= ref9 ? i1 < ref9 : i1 > ref9; i = 0 <= ref9 ? ++i1 : --i1) {
        vectorData.push(origins[i]);
        vectorData.push(vectors[i]);
      }
      view.array({
        id: name + "-vectors",
        channels: 3,
        width: vectors.length,
        items: 2,
        data: vectorData,
        live: live
      }).array({
        id: name + "-colors",
        channels: 4,
        width: colors.length,
        data: colors,
        live: live
      });
      this.vecs = view.vector(vectorOpts);
      if (labels != null) {
        view.array({
          channels: 3,
          width: vectors.length,
          expr: function(emit, i) {
            return emit((vectors[i][0] + origins[i][0]) / 2, (vectors[i][1] + origins[i][1]) / 2, (vectors[i][2] + origins[i][2]) / 2);
          },
          live: live
        }).text({
          id: name + "-text",
          live: labelsLive,
          width: labels.length,
          data: labels
        });
        this.labels = view.label(labelOpts);
      }
      if (doZero) {
        zeroData = (function() {
          var j1, ref10, results;
          results = [];
          for (j1 = 0, ref10 = vectors.length; 0 <= ref10 ? j1 < ref10 : j1 > ref10; 0 <= ref10 ? j1++ : j1--) {
            results.push([0, 0, 0]);
          }
          return results;
        })();
        view.array({
          id: name + "-zero-colors",
          channels: 4,
          width: vectors.length,
          live: live,
          expr: function(emit, i) {
            if (vectors[i][0] * vectors[i][0] + vectors[i][1] * vectors[i][1] + vectors[i][2] * vectors[i][2] <= zeroThreshold * zeroThreshold) {
              return emit.apply(null, colors[i]);
            } else {
              return emit(0, 0, 0, 0);
            }
          }
        }).array({
          id: name + "-zeros",
          channels: 3,
          width: vectors.length,
          data: zeroData,
          live: false
        });
        this.zeroPoints = view.point(zeroOpts);
        this.zeroPoints.bind('visible', (function(_this) {
          return function() {
            var j1, ref10;
            if (_this.hidden) {
              return false;
            }
            for (i = j1 = 0, ref10 = vectors.length; 0 <= ref10 ? j1 < ref10 : j1 > ref10; i = 0 <= ref10 ? ++j1 : --j1) {
              if (vectors[i][0] * vectors[i][0] + vectors[i][1] * vectors[i][1] + vectors[i][2] * vectors[i][2] <= zeroThreshold * zeroThreshold) {
                return true;
              }
            }
            return false;
          };
        })(this));
      }
    }

    LabeledVectors.prototype.hide = function() {
      var ref;
      if (this.hidden) {
        return;
      }
      this.hidden = true;
      this.vecs.set('visible', false);
      return (ref = this.labels) != null ? ref.set('visible', false) : void 0;
    };

    LabeledVectors.prototype.show = function() {
      var ref;
      if (!this.hidden) {
        return;
      }
      this.hidden = false;
      this.vecs.set('visible', true);
      return (ref = this.labels) != null ? ref.set('visible', true) : void 0;
    };

    return LabeledVectors;

  })();

  LabeledPoints = (function() {
    function LabeledPoints(view, opts1) {
      var col, colors, i, labelOpts, labels, labelsLive, len, len1, live, name, point, pointData, pointOpts, points, ref, ref1, ref2, ref3, ref4, ref5, u, v, z;
      this.opts = opts1;
      this.show = bind(this.show, this);
      this.hide = bind(this.hide, this);
      if (this.opts == null) {
        this.opts = {};
      }
      name = (ref = this.opts.name) != null ? ref : "labeled-points";
      points = this.opts.points;
      colors = this.opts.colors;
      labels = this.opts.labels;
      live = (ref1 = this.opts.live) != null ? ref1 : true;
      labelsLive = (ref2 = this.opts.labelsLive) != null ? ref2 : false;
      pointOpts = {
        id: name + "-drawn",
        classes: [name],
        points: "#" + name + "-points",
        colors: "#" + name + "-colors",
        color: "white",
        size: 15
      };
      extend(pointOpts, (ref3 = this.opts.pointOpts) != null ? ref3 : {});
      labelOpts = {
        id: name + "-labels",
        classes: [name],
        points: "#" + name + "-points",
        colors: "#" + name + "-colors",
        color: "white",
        outline: 0,
        background: [0, 0, 0, 0],
        size: 15,
        offset: [0, 25]
      };
      extend(labelOpts, (ref4 = this.opts.labelOpts) != null ? ref4 : {});
      for (i = u = 0, len = colors.length; u < len; i = ++u) {
        col = colors[i];
        if (col instanceof Color) {
          colors[i] = col.arr(1);
        }
      }
      this.hidden = false;
      pointData = [];
      for (v = 0, len1 = points.length; v < len1; v++) {
        point = points[v];
        if (point[2] == null) {
          point[2] = 0;
        }
      }
      for (i = z = 0, ref5 = points.length; 0 <= ref5 ? z < ref5 : z > ref5; i = 0 <= ref5 ? ++z : --z) {
        pointData.push(points[i]);
      }
      view.array({
        id: name + "-points",
        channels: 3,
        width: points.length,
        data: pointData,
        live: live
      }).array({
        id: name + "-colors",
        channels: 4,
        width: colors.length,
        data: colors,
        live: live
      });
      this.pts = view.point(pointOpts);
      if (labels != null) {
        view.text({
          id: name + "-text",
          live: labelsLive,
          width: labels.length,
          data: labels
        });
        this.labels = view.label(labelOpts);
      }
    }

    LabeledPoints.prototype.hide = function() {
      var ref;
      if (this.hidden) {
        return;
      }
      this.hidden = true;
      this.pts.set('visible', false);
      return (ref = this.labels) != null ? ref.set('visible', false) : void 0;
    };

    LabeledPoints.prototype.show = function() {
      var ref;
      if (!this.hidden) {
        return;
      }
      this.hidden = false;
      this.pts.set('visible', true);
      return (ref = this.labels) != null ? ref.set('visible', true) : void 0;
    };

    return LabeledPoints;

  })();

  Demo = (function() {
    function Demo(opts1, callback) {
      var cameraOpts, clearColor, clearOpacity, doFullScreen, focusDist, image, key, mathboxOpts, onPreloaded, preload, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, scaleUI, toPreload, value;
      this.opts = opts1;
      this.stopAll = bind(this.stopAll, this);
      this.animate = bind(this.animate, this);
      this.clearAnims = bind(this.clearAnims, this);
      this.texCombo = bind(this.texCombo, this);
      this.texSet = bind(this.texSet, this);
      this.urlParams = urlParams;
      if (this.opts == null) {
        this.opts = {};
      }
      mathboxOpts = {
        plugins: ['core', 'controls', 'cursor'],
        controls: {
          klass: OrbitControls,
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
      clearColor = (ref1 = this.opts.clearColor) != null ? ref1 : 0xffffff;
      clearOpacity = (ref2 = this.opts.clearOpacity) != null ? ref2 : 1.0;
      cameraOpts = {
        proxy: true,
        position: [3, 1.5, 1.5],
        lookAt: [0, 0, 0],
        up: [0, 0, 1]
      };
      extend(cameraOpts, (ref3 = this.opts.camera) != null ? ref3 : {});
      if ((ref4 = this.opts.cameraPosFromQS) != null ? ref4 : true) {
        cameraOpts.position = this.urlParams.get('camera', 'float[]', cameraOpts.position);
      }
      focusDist = (ref5 = this.opts.focusDist) != null ? ref5 : 1.5;
      scaleUI = (ref6 = this.opts.scaleUI) != null ? ref6 : true;
      doFullScreen = (ref7 = this.opts.fullscreen) != null ? ref7 : true;
      this.dims = (ref8 = this.opts.dims) != null ? ref8 : 3;
      clearColor = new Color(clearColor);
      this.animations = [];
      onPreloaded = (function(_this) {
        return function() {
          var ref9;
          _this.mathbox = mathBox(mathboxOpts);
          _this.three = _this.mathbox.three;
          _this.three.renderer.setClearColor(clearColor.three(), clearOpacity);
          _this.controls = _this.three.controls;
          _this.camera = _this.mathbox.camera(cameraOpts)[0].controller.camera;
          if ((ref9 = _this.controls) != null) {
            if (typeof ref9.updateCamera === "function") {
              ref9.updateCamera();
            }
          }
          _this.canvas = _this.mathbox._context.canvas;
          if (scaleUI) {
            _this.mathbox.bind('focus', function() {
              return focusDist / 1000 * Math.min(_this.canvas.clientWidth, _this.canvas.clientHeight);
            });
          } else {
            _this.mathbox.set('focus', focusDist);
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
      preload = (ref9 = this.opts.preload) != null ? ref9 : {};
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

    Demo.prototype.texVector = function(vec, opts) {
      var coord, dim, i, len, precision, ref, ref1, ret, u;
      if (opts == null) {
        opts = {};
      }
      precision = (ref = opts.precision) != null ? ref : 2;
      dim = (ref1 = opts.dim) != null ? ref1 : this.dims;
      vec = vec.slice(0, dim);
      if (precision >= 0) {
        for (i = u = 0, len = vec.length; u < len; i = ++u) {
          coord = vec[i];
          vec[i] = coord.toFixed(precision);
        }
      }
      ret = '';
      if (opts.color != null) {
        if (opts.color instanceof Color) {
          opts.color = opts.color.str();
        }
        ret += "\\color{" + opts.color + "}{";
      }
      ret += "\\begin{bmatrix}";
      ret += vec.join("\\\\");
      ret += "\\end{bmatrix}";
      if (opts.color != null) {
        ret += "}";
      }
      return ret;
    };

    Demo.prototype.texSet = function(vecs, opts) {
      var col, colors, i, len, len1, precision, ref, str, u, v, vec;
      if (opts == null) {
        opts = {};
      }
      colors = opts.colors;
      if (colors != null) {
        for (i = u = 0, len = colors.length; u < len; i = ++u) {
          col = colors[i];
          if (col instanceof Color) {
            colors[i] = col.str();
          }
        }
      }
      precision = (ref = opts.precision) != null ? ref : 2;
      str = "\\left\\{";
      for (i = v = 0, len1 = vecs.length; v < len1; i = ++v) {
        vec = vecs[i];
        if (colors != null) {
          opts.color = colors[i];
        }
        str += this.texVector(vec, opts);
        if (i + 1 < vecs.length) {
          str += ",\\,";
        }
      }
      return str + "\\right\\}";
    };

    Demo.prototype.texCombo = function(vecs, coeffs, opts) {
      var coeffColors, col, colors, i, len, len1, len2, precision, ref, str, u, v, vec, z;
      if (opts == null) {
        opts = {};
      }
      colors = opts.colors;
      if (colors != null) {
        for (i = u = 0, len = colors.length; u < len; i = ++u) {
          col = colors[i];
          if (col instanceof Color) {
            colors[i] = col.str();
          }
        }
      }
      coeffColors = opts.coeffColors;
      if (!(coeffColors instanceof Array)) {
        coeffColors = (function() {
          var ref, results, v;
          results = [];
          for (v = 0, ref = vecs.length; 0 <= ref ? v < ref : v > ref; 0 <= ref ? v++ : v--) {
            results.push(coeffColors);
          }
          return results;
        })();
      }
      for (i = v = 0, len1 = coeffColors.length; v < len1; i = ++v) {
        col = coeffColors[i];
        if (col instanceof Color) {
          coeffColors[i] = col.str();
        }
      }
      precision = (ref = opts.precision) != null ? ref : 2;
      str = '';
      for (i = z = 0, len2 = vecs.length; z < len2; i = ++z) {
        vec = vecs[i];
        if (coeffColors[i] != null) {
          str += "\\color{" + coeffColors[i] + "}{";
        }
        if (coeffs[i] !== 1) {
          if (coeffs[i] === -1) {
            str += '-';
          } else {
            str += coeffs[i].toFixed(precision);
          }
        }
        if (coeffColors[i] != null) {
          str += "}";
        }
        if (colors != null) {
          opts.color = colors[i];
        }
        str += this.texVector(vec, opts);
        if (i + 1 < vecs.length && coeffs[i + 1] >= 0) {
          str += ' + ';
        }
      }
      return str;
    };

    Demo.prototype.texMatrix = function(cols, opts) {
      var col, colors, i, j, len, m, n, precision, ref, ref1, ref2, ref3, ref4, str, u, v, z;
      if (opts == null) {
        opts = {};
      }
      colors = opts.colors;
      if (colors != null) {
        for (i = u = 0, len = colors.length; u < len; i = ++u) {
          col = colors[i];
          if (col instanceof Color) {
            colors[i] = col.str();
          }
        }
      }
      precision = (ref = opts.precision) != null ? ref : 2;
      m = (ref1 = opts.rows) != null ? ref1 : this.dims;
      n = (ref2 = opts.cols) != null ? ref2 : cols.length;
      str = "\\begin{bmatrix}";
      for (i = v = 0, ref3 = m; 0 <= ref3 ? v < ref3 : v > ref3; i = 0 <= ref3 ? ++v : --v) {
        for (j = z = 0, ref4 = n; 0 <= ref4 ? z < ref4 : z > ref4; j = 0 <= ref4 ? ++z : --z) {
          if (colors != null) {
            str += "\\color{" + colors[j] + "}{";
          }
          if (precision >= 0) {
            str += cols[j][i].toFixed(precision);
          } else {
            str += cols[j][i];
          }
          if (colors != null) {
            str += "}";
          }
          if (j + 1 < n) {
            str += "&";
          }
        }
        if (i + 1 < m) {
          str += "\\\\";
        }
      }
      return str += "\\end{bmatrix}";
    };

    Demo.prototype.rowred = function(mat, opts) {
      return rowReduce(mat, opts);
    };

    Demo.prototype.view = function(opts) {
      var r;
      if (opts == null) {
        opts = {};
      }
      if (this.urlParams.range != null) {
        r = this.urlParams.get('range', 'float');
        if (opts.viewRange == null) {
          opts.viewRange = [[-r, r], [-r, r], [-r, r]];
        }
      }
      return new View(this.mathbox, opts).view;
    };

    Demo.prototype.caption = function(text) {
      return new Caption(this.mathbox, text);
    };

    Demo.prototype.popup = function(text) {
      return new Popup(this.mathbox, text);
    };

    Demo.prototype.clipCube = function(view, opts) {
      return new ClipCube(view, opts);
    };

    Demo.prototype.draggable = function(view, opts) {
      return new Draggable(view, opts);
    };

    Demo.prototype.linearCombo = function(view, opts) {
      return new LinearCombo(view, opts);
    };

    Demo.prototype.grid = function(view, opts) {
      return new Grid(view, opts);
    };

    Demo.prototype.labeledVectors = function(view, opts) {
      return new LabeledVectors(view, opts);
    };

    Demo.prototype.labeledPoints = function(view, opts) {
      return new LabeledPoints(view, opts);
    };

    Demo.prototype.subspace = function(opts) {
      return new Subspace(opts);
    };

    Demo.prototype.clearAnims = function() {
      return this.animations = this.animations.filter(function(a) {
        return a.running;
      });
    };

    Demo.prototype.animate = function(opts) {
      var anim, ref;
      anim = (ref = opts.animation) != null ? ref : new MathboxAnimation(opts.element, opts);
      anim.on('stopped', this.clearAnims);
      anim.on('done', this.clearAnims);
      anim.start();
      return this.animations.push(anim);
    };

    Demo.prototype.stopAll = function() {
      var anim, len, ref, u;
      ref = this.animations;
      for (u = 0, len = ref.length; u < len; u++) {
        anim = ref[u];
        anim.stop();
        anim.off('stopped', this.clearAnims);
        anim.off('done', this.clearAnims);
      }
      return this.animations = [];
    };

    return Demo;

  })();

  Demo2D = (function(superClass) {
    extend1(Demo2D, superClass);

    function Demo2D(opts, callback) {
      var base, base1, base2, base3, base4, base5, base6, base7, base8, ortho, ref, ref1, vertical;
      if (opts == null) {
        opts = {};
      }
      if (opts.dims == null) {
        opts.dims = 2;
      }
      if (opts.mathbox == null) {
        opts.mathbox = {};
      }
      if ((base = opts.mathbox).plugins == null) {
        base.plugins = ['core'];
      }
      ortho = (ref = opts.ortho) != null ? ref : 10000;
      if ((base1 = opts.mathbox).camera == null) {
        base1.camera = {};
      }
      if ((base2 = opts.mathbox.camera).near == null) {
        base2.near = ortho / 4;
      }
      if ((base3 = opts.mathbox.camera).far == null) {
        base3.far = ortho * 4;
      }
      if (opts.camera == null) {
        opts.camera = {};
      }
      if ((base4 = opts.camera).proxy == null) {
        base4.proxy = false;
      }
      if ((base5 = opts.camera).position == null) {
        base5.position = [0, 0, ortho];
      }
      if ((base6 = opts.camera).lookAt == null) {
        base6.lookAt = [0, 0, 0];
      }
      if ((base7 = opts.camera).up == null) {
        base7.up = [1, 0, 0];
      }
      vertical = (ref1 = opts.vertical) != null ? ref1 : 1.1;
      if ((base8 = opts.camera).fov == null) {
        base8.fov = Math.atan(vertical / ortho) * 360 / π;
      }
      if (opts.focusDist == null) {
        opts.focusDist = ortho / 1.5;
      }
      Demo2D.__super__.constructor.call(this, opts, callback);
    }

    Demo2D.prototype.view = function(opts) {
      var r;
      if (opts == null) {
        opts = {};
      }
      if (this.urlParams.range != null) {
        r = this.urlParams.get('range', 'float');
        if (opts.viewRange == null) {
          opts.viewRange = [[-r, r], [-r, r]];
        }
      } else {
        if (opts.viewRange == null) {
          opts.viewRange = [[-10, 10], [-10, 10]];
        }
      }
      return new View(this.mathbox, opts).view;
    };

    Demo2D.prototype.draggable = function(view, opts) {
      if (opts == null) {
        opts = {};
      }
      if (opts.is2D == null) {
        opts.is2D = true;
      }
      return new Draggable(view, opts);
    };

    return Demo2D;

  })(Demo);

  window.Color = Color;

  for (name in palette) {
    color = palette[name];
    document.body.style.setProperty("--palette-" + name, new Color(color).str());
  }

  window.rowReduce = rowReduce;

  window.eigenvalues = eigenvalues;

  window.Animation = Animation;

  window.Demo = Demo;

  window.Demo2D = Demo2D;

  window.urlParams = urlParams;

  window.OrbitControls = OrbitControls;

  window.groupControls = groupControls;

}).call(this);
