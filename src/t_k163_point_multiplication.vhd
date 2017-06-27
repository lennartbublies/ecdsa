----------------------------------------------------------------------------
-- Top level FOR top_K163_point_multiplication.vhd
-- Point multiplication IN K163 (K163_point_multiplication.vhd)
--
-- Introduces the point coordinates and k through the same PORT
--
----------------------------------------------------------------------------

------------------------------------------------------------
-- top K163_point_multiplication
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

ENTITY top_K163_point_multiplication is
PORT (
  inData: IN std_logic_vector(162 DOWNTO 0);  
  xP_data, yP_data, k_data: IN std_logic;
  clk, rst, start: IN std_logic;
  outData: INOUT std_logic_vector(162 DOWNTO 0);
  xQ_or_yQ: IN std_logic;
  ready: OUT std_logic
  );
END top_K163_point_multiplication;

ARCHITECTURE rtl of top_K163_point_multiplication is

  COMPONENT K163_point_multiplication is
  PORT (
    xP, yP, k: IN std_logic_vector(162 DOWNTO 0);
    clk, rst, start: IN std_logic;
    xQ, yQ: INOUT std_logic_vector(162 DOWNTO 0);
    ready: OUT std_logic
    );
  END COMPONENT K163_point_multiplication;


  SIGNAL xP, yP, k, xQ, yQ: std_logic_vector (162 DOWNTO 0);

BEGIN

  theComp: K163_point_multiplication PORT MAP(
                    xP => xP, yP => yP, k => k,
                    clk => clk, rst => rst, start => start,
                    xQ => xQ, yQ => yQ, ready => ready );

  registers: PROCESS(clk)
  BEGIN
  IF clk' event and clk = '1' THEN 
    IF xP_data = '1' THEN xP <= inData; END IF;
    IF yP_data = '1' THEN yP <= inData; END IF;
    IF k_data = '1'  THEN k <= inData; END IF;
  END IF;
  END PROCESS;

  outData <= xQ WHEN xQ_or_yQ = '0' ELSE yQ;

END rtl;
