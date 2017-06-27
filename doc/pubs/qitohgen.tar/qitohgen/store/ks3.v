`ifndef __KS_3_V__
`define __KS_3_V__
`include "ks2.v"
module ks3(a, b, d);

input wire [0:2] a;
input wire [0:2] b;
output wire [0:4] d;

wire m1;
wire [0:2] m2;
wire [0:2] m3;
wire [0:1] ahl;
wire [0:1] bhl;

ks2 ksm1(a[0:1], b[0:1], m2);
assign m1 = a[2] & b[2];
assign ahl[0] = a[2] ^ a[0];
assign ahl[1] = a[1];
assign bhl[0] = b[2] ^ b[0];
assign bhl[1] = b[1];
ks2 ksm3(ahl, bhl, m3);

assign  d[0] = m2[0];   
assign  d[1] = m2[1];   
assign  d[2] = m2[2] ^ m1[0] ^ m2[0] ^ m3[0];   
assign  d[3] = m2[1] ^ m3[1];   
assign  d[4] = m2[2] ^ m3[2] ^ m1[0];   
endmodule
`endif
