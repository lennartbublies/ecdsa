-------------------------------------------------------------------------------
-- Module:       e_baud_clock 
-- Purpose:      Generates a continous clock signal from baud rate
--               
-- Author:       Leander Schulz
-- Date:         06.09.2016
-- Last change:  06.09.2016
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY e_baud_clock IS
    GENERIC(
          baud_rate : IN NATURAL RANGE 1200 TO 500000);
    PORT( clk_i       : IN std_logic;     -- system clock
          rst_i       : IN std_logic;     -- asynchronous reset
          baud_clk_o  : OUT std_logic);   -- generated baud rate clock
END ENTITY e_baud_clock;

ARCHITECTURE bclk_arch OF e_baud_clock IS

    SUBTYPE max_cycles     IS INTEGER RANGE 0 TO 50000000;
    SIGNAL   clk_count     : max_cycles := 0;
    CONSTANT clk_period    : INTEGER := 20; -- 1.000.000.000 ns / 50 MHz
    
    -- symbol_length in ns 
    -- (e.g. 104.166ns at 9600 Baud):
    CONSTANT symbol_length : INTEGER := 1000000000 / baud_rate;
    
    -- symbol_cycles = number of clock periods per symbol 
    -- (e.g. 5208 cycles at 9600 Baud)
    CONSTANT symbol_cycles : max_cycles := symbol_length / clk_period;
    
BEGIN

    p_generator : PROCESS(clk_i,rst_i)
    BEGIN
        IF rst_i = '0' THEN 
            baud_clk_o  <= '0';
            clk_count <= 0;            
        ELSIF rising_edge(clk_i) THEN
            IF clk_count < symbol_cycles THEN
                baud_clk_o  <= '0';
                clk_count <= clk_count + 1;
            ELSE
                baud_clk_o  <= '1';
                clk_count <= 0;
            END IF;
        END IF;
    END PROCESS p_generator;


END ARCHITECTURE bclk_arch; 
