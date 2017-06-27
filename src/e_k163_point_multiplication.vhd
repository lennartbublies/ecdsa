----------------------------------------------------------------------------
-- Point multiplication IN K163 (K163_point_multiplication.vhd)
--
-- Uses the entities K163_addition and two classic squarer
--
----------------------------------------------------------------------------
 
------------------------------------------------------------
-- K163_package
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
PACKAGE K163_package is
  CONSTANT M: natural := 163;
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS => '0');
END K163_package;

------------------------------------------------------------
-- K163_point_multiplication
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.K163_package.all;
ENTITY K163_point_multiplication is
PORT (
  xP, yP, k: IN std_logic_vector(M-1 DOWNTO 0);
  clk, rst, start: IN std_logic;
  xQ, yQ: INOUT std_logic_vector(M-1 DOWNTO 0);
  ready: OUT std_logic
  );
END K163_point_multiplication;

ARCHITECTURE rtl of K163_point_multiplication is

  COMPONENT K163_addition is
  PORT(
  x1, y1, x2, y2: IN std_logic_vector(m-1 DOWNTO 0);
  clk, rst, start: IN std_logic;
  x3: INOUT std_logic_vector(m-1 DOWNTO 0);
  y3: OUT std_logic_vector(m-1 DOWNTO 0);
  ready: OUT std_logic );
  END COMPONENT;

  --COMPONENT square_163_7_6_3 is
  --PORT (
  --a: IN std_logic_vector(162 DOWNTO 0);
  --z: OUT std_logic_vector(162 DOWNTO 0));
  --END COMPONENT;

  COMPONENT classic_squarer is
  PORT (
    a: IN std_logic_vector(M-1 DOWNTO 0);
    c: OUT std_logic_vector(M-1 DOWNTO 0) );
  END COMPONENT;

  SIGNAL a, next_a, a_div_2: std_logic_vector(m DOWNTO 0);
  SIGNAL b, next_b: std_logic_vector(m-1 DOWNTO 0);
  SIGNAL xxP, yyP, next_xQ, next_yQ, xxPxoryyP, square_xxP, square_yyP, y1, x3, y3: std_logic_vector(m-1 DOWNTO 0);

  SIGNAL ce_P, ce_Q, ce_ab, load, sel_1, start_addition, addition_done, carry, Q_infinity, aEqual0, bEqual0, a1xorb0: std_logic;

  SIGNAL sel_2: std_logic_vector(1 DOWNTO 0);

  subtype states is natural RANGE 0 TO 12;
  SIGNAL current_state: states;

BEGIN

  xor_gates: FOR i IN 0 TO m-1 GENERATE xxPxoryyP(i) <=xxP(i) xor yyP(i); END GENERATE;

  WITH sel_1 SELECT y1 <= yyP WHEN '0', xxPxoryyP WHEN OTHERS;
  WITH sel_2 SELECT next_yQ <= y3 WHEN "00", yyP WHEN "01", xxPxoryyP WHEN OTHERS;
  WITH sel_2 SELECT next_xQ <= x3 WHEN "00", xxP WHEN OTHERS;

  first_component: K163_addition PORT MAP( x1 => xxP, y1 => y1, 
                      x2 => xQ,  y2 => yQ, clk => clk, rst => rst,
                      start => start_addition, x3 => x3, y3 => y3, 
                      ready => addition_done );

  second_component: classic_squarer PORT MAP( a => xxP, c => square_xxP);

  third_component: classic_squarer PORT MAP( a => yyP, c => square_yyP);

  register_P: PROCESS(clk)
  BEGIN
  IF clk' event and clk = '1' THEN 
    IF load = '1' THEN xxP <= xP; yyP <= yP;
    ELSIF ce_P = '1' THEN xxP <= square_xxP; yyP <= square_yyP; 
    END IF;
  END IF;
  END PROCESS;

  register_Q: PROCESS(clk)
  BEGIN
  IF clk' event and clk = '1' THEN 
    IF load = '1' THEN Q_infinity <= '1';
    ELSIF ce_Q = '1' THEN xQ <= next_xQ; yQ <= next_yQ; Q_infinity <= '0'; 
    END IF;
  END IF;
  END PROCESS;

  divide_by_2: FOR i IN 0 TO m-1 GENERATE a_div_2(i) <= a(i+1);END GENERATE;
  a_div_2(m) <= a(m);
  next_a <= (b(m-1)&b) + a_div_2 + carry;
  next_b <= zero - (a_div_2(m-1 DOWNTO 0) + carry);

  register_ab: PROCESS(clk)
  BEGIN
  IF clk' event and clk = '1' THEN 
    IF load = '1' THEN a <= ('0'&k); b <= zero;
    ELSIF ce_ab = '1' THEN a <= next_a; b <= next_b; END IF;
    END IF;
  END PROCESS;

  aEqual0 <= '1' WHEN a = 0 ELSE '0';
  bEqual0 <= '1' WHEN b = 0 ELSE '0';
  a1xorb0 <= a(1) xor b(0);

  control_unit: PROCESS(clk, rst, current_state, addition_done, aEqual0, bEqual0, a(0), a1xorb0, Q_infinity)
  BEGIN
  CASE current_state is
    WHEN 0 TO 1 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready <= '1';
    WHEN 2 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '1'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready <= '0';
    WHEN 3 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready <= '0';
    WHEN 4 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '1'; ce_Q <= '0'; ce_ab <= '1'; start_addition <= '0'; ready <= '0';
    WHEN 5 => sel_1 <= '0'; sel_2 <= "01"; carry <= '0'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready <= '0';
    WHEN 6 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '1'; ready <= '0';
    WHEN 7 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready <= '0';
    WHEN 8 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready <= '0';
    WHEN 9 => sel_1 <= '1'; sel_2 <= "10"; carry <= '1'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready <= '0';
    WHEN 10 => sel_1 <= '1'; sel_2 <= "00"; carry <= '1'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '1'; ready <= '0';
    WHEN 11 => sel_1 <= '1'; sel_2 <= "00"; carry <= '1'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready <= '0';
    WHEN 12 => sel_1 <= '1'; sel_2 <= "00"; carry <= '1'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready <= '0';
  END CASE;
  
  IF rst = '1' THEN current_state <= 0;
  ELSIF clk'event and clk = '1' THEN
    CASE current_state is
      WHEN 0 => IF start = '0' THEN current_state <= 1; END IF;
      WHEN 1 => IF start = '1' THEN current_state <= 2; END IF;
      WHEN 2 => current_state <= 3;
      WHEN 3 => IF (aEqual0 = '1') and (bEqual0 = '1') THEN current_state <= 0;
               ELSIF a(0) = '0' THEN current_state <= 4;
               ELSIF (a1xorb0 = '0') and (Q_infinity = '1') THEN current_state <= 5;
               ELSIF (a1xorb0 = '0') and (Q_infinity = '0') THEN current_state <= 6;
               ELSIF (a1xorb0 = '1') and (Q_infinity = '1') THEN current_state <= 9;
               ELSE current_state <= 10;
               END IF;
      WHEN 4 => current_state <= 3;
      WHEN 5 => current_state <= 3;
      WHEN 6 => current_state <= 7;
      WHEN 7 => IF addition_done = '1' THEN current_state <= 8; END IF;
      WHEN 8 => current_state <= 3;
      WHEN 9 => current_state <= 3;
      WHEN 10 => current_state <= 11;
      WHEN 11 => IF addition_done = '1' THEN current_state <= 12; END IF;
      WHEN 12 => current_state <= 3;
    END CASE;
  END IF;

  END PROCESS;
END rtl;
