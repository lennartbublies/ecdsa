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

use work.e_gf2m_point_doubling_package.all;

ENTITY tb_gf2m_point_doubling IS
END tb_gf2m_point_doubling;

ARCHITECTURE rtl OF tb_gf2m_point_doubling IS 
    -- Import entity e_gf2m_point_doubling 
    COMPONENT e_gf2m_point_doubling  IS
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
    doubling: e_gf2m_point_doubling PORT MAP(
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
    BEGIN
        -- Disable computation and reset all entities
        enable <= '0'; 
        rst <= '1';
        WAIT FOR PERIOD;
        rst <= '0';
        WAIT FOR PERIOD;

        --xP <= "000000010"; 
        --yP <= "000001111";
        -- Expected results
        --xR <= "010010101";
        --yR <= "100011000";

        --xP <= "111111111"; 
        --yP <= "111111111";
        -- Expected results
        --xR <= "111111111";
        --yR <= "111111111";
        
        xP <= "011101110"; 
        yP <= "010101111";
        -- Expected results
        --xR <= "111111111";
        --yR <= "111111111";

        -- Start computation
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        WAIT FOR DELAY;

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;