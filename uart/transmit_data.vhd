-------------------------------------------------------------------------------
-- Module:       transmit_data 
-- Purpose:      Transmits one Ascii Character via Tx of UART Connection.
--               
-- Author:       Leander Schulz
-- Date:         07.09.2016
-- Last change:  07.09.2016
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY transmit_data IS
    GENERIC(baud_rate : IN NATURAL RANGE 1200 TO 115200);
    PORT( clk       : IN std_logic;
          rst       : IN std_logic;   -- global low active async reset
          start_bit : IN std_logic;   -- starts the transmission of ascii char
          char_data : IN std_logic_vector (7 DOWNTO 0); -- ascii char to send
          out_tx    : OUT std_logic );  -- sequential transmission signal
END ENTITY transmit_data;

ARCHITECTURE td_arch OF transmit_data IS
    -- clock signal from baud rate used to transmit data
    COMPONENT baud_clock IS
        GENERIC(baud_rate : IN NATURAL RANGE 1200 TO 115200);
        PORT(   clk       : IN std_logic;     
                rst       : IN std_logic;     
                baud_clk  : OUT std_logic);   
    END COMPONENT baud_clock;
    
    TYPE state_type IS (idle, start, transmit, stop); -- wait_edge
    SIGNAL s_curr, s_next : state_type := idle;
    
    SIGNAL s_iter : natural range 0 TO 9 := 0;
    
    SIGNAL s_baud_clk : std_logic;
    SIGNAL s_baud_rst : std_logic := '1';
    
BEGIN -- ARCHITECTURE----------------------------------------------------------
   

    p_transmit_byte : PROCESS(ALL)
    BEGIN
        IF rst = '0' THEN 
            out_tx <= '1';
            s_iter <= 0;
        ELSIF rising_edge(clk) THEN
        
            IF s_curr = idle THEN
                out_tx <= '1';
            ELSIF s_curr = start THEN
                out_tx <= '0';
            ELSIF s_curr = transmit THEN
                IF s_baud_clk = '1' THEN
                    IF s_iter < 8 THEN
                        out_tx <= char_data(s_iter);
                    END IF;
                    s_iter <= s_iter + 1;
                END IF;
            ELSIF s_curr = stop THEN
                out_tx <= '1';
                s_iter <= 0;
            END IF;
        
        END IF;
    END PROCESS p_transmit_byte;


    p_fsm_transition : PROCESS(ALL) 
    BEGIN
        s_next <= s_curr;
        s_baud_rst <= '1';
        CASE s_curr IS
            WHEN idle => 
                IF start_bit = '1' THEN
                    s_baud_rst <= '0';
                    s_next <= start;
                END IF;
            WHEN start =>
                    s_baud_rst <= '1';
                    s_next <= transmit;
            WHEN transmit =>
                IF s_iter = 9 THEN 
                    s_next <= stop;
                END IF;
            WHEN stop => 
                IF s_baud_clk = '1' THEN
                    s_next <= idle;
                END IF;
        END CASE;
    END PROCESS p_fsm_transition;
    
    p_fsm_store : PROCESS(clk,rst,s_next)
    BEGIN
        IF rst = '0' THEN
            s_curr <= idle;
        ELSIF rising_edge(clk) THEN
            s_curr <= s_next;
        END IF;
    END PROCESS p_fsm_store;
    
            
    baud_clock_inst : baud_clock 
        GENERIC MAP(baud_rate => baud_rate)
        PORT MAP( clk       => clk, 
                  rst       => s_baud_rst, 
                  baud_clk  => s_baud_clk
        );  

END ARCHITECTURE td_arch; -----------------------------------------------------
