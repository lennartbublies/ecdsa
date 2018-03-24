----------------------------------------------------------------------------------------------------
--  Testbench - gf2m Point Addition 
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

ENTITY tb_gf2m_point_addition IS
END tb_gf2m_point_addition;

ARCHITECTURE rtl OF tb_gf2m_point_addition IS 
    -- Import entity e_gf2m_point_addition
    COMPONENT e_gf2m_point_addition IS
        GENERIC (
            MODULO : std_logic_vector(M DOWNTO 0)
        );
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic;
            x1_i: IN std_logic_vector(M-1 DOWNTO 0);
            y1_i: IN std_logic_vector(M-1 DOWNTO 0); 
            x2_i: IN std_logic_vector(M-1 DOWNTO 0); 
            y2_i: IN std_logic_vector(M-1 DOWNTO 0);
            x3_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            y3_o: OUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL xP, yP, xQ, yQ, xR, yR:  std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, done: std_logic := '0';
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  CONSTANT ONE: std_logic_vector(M-1 DOWNTO 0) := (0 => '1', OTHERS=>'0');
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 200 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET : time := 0 ns;
  CONSTANT NUMBER_TESTS: natural := 20;
BEGIN
    -- Instantiate point addition entity
    uut3: e_gf2m_point_addition GENERIC MAP (
            MODULO => P
    ) PORT MAP ( 
        clk_i => clk, 
        rst_i => rst, 
        enable_i => enable,
        x1_i => xP, 
        y1_i => yP, 
        x2_i => xQ, 
        y2_i => yQ,
        x3_io => xR, 
        y3_o => yR,
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
        xP <= "000000010"; 
        yP <= "000001111";
        xQ <= "000001100";
        yQ <= "000001100";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "101101001" or (yR /= "101001111") ) THEN 
            write(TX_LOC,string'("TEST #1 ERROR!!! (101101001, 101001111) != (000000010, 000001111)+(000001100, 000001100)"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF; 

        WAIT FOR 2*PERIOD;
            
        -- Test #2: 
        -- Set point P and Q for computation
        xP <= "111111111"; 
        yP <= "111111111";
        xQ <= "000001100";
        yQ <= "000001100";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "000001100" or (yR /= "000001100") ) THEN 
            write(TX_LOC,string'("TEST #2 ERROR!!! (000001100, 000001100) != (111111111, 111111111)+(000001100, 000001100)"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;  

        WAIT FOR 2*PERIOD;
            
        -- Test #3: 
        -- Set point P and Q for computation
        xP <= "000000010"; 
        yP <= "000001111";
        xQ <= "111111111";
        yQ <= "111111111";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "000000010" or (yR /= "000001111") ) THEN 
            write(TX_LOC,string'("TEST #3 ERROR!!! (000000010, 000001111) != (000000010, 000001111)+(111111111, 111111111)"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;    

        WAIT FOR 2*PERIOD;
            
        -- Test #4: 
        -- Set point P and Q for computation
        xP <= "111100101"; 
        yP <= "000010111";
        xQ <= "011101110";
        yQ <= "010101111";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "000010000" or (yR /= "100011101") ) THEN 
            write(TX_LOC,string'("TEST #4 ERROR!!! (000010000, 100011101) != (111100101, 000010111)+(011101110, 010101111)"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;

        WAIT FOR 2*PERIOD;
            
        -- Test #5: 
        -- Set point P and Q for computation
        xP <= "010101010"; 
        yP <= "010101010";
        xQ <= "000000000";
        yQ <= "000000000";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "010101011" or (yR /= "000000000") ) THEN 
            write(TX_LOC,string'("TEST #5 ERROR!!! (010101011, 000000000) != (010101010, 010101010)+(000000000, 000000000)"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF; 

        WAIT FOR 2*PERIOD;
            
        -- Test #6: 
        -- Set point P and Q for computation
        xP <= "000001101"; 
        yP <= "000101010";
        xQ <= "000000000";
        yQ <= "000000000";
      
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        IF ( xR /= "110110010" or (yR /= "001111110") ) THEN 
            write(TX_LOC,string'("TEST #6 ERROR!!! (110110010, 001111110) != (000001101, 000101010)+(000000000, 000000000)"));
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;          
       
        WAIT FOR DELAY;

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;