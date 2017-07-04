/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

"use strict";

let rye = require("rye");
let helpers = require("./helpers");

let field = new rye.PrimeField(2); // GF(2)
let ring = new rye.PolynomRing(field);
let extfield = new rye.FactorRing(ring, ring.polynom([1, 1, 0, 0, 0, 0, 0, 0, 0, 1])); // GF(2^9)

function div(a, b) {
    let ib = extfield.inv(b);
    return extfield.mul(a, ib);
}

function test_infinity(x1, y1) {
    return x1 == Infinity && y1 == Infinity;
}

function point_add(x1, y1, x2, y2) {
    if (test_infinity(x1, y1)) {
        return [x2, y2];
    } else if (test_infinity(x2, y2)) {
        return [x1, y1];
    } else if (x1 == x2) {
        if (y1 == y2) {
            return [Infinity, Infinity];
        } else {
            return point_double(x1, x2);
        }
    }

    let f = extfield;
    let a = 1;
    let x3, y3;

    //console.log(`ADD (${x1},${y1}) + (${x2},${y2})`);

    let y1_y2 = f.add(y1, y2);
    //console.log("TY: " + y1_y2);
    let x1_x2 = f.add(x1, x2);
    //console.log("TX: " + x1_x2);


    let lambda = div(y1_y2, x1_x2);
    //console.log("LAMBDA: " + lambda);

    let l2 = f.mul(lambda, lambda);
    //console.log("L^2: " + l2);

    let l2_l = f.add(l2, lambda);
    //console.log("L^2 + L: " + l2_l);

    let l2_l_x1 = f.add(l2_l, x1);
    //console.log("L^2 + L + x1: " + l2_l_x1);

    let l2_l_x1_x2 = f.add(l2_l_x1, x2);
    //console.log("L^2 + L + x1 + x2: " + l2_l_x1_x2);

    let l2_l_x1_x2_a = x3 = f.add(l2_l_x1_x2, a);
    //console.log("L^2 + L + x1 + x2: " + l2_l_x1_x2_a);

    let x1_x3 = f.add(x1, x3);
    //console.log("x1 + x3: " + x1_x3);

    let l_x1_x3 = f.mul(lambda, x1_x3);
    //console.log("l * (x1 + x3): " + l_x1_x3);

    let l_x1_x3_x3 = f.add(l_x1_x3, x3);
    //console.log("l * (x1 + x3) + x3: " + l_x1_x3_x3);

    let l_x1_x3_x3_y1 = y3 = f.add(l_x1_x3_x3, y1);
    //console.log("l * (x1 + x3) + x3 + y1: " + l_x1_x3_x3_y1);

    return [x3, y3];
}


function point_double(x1, y1) {
    if (test_infinity(x1, y1) || x1 == 0) {
        return [Infinity, Infinity];
    }

    let f = extfield;
    let a = 1;
    let x3, y3;

    let y1_x1 = div(y1, x1);
    
    let lambda = f.add(x1, y1_x1);

    //console.log("LAMBDA: " + lambda);


    let l2 = f.mul(lambda, lambda);

    let l2_l = f.add(l2, lambda);

    let l2_l_a = x3 = f.add(l2_l, a);


    let x12 = f.mul(x1, x1);

    let l_x3 = f.mul(lambda, x3);

    let x12_lx3 = f.add(x12, l_x3);

    let x12_lx3_x3 = y3 = f.add(x12_lx3, x3);


    return [x3, y3];
}


function oncurve(x, y, a, b) {
    if (x == Infinity && y == Infinity) {
        return true;
    }

    let f = extfield;

    let x2 = f.mul(x, x);
    let x3 = f.mul(x2, x);

    let ax2 = f.mul(a, x2);

    let x3_ax2 = f.add(x3, ax2);

    let x3_ax2_b = f.add(x3_ax2, b);

    // -- 

    let y2 = f.mul(y, y);
    let xy = f.mul(x, y);

    let y2_xy = f.add(y2, xy);


    //console.log(y2_xy + " = y^2 + xy = x^3 + ax^2 + b = " +x3_ax2_b);

    return y2_xy == x3_ax2_b;
}


function degree(num) {
    return num.toString(2).length - 1;
}

function point_mul(k, px, py) {
    let qx = Infinity;
    let qy = Infinity;

    for (let i = degree(k) - 1; i >= 0; i--) {
        let qxx = qx, qyy = qy;
        let parts = point_double(qx, qy);
        qx = parts[0]; qy = parts[1];
        //console.log(`2Q  (${i}): (${qxx},${qyy}) -> (${qx},${qy})`);

        if ((k & (1 << i)) != 0) {
            qxx = qx; qyy = qy;
            let pxx = px, pyy = py;
            parts = point_add(qx, qy, px, py);
            qx = parts[0]; qy = parts[1];
            //console.log(`Q+P (${i}): (${qxx},${qyy}) + (${pxx},${pyy}) -> (${qx},${qy})`);
        }
    }

    return [qx, qy];
}


function find_curve_n(px, py) {
console.log(px + "-" + py);
    for (let n = 2; n < extfield.order; n++) {
        let parts = point_mul(n, px, py);
        if (test_infinity(parts[0], parts[1])) {
            console.log(`N=${n} at (${parts[0]}, ${parts[1]})`);
        }
    }

    return -1;
}

//console.log(point_double(0b10, 0b1111));
//console.log(point_add(0b10, 0b1111, 0b1100, 0b1100));
//console.log(point_mul(202, 58, 89));

console.log(find_curve_n(0b11101110, 0b10101111));
