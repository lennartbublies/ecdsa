--------------------------------------------------------------------------------
-- Test_Simple_K163_point_multiplication 
-- VHDL Test Bench for module: K163_point_multiplication.vhd 
--  
--
-- Executes NUMBER_TESTS operations with random values of K. 
-- Test k.P = (k-1).P + P, for a fixed known P.
--
-- Finally k = n-1, being N= order of point P and test:
-- k.P = (n-1).P = -P = (xP, xP+yP)
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
use ieee.math_real.all; -- for UNIFORM, TRUNC
USE std.textio.ALL;

use work.K163_package.all;

ENTITY test_simple_point_multiplication IS
END test_simple_point_multiplication;

ARCHITECTURE behavior OF test_simple_point_multiplication IS 

  -- Component Declaration for the Unit Under Test (UUT)
  component K163_point_multiplication is
  port (
    xP, yP, k: in std_logic_vector(M-1 downto 0);
    clk, reset, start: in std_logic;
    xQ, yQ: inout std_logic_vector(M-1 downto 0);
    done: out std_logic );
  end component K163_point_multiplication;

  component K163_addition is
  port(
    x1, y1, x2, y2: in std_logic_vector(m-1 downto 0);
    clk, reset, start: in std_logic;
    x3: inout std_logic_vector(m-1 downto 0);
    y3: out std_logic_vector(m-1 downto 0);
    done: out std_logic );
  end component K163_addition;

  -- Internal signals
  SIGNAL xP, yP, k, k_minus_1, xQ1, yQ1, xQ2, yQ2, xQ3, yQ3, xP_plus_yP:  std_logic_vector(M-1 downto 0) := (others=>'0');
  SIGNAL clk, reset, start, start_add, done, done_2, done_add: std_logic := '0';
  constant ZERO: std_logic_vector(M-1 downto 0) := (others=>'0');
  constant ONE: std_logic_vector(M-1 downto 0) := (0 => '1', others=>'0');
  constant DELAY : time := 100 ns;
  constant PERIOD : time := 200 ns;
  constant DUTY_CYCLE : real := 0.5;
  constant OFFSET : time := 0 ns;
  constant NUMBER_TESTS: natural := 20;
  constant P_order : std_logic_vector(M-1 downto 0) := "100" & x"000000000000000000020108a2e0cc0d99f8a5ee";
  
BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut1: K163_point_multiplication PORT MAP( xP => xP, yP => yP, k => k,
                    clk => clk, reset => reset, start => start,
                    xQ => xQ1, yQ => yQ1, done => done );

  uut2: K163_point_multiplication PORT MAP( xP => xP, yP => yP, k => k_minus_1,
                    clk => clk, reset => reset, start => start,
                    xQ => xQ2, yQ => yQ2, done => done_2 );

  uut3: K163_addition port map( x1=> xP, y1 => yP, x2 => xQ2, y2 => yQ2,
                    clk => clk, reset => reset, start => start_add,
                    x3 => xQ3, y3 => yQ3,done => done_add );

 k_minus_1 <= k - '1';
 xP <= "010" & x"fe13c0537bbc11acaa07d793de4e6d5e5c94eee8";
 yP <= "010" & x"89070fb05d38ff58321f2e800536d538ccdaa3d9";
 xP_plus_yP <= xP xor yP;

  PROCESS -- clock process for clk
  BEGIN
  WAIT for OFFSET;
  CLOCK_LOOP : LOOP
     clk <= '0';
     WAIT FOR (PERIOD *(1.0 - DUTY_CYCLE));
     clk <= '1';
     WAIT FOR (PERIOD * DUTY_CYCLE);
  END LOOP CLOCK_LOOP;
  END PROCESS;

  tb_proc : PROCESS --generate values
    PROCEDURE gen_random(X : out std_logic_vector (M-1 DownTo 0); w: natural; s1, s2: inout Natural) IS
      VARIABLE i_x, aux: integer;
      VARIABLE rand: real;
    BEGIN
        aux := W/16;
        for i in 1 to aux loop
          UNIFORM(s1, s2, rand);
          i_x := INTEGER(TRUNC(rand * real(2**16)));
          x(i*16-1 downto (i-1)*16) := CONV_STD_LOGIC_VECTOR (i_x, 16);
        end loop;
        UNIFORM(s1, s2, rand);
        i_x := INTEGER(TRUNC(rand * real(2**(w-aux*16))));
        x(w-1 downto aux*16) := CONV_STD_LOGIC_VECTOR (i_x, (w-aux*16));
    END PROCEDURE;
    VARIABLE TX_LOC : LINE;
    VARIABLE TX_STR : String(1 to 4096);
    VARIABLE seed1, seed2: positive; 
    VARIABLE i_x, i_y, i_p, i_z, i_yz_modp: integer;
    VARIABLE cycles, max_cycles, min_cycles, total_cycles: integer := 0;
    VARIABLE avg_cycles: real;
    VARIABLE initial_time, final_time: time;
    VARIABLE xx: std_logic_vector (M-1 DownTo 0) ;

  BEGIN
    min_cycles:= 2**20;
    start <= '0'; reset <= '1';
    WAIT FOR PERIOD;
    reset <= '0';
    WAIT FOR PERIOD;
    
    for I in 1 to NUMBER_TESTS loop
      gen_random(xx, M, seed1, seed2);
      while (xx >= P_order) loop gen_random(xx, M, seed1, seed2); end loop;
      k <= xx;
      start <= '1'; initial_time := now;
      WAIT FOR PERIOD;
      start <= '0';
      wait until (done = '1') and (done_2 = '1');
      final_time := now;
      cycles := (final_time - initial_time)/PERIOD;
      total_cycles := total_cycles+cycles;
      --ASSERT (FALSE) REPORT "Number of Cycles: " & integer'image(cycles) & "  TotalCycles: " & integer'image(total_cycles) SEVERITY WARNING;
      if cycles > max_cycles then  max_cycles:= cycles; end if;
      if cycles < min_cycles then  min_cycles:= cycles; end if;
      WAIT FOR PERIOD;
      start_add <= '1';
      WAIT FOR PERIOD;
      start_add <= '0';
      wait until done_add = '1';

      WAIT FOR 2*PERIOD;

      IF ( xQ1 /= xQ3 or (yQ1 /= yQ3) ) THEN 
        write(TX_LOC,string'("ERROR!!! k.P /= (k-1)*P + P; k = ")); write(TX_LOC, k);
        write(TX_LOC, string'(" )"));
        TX_STR(TX_LOC.all'range) := TX_LOC.all;
        Deallocate(TX_LOC);
        ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
      END IF;  
     end loop;
    WAIT FOR DELAY;
 
    k <= P_order;
    start <= '1'; 
    WAIT FOR PERIOD;
    start <= '0';
    wait until done = '1';
    IF ( xQ1 /= xP or (yQ1 /= xP_plus_yP) ) THEN 
      write(TX_LOC,string'("ERROR!!! k.P = (n-1).P = -P = (xP, xP+yP) with n order of P")); write(TX_LOC, k);
      write(TX_LOC, string'(" )"));
      TX_STR(TX_LOC.all'range) := TX_LOC.all;
      Deallocate(TX_LOC);
      ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
    END IF;  
    WAIT FOR 10*PERIOD;
    
    avg_cycles := real(total_cycles)/real(NUMBER_TESTS);
    ASSERT (FALSE) REPORT
    "Simulation successful!.  MinCycles: " & integer'image(min_cycles) &
    "  MaxCycles: " & integer'image(max_cycles) & "  TotalCycles: " & integer'image(total_cycles) &
    "  AvgCycles: " & real'image(avg_cycles)
    SEVERITY FAILURE;
  END PROCESS;

END;