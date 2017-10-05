"use strict";

// Configurable setup for demos
// Used to cut down on code duplication.

window.Demo = function(opts, func) {

    this.opts = opts;
    var self = this;

    var mathboxOpts = opts.mathbox || {};
    var clearColor = (opts.clearColor === undefined) ? 0x000000 : opts.clearColor;
    var clearOpacity = (opts.clearOpacity === undefined) ? 1.0 : opts.clearOpacity;
    var cameraOpts = opts.camera || {
        proxy:    true,
        position: [-1.5, 1.5, -3],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    };
    var focusDist = opts.focusDist || 1.5;
    var viewRange = opts.viewRange || [[-10, 10], [-10, 10], [-10, 10]];
    var doAxes = (opts.axes === undefined) ? true : opts.axes;
    var doAxisLabels = (opts.axisLabels === undefined) ? true : opts.axisLabels;
    doAxisLabels = doAxisLabels && doAxes;
    var doGrid = (opts.grid === undefined) ? true : opts.grid;
    var captionContent = opts.caption;
    var doFullscreen = (opts.fullscreen === undefined) ? true : opts.fullscreen;
    var doPopup = !!opts.popup;

    var onPreloaded = function() {
        // Create mathbox
        var tmpDict = {
            plugins: ['core', 'controls', 'cursor'],
            controls: {
                klass: THREE.OrbitControls,
                parameters: {
                    // noZoom: true,
                }
            },
            mathbox: {
                inspect: false,
            },
            splash: {fancy: true, color: "blue"},
        };
        for(var prop in mathboxOpts)
            tmpDict[prop] = mathboxOpts[prop];
        var mathbox = self.mathbox = window.mathbox = mathBox(tmpDict);

        if (mathbox.fallback) throw "WebGL not supported"
        var three = self.three = window.three = mathbox.three;
        three.renderer.setClearColor(new THREE.Color(clearColor), clearOpacity);
        // Place camera
        self.cameraAPI = mathbox.camera(cameraOpts);
        self.camera = self.cameraAPI[0].controller.camera;
        // Calibrate focus distance for units
        //mathbox.set('focus', focusDist);
        self.canvas = document.querySelector('canvas');
        mathbox.bind('focus', function() {
            return focusDist
                * Math.min(self.canvas.clientWidth, self.canvas.clientHeight) / 1000;
        });

        // 3D cartesian
        var view = self.view = mathbox
            .cartesian({
                range: viewRange,
                scale: [-1, 1, 1],
                rotation: [-π/2, 0, 0],
            });

        if(doAxes)
            view.axis({
                classes:  ['axes'],
                axis:     1,
                end:      true,
                width:    3,
                depth:    1,
                color:    'white',
                opacity:  0.75,
                zBias:    -1,
                size:     5,
            })
            .axis({
                classes:  ['axes'],
                axis:     2,
                end:      true,
                width:    3,
                depth:    1,
                color:    'white',
                opacity:  0.75,
                zBias:    -1,
                size:     5,
            })
            .axis({
                classes:  ['axes'],
                axis:     3,
                end:      true,
                width:    3,
                depth:    1,
                color:    'white',
                opacity:  0.75,
                zBias:    -1,
                size:     5,
            });

        if(doGrid)
            view.grid({
                classes:  ['axes', 'grid'],
                axes:     [1, 2],
                width:    2,
                depth:    1,
                color:    'white',
                opacity:  0.5,
            });

        if(doAxisLabels)
            view.array({
                channels: 3,
                width:    3,
                data:     [[viewRange[0][1]*1.04,0,0],
                           [0,viewRange[1][1]*1.04,0],
                           [0,0,viewRange[2][1]*1.04]],
                live:     false,
            })
            .text({
                live:     false,
                width:    3,
                data:     ['x', 'y', 'z']
            })
            .label({
                classes: ['axes'],
                outline: 0,
                color:   "white",
                offset:  [0,0],
                size:    20
            });

        if(captionContent) {
            var div = document.getElementsByClassName("mathbox-overlays")[0];
            var label = self.label = document.createElement("div");
            label.className = "overlay-text";
            label.innerHTML = captionContent;
            div.appendChild(label);
        }

        if(doFullscreen) {
            document.body.addEventListener('keypress', function (event) {
                if (event.charCode == 'f'.charCodeAt(0)) {
                    if (screenfull.enabled) {
                        screenfull.toggle();
                    }
                }
            });
        }

        if(doPopup) {
            var div = document.getElementsByClassName("mathbox-overlays")[0];
            var popup = self.popup = document.createElement("div");
            popup.className = "overlay-popup";
            popup.style.display = 'none';
            div.appendChild(popup);
        }

        func.apply(self);

    }

    // Preload images
    var preload = opts.preload;
    var toPreload = 0;
    if(preload) {
        for(var key in preload) {
            toPreload++;
            var image = new Image();
            this[key] = image;
            image.src = preload[key];
            image.addEventListener('load', function() {
                if(--toPreload == 0)
                    onPreloaded();
            });
        }
    } else
        onPreloaded();

};


window.Demo.prototype = {

    show_popup: function(text) {
        this.popup.innerHTML = text;
        this.popup.style.display = '';
    },
    hide_popup: function() {
        this.popup.style.display = 'none';
    },

    render_vec: (function() {
        var tVec = new THREE.Vector3();
        return function(vec) {
            var tmpvec = vec;
            if(!vec.x) {
                tVec.set.apply(tVec, vec);
                tmpvec = tVec;
            }
            return "\\begin{bmatrix}" +
                tmpvec.x + "\\\\" +
                tmpvec.y + "\\\\" +
                tmpvec.z +
                "\\end{bmatrix}";
        };
    })(),

    orthogonalize: (function() {
        // Orthogonalize two linearly independent vectors
        var tmpvec;
        return function(p1, p2) {
            if(tmpvec === undefined)
                tmpvec = new THREE.Vector3();
            tmpvec.copy(p1.normalize());
            p2.sub(tmpvec.multiplyScalar(p2.dot(p1))).normalize();
        };
    }),

    labeledVectors: function(vectors, colors, labels, opts) {
        var vectorData = [];
        var origins = [];
        if(opts.origins)
            origins = opts.origins;
        else {
            for(var i = 0; i < vectors.length; ++i)
                origins.push([0, 0, 0]);
        }
        for(var i = 0; i < vectors.length; ++i) {
            vectorData.push(origins[i]);
            vectorData.push(vectors[i]);
        }

        var vectorSize   = (opts.vectorSize   === undefined) ? 5  : opts.vectorSize;
        var vectorWidth  = (opts.vectorWidth  === undefined) ? 5  : opts.vectorWidth;
        var labelOutline = (opts.labelOutline === undefined) ? 2  : opts.labelOutline;
        var labelSize    = (opts.labelSize    === undefined) ? 15 : opts.labelSize;
        var zeroSize     = (opts.zeroSize     === undefined) ? 20 : opts.zeroSize;
        var labelOffset = opts.labelOffset || [0, 25];
        let prefix = opts.prefix || '';

        this.view
        // vectors
            .array({
                id:       prefix + "vectors",
                channels: 3,
                width:    vectors.length,
                items:    2,
                data:     vectorData
            })
            .array({
                id:       prefix + "colors",
                channels: 4,
                width:    colors.length,
                data:     colors,
            })
            .vector({
                id:      prefix + "vectors-drawn",
                colors:  "#" + prefix + "colors",
                color:   "white",
                points:  "#" + prefix + "vectors",
                end:     true,
                size:    vectorSize,
                width:   vectorWidth,
            });
        if(labels) {
            this.view
            // labels
                .array({
                    channels: 3,
                    width:    vectors.length,
                    expr: function(emit, i) {
                        emit((vectors[i][0] + origins[i][0])/2,
                             (vectors[i][1] + origins[i][1])/2,
                             (vectors[i][2] + origins[i][2])/2);
                    },
                })
                .text({
                    id:    prefix + "text",
                    live:  false,
                    width: labels.length,
                    data:  labels,
                })
                .label({
                    id:      prefix + "vector-labels",
                    outline: labelOutline,
                    colors:  "#" + prefix + "colors",
                    color:   "white",
                    background: "black",
                    offset:  labelOffset,
                    size:    labelSize,
                });
        }

        // Points for when vectors are zero
        if(opts.zeroPoints) {
            var zeroData = [];
            for(var i = 0; i < vectors.length; ++i)
                zeroData.push([0,0,0]);

            this.view
                .array({
                    id:       prefix + "zero-colors",
                    channels: 4,
                    width:    vectors.length,
                    expr: function(emit, i) {
                        if(vectors[i][0] == 0 &&
                           vectors[i][1] == 0 &&
                           vectors[i][2] == 0)
                            emit(colors[i][0],
                                 colors[i][1],
                                 colors[i][2],
                                 colors[i][3]);
                        else
                            emit(0, 0, 0, 0);
                    }
                })
                .array({
                    id:       prefix + "zeros",
                    channels: 3,
                    width:    vectors.length,
                    data:     zeroData,
                })
            ;
            this.zeroPoints = this.view
                .point({
                    id:      prefix + "zero-points",
                    colors:  "#" + prefix + "zero-colors",
                    color:   "white",
                    points:  "#" + prefix + "zeros",
                    size:    zeroSize,
                    visible: false,
                });
        }
    },

    clipCube: function(opts) {
        // Return a MathBox API that clips its contents to the cube [-1,1]^3.
        // Optionally draw the cube too.

        if(opts.drawCube) {
            var cubeMaterial = opts.material || new THREE.MeshBasicMaterial();
            var wireframeColor = opts.wireframeColor || new THREE.Color(1, 1, 1);

            // Clip-to cube
            this.clipCubeMesh = (function() {
                var geo = new THREE.BoxGeometry(2, 2, 2);
                var mesh = new THREE.Mesh(geo, cubeMaterial);
                var cube = new THREE.BoxHelper(mesh);
                cube.material.color = wireframeColor
                three.scene.add(cube);
                return mesh;
            })();
        }

        var clipped = this.view;
        clipped = clipped
            .shader({code: "#vertex-xyz"})
            .vertex({pass: "world"});
        clipped = clipped
            .shader({code: "#fragment-clipping"})
            .fragment();
        this.clipped = clipped;
        return clipped;
    },

    decodeQS: function() {
        var decode, match, pl, query, search;
        pl = /\+/g;
        search = /([^&=]+)=?([^&]*)/g;
        decode = function(s) {
            return decodeURIComponent(s.replace(pl, " "));
        };
        query = window.location.search.substring(1);
        var urlParams = {};
        while (match = search.exec(query)) {
            urlParams[decode(match[1])] = decode(match[2]);
        }
        return urlParams;
    },

};
