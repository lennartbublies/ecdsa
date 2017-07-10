-------------------------------------------------------------------------------
-- Module:        receive_data 
-- Description: 	RX-Signal in paralleles Signal wandeln
--               
-- Author:        Leander Schulz
-- Date:        	09.08.2016
-- Last change:   20.09.2016
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY receive_data IS
GENERIC( baud_rate : IN NATURAL RANGE 1200 TO 115200
    );
PORT(   
        clk      : IN std_logic;
        rx       : IN std_logic;    -- input signal from rs232
        rst      : IN std_logic;    -- low active async reset
        wrreq    : OUT std_logic;   -- write request to trigger FIFO
        out_data : OUT std_logic_vector (7 DOWNTO 0) -- parallel ascii output
    );
END ENTITY receive_data;


ARCHITECTURE rd_arch OF receive_data IS
-- p_scan_clk:
    CONSTANT clk_period    : INTEGER := 20; -- 1G/50M ns
    SUBTYPE  t_scan IS NATURAL RANGE 0 TO 50000000;
    SIGNAL   scan_clk      : std_logic := '0';
    SIGNAL   scan_cnt      : t_scan := 0;
    -- symbol_length in ns (104.166ns bei 9600 Baud)
    CONSTANT symbol_length : INTEGER := 1000000000 / baud_rate; -- 1G
    -- symbol_cycles = Anzahl taktperioden eines Symbols (5208 Zyklen bei 9600 Baud)
    CONSTANT symbol_cycles : INTEGER := symbol_length / clk_period;
    CONSTANT wait_rate     : t_scan  := (symbol_cycles/2)*3;
    SIGNAL   wait_cnt      : INTEGER RANGE 0 TO wait_rate := 0;
    
-- p_scan_clk:
    SIGNAL  rst_internal : std_logic := '1';
    SIGNAL  rx_last      : std_logic := '1';
-- p_scan_symbol:
    SUBTYPE t_byte   IS NATURAL RANGE 0 TO 9;
    SIGNAL  bit_cnt : t_byte := 0;
    
    SIGNAL s_data : std_logic_vector(0 TO 7);       -- changed order 
    
    TYPE state_type IS (idle, start, data, stop);
    SIGNAL s_state, s_next : state_type;
    
BEGIN -- ARCHITECTURE
    
--- save the rx signal via shifting into s_data:
    p_shift : PROCESS(clk, rst_internal, rx)
    BEGIN
        IF rst = '0' THEN
            s_data <= (others => '0');
        ELSIF rising_edge(clk) AND scan_clk = '1' THEN
            IF bit_cnt < 8 THEN
                s_data(0) <= rx;
                FOR i IN 1 TO 7 LOOP
                    s_data(i) <= s_data(i-1);
                END LOOP;
            END IF;
        END IF;
    END PROCESS p_shift;
        
    p_scan_symbol : PROCESS(rx,scan_clk,rst)
    BEGIN
        IF rst = '0' THEN
            bit_cnt <= 0;
        ELSIF rst_internal = '0' THEN
            bit_cnt <= 0;
        ELSIF rising_edge(clk) AND scan_clk = '1' THEN
            IF bit_cnt < 9 THEN
                bit_cnt <= bit_cnt + 1;
            END IF;
        END IF;
    END PROCESS p_scan_symbol;
    
--- finite state machine to determine the current byte read state
    p_byte_fsm : PROCESS(s_state,s_next,rst_internal,rx,scan_clk) --ALL)
    BEGIN
        s_next <= s_state;
        rst_internal <= '1';
        CASE s_state IS
            WHEN idle =>
                IF rx = '0' THEN
                    s_next <= start;
                    rst_internal <= '0';
                END IF;
            WHEN start =>
                rst_internal <= '1';
                IF scan_clk = '1' THEN
                    s_next <= data;
                END IF;
            WHEN data => 
                IF bit_cnt = 9 THEN
                    s_next <= stop;
                END IF;
            WHEN stop => 
                IF rx = '0' THEN
                    s_next <= idle;
                END IF;
        END CASE;
    END PROCESS p_byte_fsm;
    
    p_byte_store : PROCESS(rst,clk) --ALL)
    BEGIN
        IF rst = '0' THEN
            s_state <= idle;
        ELSIF rising_edge(clk) THEN
            s_state <= s_next;
        END IF;
    END PROCESS p_byte_store;

--- process to generate the clock signal 'scan_clk' to determine when to read rx
    p_scan_clk : PROCESS(clk,rst,rx) --(ALL)
    BEGIN
        IF rst = '0' THEN
            scan_clk <= '0';
            scan_cnt <= 0;
            wait_cnt <= 0;
        ELSIF rising_edge(clk) THEN
            IF rst_internal = '0' THEN          -- internal reset when start bit detected                    
                    scan_clk <= '0';
                    scan_cnt <= 0;
                    wait_cnt <= 0;
            ELSIF wait_cnt < wait_rate THEN            -- warte Halbe Baud-Rate
                wait_cnt <= wait_cnt + 1;
            ELSE
                IF bit_cnt = 9 THEN          -- internal reset when start bit detected                    
                    scan_clk <= '0';
                    scan_cnt <= 0;
                    wait_cnt <= 0;
                ELSIF scan_cnt = 0 THEN                -- generiere scan_clk
                    scan_clk <= '1';
                    scan_cnt <= scan_cnt + 1;
                ELSE
                    scan_clk <= '0';
                    IF scan_cnt < symbol_cycles THEN
                        scan_cnt <= scan_cnt + 1;
                    ELSIF scan_cnt = symbol_cycles THEN
                        scan_cnt <= 0;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS p_scan_clk;

--- push to output 
    p_scan_out : PROCESS(clk,bit_cnt,rst,s_state,s_next)
    BEGIN 
        IF rst = '0' THEN
            out_data <= "00000000";
            wrreq <= '0';
        ELSIF rising_edge(clk) THEN
            IF s_state = data AND s_next = stop THEN
                out_data <= s_data;
                wrreq <= '1'; 
            ELSE
                wrreq <= '0'; -- eventually catch throwing of multiple events
            END IF;
        END IF;        
    END PROCESS p_scan_out;
    
END ARCHITECTURE rd_arch;