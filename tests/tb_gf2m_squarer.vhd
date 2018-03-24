--------------------------------------------------------------------------------
--  Testbench - gf2m squarer 
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 18.08.2017
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
use ieee.math_real.all; -- FOR UNIFORM, TRUNC
USE std.textio.ALL;
use work.tld_ecdsa_package.all;

ENTITY tb_gf2m_squarer IS
END tb_gf2m_squarer;

ARCHITECTURE behavior OF tb_gf2m_squarer IS 
    -- Import entity e_gf2m_classic_squarer
    COMPONENT e_gf2m_classic_squarer IS
        GENERIC (
            MODULO : std_logic_vector(M-1 DOWNTO 0)
        );
        PORT(
            a_i: IN std_logic_vector(M-1 DOWNTO 0);
            c_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    end COMPONENT;

    --Inputs
    SIGNAL a :  std_logic_vector(m-1 downto 0) := (others=>'0');
    SIGNAL clk, rst, enable: std_logic;

    --Outputs
    SIGNAL c :  std_logic_vector(m-1 downto 0);
    SIGNAL done: std_logic;

    constant PERIOD : time := 200 ns;
    constant DUTY_CYCLE : real := 0.5;
    constant OFFSET : time := 0 ns;
BEGIN
    -- Instantiate squarer
    uut: e_gf2m_classic_squarer GENERIC MAP (
            MODULO => P(M-1 DOWNTO 0)
    ) PORT MAP( 
        a_i => a, 
        c_o => c
    );

    -- Clock process for clk
    PROCESS 
    BEGIN
        WAIT for OFFSET;
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
        a <= "000000010";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT FOR PERIOD;
        
        IF ( c /= "000000100" ) THEN 
            write(TX_LOC,string'("TEST #1 ERROR!!! 000000100 != 000000010^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF; 

        WAIT FOR 2*PERIOD;

        -- Test #2:
        a <= "000000000";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT FOR PERIOD;
        
        IF ( c /= "000000000" ) THEN 
            write(TX_LOC,string'("TEST #2 ERROR!!! 000000000 != 000000000^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF; 

        WAIT FOR 2*PERIOD;

        -- Test #3:
        a <= "111111111";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT FOR PERIOD;
        
        IF ( c /= "010101011" ) THEN 
            write(TX_LOC,string'("TEST #3 ERROR!!! 010101011 != 111111111^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF; 

        WAIT FOR 2*PERIOD;

        -- Test #4:
        a <= "011011010";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT FOR PERIOD;
        
        IF ( c /= "100111100" ) THEN 
            write(TX_LOC,string'("TEST #4 ERROR!!! 100111100 != 011011010^2"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF; 

        WAIT FOR 2*PERIOD;

        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;