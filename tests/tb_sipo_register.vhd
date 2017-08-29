----------------------------------------------------------------------------------------------------
--  Testbench - SIPO Register
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

ENTITY tb_sipo_register IS
END tb_sipo_register;

ARCHITECTURE rtl OF tb_sipo_register IS 
    -- Import entity e_sipo_register 
    COMPONENT e_sipo_register  IS
        GENERIC (
            N : integer
        );
        PORT(
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            enable_i : IN std_logic;
            data_i : IN std_logic;
            data_o : OUT std_logic_vector(N-1 DOWNTO 0)
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL sipo: std_logic_vector(7 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, data: std_logic := '0';
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 200 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET : time := 0 ns;
  CONSTANT NUMBER_TESTS: natural := 20;
BEGIN
    -- Instantiate sipo register entity
    sipo_register: e_sipo_register GENERIC MAP (
            N => 8
        ) PORT MAP(
            clk_i => clk, 
            rst_i => rst,
            enable_i => enable,  
            data_i => data, 
            data_o => sipo
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

        enable <= '1'; 
        WAIT FOR PERIOD;
        data <= '0'; 
        WAIT FOR PERIOD;
        data <= '1'; 
        WAIT FOR PERIOD;
        data <= '1'; 
        WAIT FOR PERIOD;
        data <= '0'; 
        WAIT FOR PERIOD;
        data <= '1'; 
        WAIT FOR PERIOD;
        data <= '1'; 
        WAIT FOR PERIOD;
        data <= '0'; 
        WAIT FOR PERIOD;
        data <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0'; 
        
        WAIT FOR DELAY;

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;