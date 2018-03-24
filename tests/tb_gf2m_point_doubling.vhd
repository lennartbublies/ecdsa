----------------------------------------------------------------------------------------------------
--  Testbench - gf2m Point Doubling
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 18.08.2017
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
use ieee.math_real.all; -- FOR UNIFORM, TRUNC
USE std.textio.ALL;

use work.tld_ecdsa_package.all;

ENTITY tb_gf2m_point_doubling IS
END tb_gf2m_point_doubling;

ARCHITECTURE rtl OF tb_gf2m_point_doubling IS 
    -- Import entity e_k163_point_doubling 
    COMPONENT e_gf2m_point_doubling  IS
        GENERIC (
            MODULO : std_logic_vector(M DOWNTO 0)
        );
        PORT(
			clk_i: IN std_logic; 
			rst_i: IN std_logic; 
			enable_i: IN std_logic;
			x1_i: IN std_logic_vector(M-1 DOWNTO 0);
			y1_i: IN std_logic_vector(M-1 DOWNTO 0); 
			x2_io: INOUT std_logic_vector(M-1 DOWNTO 0);
			y2_o: OUT std_logic_vector(M-1 DOWNTO 0);
			ready_o: OUT std_logic
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL xP, yP, xR, yR:  std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, done: std_logic := '0';
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  CONSTANT ONE: std_logic_vector(M-1 DOWNTO 0) := (0 => '1', OTHERS=>'0');
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 200 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET : time := 0 ns;
  CONSTANT NUMBER_TESTS: natural := 20;
BEGIN
    -- Instantiate point doubling entity
    doubling: e_gf2m_point_doubling GENERIC MAP (
        MODULO => P
    ) PORT MAP(
            clk_i => clk, 
            rst_i => rst,
            enable_i => enable,  
            x1_i => xP, 
            y1_i => yP, 
            x2_io => xR, 
            y2_o => yR, 
            ready_o => done
        );

    -- Clock process FOR clk
    PROCESS 
    BEGIN
        WAIT FOR OFFSET;
        CLOCK_LOOP : LOOP
            clk <= '0';
            WAIT FOR (PERIOD *(1.0 - DUTY_CYCLE));
            clk <= '1';
            WAIT FOR (PERIOD * DUTY_CYCLE);
        END LOOP CLOCK_LOOP;
    END PROCESS;

    -- Start test cases
    tb : PROCESS        
        -- Internal signals
        VARIABLE TX_LOC : LINE;
        VARIABLE TX_STR : String(1 TO 4096);
    BEGIN
        -- Disable computation and reset all entities
        enable <= '0'; 
        rst <= '1';
        WAIT FOR PERIOD;
        rst <= '0';
        WAIT FOR PERIOD;

        -- Test #1:
        xP <= "000000010"; 
        yP <= "000001111";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "010010101" or (yR /= "100011000") ) THEN 
            write(TX_LOC,string'("TEST #1 ERROR!!! (010010101, 100011000) != (000000010, 000001111)^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;

        WAIT FOR 2*PERIOD;
        
        -- Test #2:
        xP <= "111111111"; 
        yP <= "111111111";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "111111111" or (yR /= "111111111") ) THEN 
            write(TX_LOC,string'("TEST #2 ERROR!!! (111111111, 111111111) != (111111111, 111111111)^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;

        WAIT FOR 2*PERIOD;
          
        -- Test #3:
        xP <= "011101110"; 
        yP <= "010101111";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "011001101" or (yR /= "100010001") ) THEN 
            write(TX_LOC,string'("TEST #3 ERROR!!! (011001101, 100010001) != (011101110, 010101111)^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;

        WAIT FOR 2*PERIOD;

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;