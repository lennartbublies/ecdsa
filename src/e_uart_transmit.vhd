-------------------------------------------------------------------------------
-- Module:       e_uart_transmit 
-- Purpose:      Transmits Key when a message will be signed or
--               1 Byte True/False when a message will be verified
--               
-- GENERIC:
--  baud_rate - baud rate of uart transmission
-- PORT:
--  clk_i     - global clock signal
--  rst_i     - global low active async reset
--  mode_i    - ecdsa mode (sign/verify)
--  start_i   - starts the transmission of ascii char
--  data_i    - data byte to send
--  tx_o      - sequential transmission signal
--
-- Author:       Leander Schulz (inf102143@fh-wedel.de)
-- Date:         01.09.2017
-- Last change:  01.09.2017
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY e_uart_transmit IS
    GENERIC(
        baud_rate : IN NATURAL RANGE 1200 TO 500000;
        N         : integer;
        M         : integer 
    );
    PORT( 
        clk_i     : IN std_logic;
        rst_i     : IN std_logic;
        mode_i    : IN std_logic;
        start_i   : IN std_logic;
        data_i    : IN std_logic_vector (7 DOWNTO 0);
        tx_o      : OUT std_logic; 
        reg_o     : OUT std_logic);
END ENTITY e_uart_transmit;

ARCHITECTURE td_arch OF e_uart_transmit IS
    -- import e_baud_clock
    -- clock signal from baud rate used to transmit data
    COMPONENT e_baud_clock IS
        GENERIC(baud_rate : IN NATURAL RANGE 1200 TO 500000);
        PORT(   clk_i       : IN std_logic;     
                rst_i       : IN std_logic;     
                baud_clk_o  : OUT std_logic);   
    END COMPONENT e_baud_clock;
    
    TYPE state_type IS (idle, start, transmit, stop); -- wait_edge
    SIGNAL s_curr, s_next : state_type := idle;
    
    SIGNAL s_iter : natural range 0 TO 9 := 0;
    
    SIGNAL s_baud_clk : std_logic;
    SIGNAL s_baud_rst : std_logic := '1';
    
BEGIN -- ARCHITECTURE----------------------------------------------------------
   

    p_transmit_byte : PROCESS(clk_i,rst_i,s_curr,s_baud_clk,s_iter)
    BEGIN
        IF rst_i = '0' THEN 
            tx_o <= '1';
            s_iter <= 0;
        ELSIF rising_edge(clk_i) THEN
        
            IF s_curr = idle THEN
                tx_o <= '1';
            ELSIF s_curr = start THEN
                tx_o <= '0';
            ELSIF s_curr = transmit THEN
                IF s_baud_clk = '1' THEN
                    IF s_iter < 8 THEN
                        tx_o <= data_i(s_iter);
                    END IF;
                    s_iter <= s_iter + 1;
                END IF;
            ELSIF s_curr = stop THEN
                tx_o <= '1';
                s_iter <= 0;
            END IF;
        
        END IF;
    END PROCESS p_transmit_byte;


    p_fsm_transition : PROCESS(s_curr,start_i,s_baud_clk,s_iter)
    BEGIN
        s_next <= s_curr;
        s_baud_rst <= '1';
        CASE s_curr IS
            WHEN idle => 
                IF start_i = '1' THEN
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
    
    p_fsm_store : PROCESS(clk_i,rst_i,s_next)
    BEGIN
        IF rst_i = '0' THEN
            s_curr <= idle;
        ELSIF rising_edge(clk_i) THEN
            s_curr <= s_next;
        END IF;
    END PROCESS p_fsm_store;
    
            
    baud_clock_inst : e_baud_clock 
        GENERIC MAP(baud_rate => baud_rate)
        PORT MAP( clk_i       => clk_i, 
                  rst_i       => s_baud_rst, 
                  baud_clk_o  => s_baud_clk
        );  

END ARCHITECTURE td_arch; -----------------------------------------------------
