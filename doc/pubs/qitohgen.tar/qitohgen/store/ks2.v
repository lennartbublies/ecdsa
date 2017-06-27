`ifndef __KS_2_V__
`define __KS_2_V__
module ks2(
	a,         // Input 1
	b,         // Input 2 
	d          // Output
);
input  wire [0:1] a; 
input  wire [0:1] b;
output wire [0:2] d;

assign d[0] = a[0] & b[0];
assign d[2] = a[1] & b[1];
assign d[1] = ((a[1] ^ a[0]) & (b[1] ^ b[0])) ^ d[0] ^ d[2];

endmodule
`endif
