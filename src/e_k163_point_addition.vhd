----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Point Addition IN K163
--
--  Ports:
-- 
--  Source:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/K163_addition.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 27.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- K163 elliptic curve point addition package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE package_K_163 is
  CONSTANT M: natural := 163;
  CONSTANT logm: natural := 8;
END package_K_163;

------------------------------------------------------------
-- K163 elliptic curve point addition
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.package_K_163.all;

ENTITY e_k163_addition is
    PORT(
        -- Input signals
        x1, y1, x2, y2: IN std_logic_vector(m-1 DOWNTO 0);
        clk, rst, start: IN std_logic;
        
        -- Output signals
        x3: INOUT std_logic_vector(m-1 DOWNTO 0);
        y3: OUT std_logic_vector(m-1 DOWNTO 0);
        ready: OUT std_logic
    );
END e_k163_addition;

ARCHITECTURE rtl of e_k163_addition is
  COMPONENT interleaved_mult is
  PORT (
    A, B: IN std_logic_vector (M-1 DOWNTO 0);
    clk, rst, start: IN std_logic; 
    Z: OUT std_logic_vector (M-1 DOWNTO 0);
    ready: OUT std_logic );
  END COMPONENT;
  
  COMPONENT binary_algorithm_polynomials is
  PORT(
    g, h: IN std_logic_vector(m-1 DOWNTO 0);
    clk, rst, start: IN std_logic;  
    z: OUT std_logic_vector(m-1 DOWNTO 0);
    ready: OUT std_logic );
  END COMPONENT;

  COMPONENT classic_squarer is
  PORT (
    a: IN std_logic_vector(M-1 DOWNTO 0);
    c: OUT std_logic_vector(M-1 DOWNTO 0));
  END COMPONENT;

  SIGNAL div_in1, div_in2, lambda, lambda_square, 
  mult_in2, mult_out: std_logic_vector(m-1 DOWNTO 0);
  SIGNAL start_div, div_done, start_mult, mult_done: std_logic;
  subtype states is natural RANGE 0 TO 6;
  SIGNAL current_state: states;

BEGIN

  divider_inputs: FOR i IN 0 TO m-1 GENERATE 
    div_in1(i) <= y1(i) xor y2(i);
    div_in2(i) <= x1(i) xor x2(i);
  END GENERATE;

  divider: binary_algorithm_polynomials PORT MAP( g => div_in1, h => div_in2, 
                              clk => clk, rst => rst, start => start_div, 
                              z => lambda, ready => div_done);

  lambda_square_computation: classic_squarer PORT MAP( a => lambda, c => lambda_square);

  x_output: FOR i IN 1 TO 162 GENERATE
    x3(i) <= lambda_square(i) xor lambda(i) xor div_in2(i);
  END GENERATE;

  x3(0) <= not(lambda_square(0) xor lambda(0) xor div_in2(0));

  multiplier_inputs: FOR i IN 0 TO 162 GENERATE
    mult_in2(i) <= x1(i) xor x3(i);
  END GENERATE;

  multiplier: interleaved_mult PORT MAP( a => lambda, b => mult_in2, 
                    clk => clk, rst => rst, start => start_mult, 
                    z => mult_out, ready => mult_done);

  y_output: FOR i IN 0 TO 162 GENERATE
    y3(i) <= mult_out(i) xor x3(i) xor y1(i);
  END GENERATE;

  control_unit: PROCESS(clk, rst, current_state)
  BEGIN
  CASE current_state is
    WHEN 0 TO 1 => start_div <= '0'; start_mult <= '0'; ready <= '1';
    WHEN 2 => start_div <= '1'; start_mult <= '0'; ready <= '0';
    WHEN 3 => start_div <= '0'; start_mult <= '0'; ready <= '0';
    WHEN 4 => start_div <= '0'; start_mult <= '1'; ready <= '0';
    WHEN 5 TO 6 => start_div <= '0'; start_mult <= '0'; ready <= '0';
  END CASE;

  IF rst = '1' THEN current_state <= 0;
  ELSIF clk'event and clk = '1' THEN
    CASE current_state is
      WHEN 0 => IF start = '0' THEN current_state <= 1; END IF;
      WHEN 1 => IF start = '1' THEN current_state <= 2; END IF; 
      WHEN 2 => current_state <= 3;
      WHEN 3 => IF div_done = '1' THEN current_state <= 4; END IF;
      WHEN 4 => current_state <= 5;
      WHEN 5 => IF mult_done = '1' THEN current_state <= 6; END IF;
      WHEN 6 => current_state <= 0;
    END CASE;
  END IF;
  END PROCESS;
END rtl;
