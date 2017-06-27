`include "ks5.v"

module ks_tb();
reg  [0:4] a;
reg  [0:4] b;
wire [0:8] d;

initial begin
	$display("time  a    b    d");
	$monitor("%g     %x   %x   %x", $time, a, b, d);
#5 	a = 'h 6;
	b = 'h 2;
#10 $display("----------");
	$finish;
end

ks5 mul(a, b, d);

endmodule


