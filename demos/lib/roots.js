"use strict";

// JDR: mostly found on:
//   https://stackoverflow.com/questions/27176423/function-to-solve-cubic-equation-analytically

(function() {

var cuberoot = function (x) {
    var y = Math.pow(Math.abs(x), 1/3);
    return x < 0 ? -y : y;
}

// Returns a list of [real root, multiplicity]
var solveCubic = function (a, b, c, d) {
    if (d === undefined) { // Quadratic case, ax^2+bx+c=0
        if (c === undefined) { // Linear case, ax+b=0
            if (b === undefined) // Degenerate case
                return [];
            return [[-b/a, 1]];
        }

        var D = b*b - 4*a*c;
        if (Math.abs(D) < 1e-8)
            return [[-b/(2*a), 2]];
        else if (D > 0)
            return [[(-b+Math.sqrt(D))/(2*a), 1], [(-b-Math.sqrt(D))/(2*a), 1]];
        return [];
    }

    // Convert to depressed cubic t^3+pt+q = 0 (subst x = t - b/3a)
    var p = (3*a*c - b*b)/(3*a*a);
    var q = (2*b*b*b - 9*a*b*c + 27*a*a*d)/(27*a*a*a);
    var roots;

    if (Math.abs(p) < 1e-8) { // p = 0 -> t^3 = -q -> t = -q^1/3
        if (Math.abs(q) < 1e-8) {
            roots = [[0, 3]];
        } else {
            roots = [[cuberoot(-q), 1]];
        }
    } else if (Math.abs(q) < 1e-8) { // q = 0 -> t^3 + pt = 0 -> t(t^2+p)=0
        roots = [[0, 1]].concat(p < 0 ? [[Math.sqrt(-p), 1], [-Math.sqrt(-p), 1]] : []);
    } else {
        var D = q*q/4 + p*p*p/27;
        if (Math.abs(D) < 1e-8) {       // D = 0 -> two roots, one double
            roots = [[-1.5*q/p, 2], [3*q/p, 1]];
        } else if (D > 0) {             // Only one real root
            var u = cuberoot(-q/2 - Math.sqrt(D));
            roots = [[u - p/(3*u), 1]];
        } else {                        // D < 0, three roots, but needs to use complex numbers/trigonometric solution
            var u = 2*Math.sqrt(-p/3);
            var t = Math.acos(3*q/p/u)/3;  // D < 0 implies p < 0 and acos argument in [-1..1]
            var k = 2*Math.PI/3;
            roots = [[u*Math.cos(t), 1], [u*Math.cos(t-k), 1], [u*Math.cos(t-2*k), 1]];
        }
    }

    // Convert back from depressed cubic
    for (var i = 0; i < roots.length; i++)
        roots[i][0] -= b/(3*a);

    return roots;
}

window.findRoots = solveCubic;

})();
