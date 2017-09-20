"use strict";

// JDR: Make points draggable

// opts contains:
//   view:     Containing view
//   points:   List of draggable points.  The coordinates of these points will be
//       changed by the drag.  Max 254 points.
//   size:     Size of the draggable point.
//   hiliteColor: Color (plus opacity) of a hovered point.
//   hiliteSize: Size of the hover point.
//   hiliteIndex: zIndex of the hover point.
//   onDrag:   Drag callback.

// Available properties:
//   hovered:  Index of the point the mouse is hovering over, or -1 if none
//   dragging: Point currently being dragged, or -1 if none.

function Draggable(opts) {
    var view        = opts.view;
    var points      = opts.points;
    var size        = opts.size;
    var onDrag      = opts.onDrag;
    var hiliteColor = opts.hiliteColor;
    var hiliteIndex = opts.hiliteIndex;
    var hiliteSize  = opts.hiliteSize || 30;
    var mathbox     = opts.mathbox || window.mathbox;
    if(hiliteColor === undefined)
        hiliteColor = [0, .5, .5, .75];
    if(hiliteIndex === undefined)
        hiliteIndex = 2;

    this.hovered  = -1;
    this.dragging = -1;
    var self = this;

    var scale = 1 / 4;
    var viewMatrix = view[0].controller.viewMatrix;
    var viewMatrixInv = new THREE.Matrix4();
    viewMatrixInv.getInverse(viewMatrix);
    var viewMatrixTrans = viewMatrix.clone();
    viewMatrixTrans.transpose();

    // Red channel picks out the point
    // Alpha channel for existence
    var indices = [];
    for(var i = 0; i < points.length; ++i)
        indices.push([(i+1)/255, 0, 0, 0]);

    // Draw the points in RTT
    view
        .array({
            id:       "draggable-points",
            channels: 3,
            width:    points.length,
            data:     points,
        })
        .array({
            id:       "draggable-index",
            channels: 4,
            width:    points.length,
            data:     indices,
        })
    ;

    var rtt = view.rtt({
        id:     'draggable-rtt',
        size:   'relative',
        width:  scale,
        height: scale,
    });

    rtt
        // This should really be automatic...
        .transform({
            matrix: Array.prototype.slice.call(viewMatrixTrans.elements),
        })
        .point({
            points:   '#draggable-points',
            colors:   '#draggable-index',
            color:    'white',
            size:     size,
            blending: 'no',
        })
        .end();

    view
        .array({
            id:       "draggable-colors",
            channels: 4,
            width:    points.length,
            expr: function(emit, i, t) {
                if(self.hovered == i)
                    emit.apply(null, hiliteColor);
                else
                    emit(1, 1, 1, 0);
            }
        })
        .point({
            id:     "draggable-hilite",
            color:  "rgb(0,128,255)",
            points: "#draggable-points",
            colors: "#draggable-colors",
            zIndex: hiliteIndex,
            size:   hiliteSize,
            zTest:  false,
            zWrite: false,
        })
    ;

    // Readback RTT pixels
    var readback =
        view.readback({
            source: '#draggable-rtt',
            type:   'unsignedByte',
        });
    // view.compose({opacity: 0.5}); // debug readback

    var getIndexAt = function (x, y) {
        var data = readback.get('data');
        if (!data) return -1;

        x = Math.floor(x * scale);
        y = Math.floor(y * scale);

        var w = readback.get('width');
        var h = readback.get('height');

        var o = (x + w * (h - y - 1)) * 4;
        var r = data[o];
        var a = data[o+3];

        return r === undefined ? -1 : (a == 0 ? r-1 : -1);
    };

    var camera = mathbox.select("camera")[0].controller.camera;
    var mouse = [-1, -1];
    var three = mathbox.three;
    var activePoint = undefined;

    three.canvas.addEventListener('mousedown', function(event) {
        if(self.hovered < 0) return;
        event.preventDefault();
        self.dragging = self.hovered;
        activePoint = points[self.dragging];
    }, false);

    three.canvas.addEventListener('mousemove', function (event) {
        mouse = [event.offsetX * window.devicePixelRatio,
                 event.offsetY * window.devicePixelRatio];
        if(self.dragging < 0) return;

        event.preventDefault();
        // Move the point in the plane parallel to the camera.
        var projected = new THREE.Vector3(
            activePoint[0], activePoint[1], activePoint[2]);
        projected.applyMatrix4(viewMatrix).project(camera);
        var mouseX = event.offsetX / three.canvas.offsetWidth * 2 - 1.0;
        var mouseY = -(event.offsetY / three.canvas.offsetHeight * 2 - 1.0);
        var vector = new THREE.Vector3(mouseX, mouseY, projected.z);
        vector.unproject(camera).applyMatrix4(viewMatrixInv);
        if(onDrag) onDrag(vector);
        activePoint[0] = vector.x;
        activePoint[1] = vector.y;
        activePoint[2] = vector.z;
    }, false);

    three.canvas.addEventListener('mouseup', function (event) {
        if(self.dragging < 0) return;
        event.preventDefault();
        self.dragging = -1;
        self.activePoint = undefined;
    }, false);

    three.on('post', function () {
        self.hovered = getIndexAt(mouse[0], mouse[1]);
        if(self.dragging >= 0)
            three.canvas.style.cursor = 'pointer';
        else if(self.hovered >= 0)
            three.canvas.style.cursor = 'pointer';
        else if(three.controls)
            three.canvas.style.cursor = 'move';
        else
            three.canvas.style.cursor = '';
        if(three.controls)
            three.controls.enabled = self.hovered < 0 && self.dragging < 0;
    });
}
