--------------------------------------------------------------------------------
-- Test eea_inversion algorithm
-- VHDL Test Bench for module: eea_inversion.vhd 
-- for GF(2^m) divider (ch7) 
--
-- Executes NUMBER_TESTS operations with random values. 
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
use work.eea_inversion_package.all;

ENTITY test_eea_inversion IS
END test_eea_inversion;

ARCHITECTURE behavior OF test_eea_inversion IS 

  -- a multiplier is instantiated to check the results
  COMPONENT classic_multiplication
  PORT(
    a : IN std_logic_vector(M-1 downto 0);
    b : IN std_logic_vector(M-1 downto 0);
    c : OUT std_logic_vector(M-1 downto 0)
    );
  END COMPONENT;
  -- Component Declaration for the Unit Under Test (UUT2)
  COMPONENT eea_inversion is
  port (
    a: in std_logic_vector (M-1 downto 0);
    clk, reset, start: in std_logic; 
    Z: out std_logic_vector (M-1 downto 0);
    done: out std_logic
  );
  END COMPONENT eea_inversion;
  
  -- Internal signals
  SIGNAL x, z, z_by_x :  std_logic_vector(M-1 downto 0) := (others=>'0');
  SIGNAL clk, reset, start, done: std_logic;
  constant ZERO: std_logic_vector(M-1 downto 0) := (others=>'0');
  constant ONE: std_logic_vector(M-1 downto 0) := (0 => '1', others=>'0');
  constant DELAY : time := 100 ns;
  constant PERIOD : time := 200 ns;
  constant DUTY_CYCLE : real := 0.5;
  constant OFFSET : time := 0 ns;
  constant NUMBER_TESTS: natural := 10;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut1:  eea_inversion PORT MAP(a => x, 
                          clk => clk, reset => reset, start => start,
                          z => z, done => done);
  uut2: classic_multiplication PORT MAP( a => x, b => z, c => z_by_x );

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
      while (xx = ZERO) loop gen_random(xx, M, seed1, seed2); end loop;
      x <= xx;

      start <= '1'; initial_time := now;
      WAIT FOR PERIOD;
      start <= '0';
      wait until done = '1';
      final_time := now;
      cycles := (final_time - initial_time)/PERIOD;
      total_cycles := total_cycles+cycles;
      --ASSERT (FALSE) REPORT "Number of Cycles: " & integer'image(cycles) & "  TotalCycles: " & integer'image(total_cycles) SEVERITY WARNING;
      if cycles > max_cycles then  max_cycles:= cycles; end if;
      if cycles < min_cycles then  min_cycles:= cycles; end if;


      WAIT FOR 2*PERIOD;

      IF ( ONE /= z_by_x) THEN 
        write(TX_LOC,string'("ERROR!!! z_by_x=")); write(TX_LOC, z_by_x);
        write(TX_LOC,string'("/= ONE=")); 
        write(TX_LOC,string'("( z=")); write(TX_LOC, z);
        write(TX_LOC,string'(") using: ( A =")); write(TX_LOC, x);
        write(TX_LOC, string'(", F = 1")); write(TX_LOC, F);
        write(TX_LOC, string'(" )"));
        TX_STR(TX_LOC.all'range) := TX_LOC.all;
        Deallocate(TX_LOC);
        ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
      END IF;  
 
    end loop;
    WAIT FOR DELAY;
    avg_cycles := real(total_cycles)/real(NUMBER_TESTS);
    ASSERT (FALSE) REPORT
    "Simulation successful!.  MinCycles: " & integer'image(min_cycles) &
    "  MaxCycles: " & integer'image(max_cycles) & "  TotalCycles: " & integer'image(total_cycles) &
    "  AvgCycles: " & real'image(avg_cycles)
    SEVERITY FAILURE;
  END PROCESS;

END;