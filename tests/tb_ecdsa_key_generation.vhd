----------------------------------------------------------------------------------------------------
--  Testbench - ECDSA Key Generation 
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

ENTITY tb_ecdsa_key_generation IS
END tb_ecdsa_key_generation;

ARCHITECTURE rtl OF tb_ecdsa_key_generation IS 
    -- Import entity e_ecdsa_key_generation
    COMPONENT e_ecdsa_key_generation IS
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic;
            enable_i: IN std_logic;
            k_i: IN std_logic_vector(M-1 DOWNTO 0);
            xQ_o: INOUT std_logic_vector(M-1 DOWNTO 0);
            yQ_o: INOUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL k, xQ, yQ:  std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, done: std_logic := '0';
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  CONSTANT ONE: std_logic_vector(M-1 DOWNTO 0) := (0 => '1', OTHERS=>'0');
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 200 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET : time := 0 ns;
BEGIN
    -- Instantiate point addition entity
    uut3: e_ecdsa_key_generation PORT MAP ( 
        clk_i => clk, 
        rst_i => rst, 
        k_i => k,
        xQ_o => xQ,
        yQ_o => yQ,
        enable_i => enable,
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
        -- Set point P and Q for computation
        k <= "000" & x"CD06203260EEE9549351BD29733E7D1E2ED49D88"; 

        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;