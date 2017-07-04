/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * Portions Copyright (C) Philipp Kewisch, 2016 */

"use strict";
global.String.prototype.padStart = function(len, padString) {
    return ((padString || " ").repeat(len) + this).substr(-len);
};

exports.toelem = function toelem(y, elemsize) {
    if (isNaN(y)) {
        return `{ ${Array(elemsize).fill("0xFF").join(", ")} }`;
    }
    let hexstr = y.toString(16);
    if (hexstr.length % 2) {
        hexstr = "0" + hexstr;
    }

    let parts = hexstr.match(/.{1,2}/g).map(p => "0x" + p);
    while (parts.length < elemsize) { parts.unshift("0x00"); }
    
    return `{ ${parts.reverse().join(", ")} }`;
};

exports.header = function header(elems, elemsize, offset) {
    let strres = "/*         ";
    for (let i = offset; i < offset+elems; i++) {
        strres += "      " + "      ".repeat(elemsize - 1) +  i.toString().padStart(4)
    }
    strres += " */";
    return strres;
};

exports.chunk = function chunk(arr, num) {
    return arr.reduce((prev, cur, idx) => {
        if ((idx % num) == 0) {
            prev.push(arr.slice(idx, idx+num));
        }
        return prev;
    }, []);
};
exports.polystring = function polystring(coeffs) {
    return coeffs.map((x, xi) => {
        if (!x) return null;
        return (x != 1 || xi == 0 ? x : "") + (xi > 0 ? "x" : "") + (xi > 1 ? "^" + xi : "");
    }).filter(Boolean).reverse().join(" + ");
};
