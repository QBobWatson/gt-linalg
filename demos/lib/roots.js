"use strict";

(function() {

var EPSILON = 1e-8

var nextPow2 = function(v) {
    v += v === 0;
    --v;
    v |= v >>> 1;
    v |= v >>> 2;
    v |= v >>> 4;
    v |= v >>> 8;
    v |= v >>> 16;
    return v + 1;
};

var pr = new Float64Array(1024)
var pi = new Float64Array(1024)


function near(a, b, c, d, tol) {
  var qa = a - c
  var qb = b - d
  var r = qa * qa + qb * qb
  if(r * r < tol) {
    return true
  }
  return false
}

function solve(n, n_iters, tolerance, zr, zi) {
  var m = zr.length
  var i, j, k, a, b, na, nb, pa, pb, qa, qb, k1, k2, k3, s1, s2, t, d, r
  var max = Math.max, abs = Math.abs
  for(i=0; i<n_iters; ++i) {
    d = 0.0
    for(j=0; j<m; ++j) {
      //Read in zj
      pa = zr[j]
      pb = zi[j]

      //Compute denominator
      //
      //  (zj - z0) * (zj - z1) * ... * (zj - z_{n-1})
      //
      a = 1.0
      b = 0.0
      for(k=0; k<m; ++k) {
        if(k === j) {
          continue
        }
        qa = pa - zr[k]
        qb = pb - zi[k]
        if(qa * qa + qb * qb < tolerance) {
          continue
        }
        k1 = qa * (a + b)
        k2 = a * (qb - qa)
        k3 = b * (qa + qb)
        a = k1 - k3
        b = k1 + k2
      }

      //Compute numerator
      na = pr[n-1]
      nb = pi[n-1]
      s1 = pb - pa
      s2 = pa + pb
      for(k=n-2; k>=0; --k) {
        k1 = pa * (na + nb)
        k2 = na * s1
        k3 = nb * s2
        na = k1 - k3 + pr[k]
        nb = k1 + k2 + pi[k]
      }


      //Compute reciprocal
      k1 = a*a + b*b
      if(abs(k1) > EPSILON) {
        a /=  k1
        b /= -k1
      } else {
        a = 1.0
        b = 0.0
      }

      //Multiply and accumulate
      k1 = na * (a + b)
      k2 = a * (nb - na)
      k3 = b * (na + nb)

      qa = k1 - k3
      qb = k1 + k2

      zr[j] = pa - qa
      zi[j] = pb - qb

      d = max(d, max(abs(qa), abs(qb)))
    }

    //If converged, exit early
    if(d < tolerance) {
      break
    }
  }

  //Post process: Combine any repeated roots
  var count
  for(i=0; i<m; ++i) {
    count = 1
    a = zr[i]
    b = zi[i]
    for(j=0; j<m; ++j) {
      if(i === j) {
        continue
      }
      if(near(zr[i], zi[i], zr[j], zi[j], tolerance)) {
        ++count
        a += zr[j]
        b += zi[j]
      }
    }
    if(count > 1) {
      a /= count
      b /= count
      for(j=0; j<m; ++j) {
        if(i === j) {
          continue
        }
        if(near(zr[i], zi[i], zr[j], zi[j], tolerance)) {
          zr[j] = a
          zi[j] = b
        }
      }
      zr[i] = a
      zi[i] = b
    }
  }
  return [ zr, zi ]
}

function bound(n) {
  var i, b = 0.0
  for(i=0; i<n; ++i) {
    b = Math.max(b, pr[i] * pr[i] + pi[i] * pi[i])
  }
  return 1.0 + Math.sqrt(b)
}

function findRoots(r_coeff, i_coeff, n_iters, tolerance, zr, zi) {
  var n = r_coeff.length, i
  if(n <= 1) {
    return []
  }
  if(pr.length < n) {
    var nl = nextPow2(n)
    pr = new Float64Array(nl)
    pi = new Float64Array(nl)
  }
  for(i=0; i<n; ++i) {
    pr[i] = r_coeff[i]
  }
  if(!i_coeff) {
    for(i=0; i<n; ++i) {
      pi[i] = 0.0
    }
  } else {
    for(i=0; i<n; ++i) {
      pi[i] = i_coeff[i]
    }
  }
  //Rescale coefficients
  var a = pr[n-1], b = pi[n-1]
  var d = a*a + b*b
  a /= d
  b /= -d
  var k1, k2, k3, s = b - a, t = a + b
  for(var i=0; i<n-1; ++i) {
    k1 = a * (pr[i] + pi[i])
    k2 = pr[i] * s
    k3 = pi[i] * t
    pr[i] = k1 - k3
    pi[i] = k1 + k2
  }
  pr[n-1] = 1.0
  pi[n-1] = 0.0
  if(!n_iters) {
    n_iters = 100 * n
  }
  if(!tolerance) {
    tolerance = 1e-6
  }
  //Pick default initial guess if unspecified
  if(!zr) {
    zr = new Array(n-1)
    zi = new Array(n-1)
    var r = bound(n), t, c
    for(i=0; i<n-1; ++i) {
      t = Math.random() * r
      c = Math.cos(Math.random() * 2 * Math.PI)
      zr[i] = t * c
      zi[i] = t * Math.sqrt(1.0 - c*c)
    }
  } else if(!zi) {
    zi = new Array(zr.length)
    for(i=0; i<zi.length; ++i) {
      zi[i] = 0.0
    }
  }
  return solve(n, n_iters, tolerance, zr, zi)
}

window.findRoots = findRoots;

})();
