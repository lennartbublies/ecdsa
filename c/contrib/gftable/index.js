/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

"use strict";

let rye = require("rye");
let helpers = require("./helpers");

function strtable2d(name, elems, elemsize, op, offset) {
    offset = offset || 0;
    elems -= offset;

    console.error(`Generating ${name} table with ${elems} elements of size ${elemsize}`);
    let strres = `static const uint8_t ${name}[${elems}][${elems}][${elemsize}] = {\n\t`;

    strres += helpers.header(elems, elemsize, offset) + "\n\t";

    let xtable = [];
    for (let x = offset; x < offset+elems; x++) {
        let ytable = [];
        for (let y = offset; y < offset+elems; y++) {
            ytable.push(helpers.toelem(op(x, y), elemsize));
        }
        xtable.push(`/* ${x.toString().padStart(4)} */ { ${ytable.join(", ")} }`);
    }
    return strres + xtable.join(",\n\t") + "\n};";
}


function strtable1d(name, elems, elemsize, op, offset) {
    offset = offset || 0;
    elems -= offset;

    console.error(`Generating ${name} table with ${elems} elements of size ${elemsize}`);

    let xtable = [];
    for (let x = offset; x < offset+elems; x++) {
        xtable.push(helpers.toelem(op(x), elemsize));
    }

    return `static const uint8_t ${name}[${elems}][${elemsize}] = {\n\t` +
           helpers.chunk(xtable, 8).map(x => x.join(", ")).join(",\n\t") + "\n};";
}

function pointtable(name, elems, elemsize, op, offset, chunkcount) {
    offset = offset || 0;
    chunkcount = chunkcount || 4;
    elems -= offset;

    console.error(`Generating ${name} table with ${elems} elements of size ${elemsize}`);

    let points = [];
    for (let x = offset; x < elems+offset; x++) {
        for (let y = offset; y < elems+offset; y++) {
            if (op(x, y)) {
                points.push(`{ ${helpers.toelem(x, elemsize)}, ${helpers.toelem(y, elemsize)} }`);
            }
        }
    }

    return `static const uint8_t ${name}[${points.length}][2][${elemsize}] = {\n\t` +
           helpers.chunk(points, chunkcount).map(x => x.join(", ")).join(",\n\t") + "\n};" +
           `\nstatic const int ${name}_size = ${points.length};`;

}

function oncurve(f, x, y, a, b) {
    // x^3 + ax^2 + b
    let x2 = f.mul(x, x);
    let x3 = f.mul(x2, x);
    let ax2 = f.mul(a, x2);
    let x3_ax2 = f.add(x3, ax2);
    let x3_ax2_b = f.add(x3_ax2, b);

    // y^2 + xy
    let y2 = f.mul(y, y);
    let xy = f.mul(x, y);
    let y2_xy = f.add(y2, xy);

    //console.log(y2_xy + " = y^2 + xy = x^3 + ax^2 + b = " +x3_ax2_b);
    return y2_xy == x3_ax2_b;
}
            
function printtables(prime, coeffs) {
    let m = coeffs.length - 1;
    let elemsize = Math.ceil(m / 8);
    let size = Math.pow(prime, m);
    console.error(`Calculating GF(${prime}^${m}) with ${helpers.polystring(coeffs)} element size ${elemsize}`);

    let field = new rye.PrimeField(2); // GF(2)
    let ring = new rye.PolynomRing(field);
    let extfield = new rye.FactorRing(ring, ring.polynom(coeffs)); // GF(2^9)

    let basename = `gf_${prime}x${m}_`;

    console.log(`#ifndef __GF_TABLES_${prime}X${m}_H`);
    console.log(`#define __GF_TABLES_${prime}X${m}_H`);
    console.log("");

    console.log(strtable2d(basename + "add", size, elemsize, (a, b) => extfield.add(a, b)));
    console.log(strtable2d(basename + "mul", size, 2 * elemsize, (a, b) => {
        let pa = ring.polynom(a.toString(2).split("").reverse());
        let pb = ring.polynom(b.toString(2).split("").reverse());
        let pres = ring.mul(pa, pb);
        let res = pres.coefs().reverse().join("");
        return new Number("0b" + res);
    }));
    console.log(strtable1d(basename + "inv_mod", size, elemsize, (a) => extfield.inv(a)));
    console.log(strtable2d(basename + "mul_mod", size, elemsize, (a, b) => extfield.mul(a, b)));
    console.log(pointtable(basename + "curve_point", size, elemsize, (x, y) => oncurve(extfield, x, y, 1, 1)));

    console.log("");
    console.log("#endif");
}

printtables(2, [1, 1, 0, 0, 0, 0, 0, 0, 0, 1]);
//printtables(2, [1, 1]);
//printtables(2, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
