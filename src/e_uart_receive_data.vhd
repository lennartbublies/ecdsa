----------------------------------------------------------------------------------------------------
-- Entity - UART Receive Data
--		Receives data from RX of UART interface. Can be toggled between SIG and VALID mode. 
--
--      The key has to be right aligned if it is not byte-aligned:
--          i.e. M=9 => 9 Bits => rx_i will get 2 Bytes: "0000_0001" and "1111_1111" 
--          with 0 being ignored and 1 being the key.
--
--
-- Generic:
--		baud_rate : baud rate of UART
-- Ports:
--		clk_i	: IN std_logic;
--		rst_i	: IN std_logic;
--	 	rx_i	: IN std_logic;
--		mode_i	: IN std_logic;
--		data_o	: OUT std_logic_vector (M-1 DOWNTO 0);
--		ena_r_o	: OUT std_logic;
--		ena_s_o	: OUT std_logic;
--		ena_m_o	: OUT std_logic;
--		rdy_o	: OUT std_logic);
--    
--  Author: Leander Schulz (inf102143@fh-wedel.de)
--  Date: 10.07.2017
----------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY e_uart_receive_data IS
    
    GENERIC (   
        baud_rate : IN NATURAL RANGE 1200 TO 500000;
        N : IN NATURAL RANGE 1 TO 256;
        M : IN NATURAL RANGE 1 TO 256);
    PORT (
		clk_i	: IN std_logic;
		rst_i	: IN std_logic;
	 	rx_i	: IN std_logic;
		mode_i	: IN std_logic;
		data_o	: OUT std_logic_vector (7 DOWNTO 0);
		ena_r_o	: OUT std_logic;
		ena_s_o	: OUT std_logic;
		ena_m_o	: OUT std_logic;
		rdy_o	: OUT std_logic);
    END ENTITY e_uart_receive_data;

ARCHITECTURE e_uart_receive_data_arch OF e_uart_receive_data IS
--	signal declaration
	--TYPE uart_state_type IS (idle, start, data0, data1, data2, data3, data4, data5, data6, data7, parity, stop);
    TYPE uart_state_type IS (idle, start, data, stop);
	SIGNAL s_uart_state, s_uart_next : uart_state_type;
	
	--SIGNAL scan_cnt, wait_cnt, symbol_cycles, wait_rate, bit_cnt : INTEGER;
-- #################
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
-- p_scan_symbol:
    SUBTYPE t_byte   IS NATURAL RANGE 0 TO 9;
    SIGNAL  bit_cnt : t_byte := 0;
-- #################

    SIGNAL s_data : std_logic_vector (0 TO 7);
	
BEGIN

	-- UART Receive State Machine
    p_byte_fsm : PROCESS(s_uart_state,s_uart_next,rst_internal,rx_i,scan_clk) --ALL)
    BEGIN
        s_uart_next <= s_uart_state;
        rst_internal <= '1';
        CASE s_uart_state IS
            WHEN idle =>
                IF rx_i = '0' THEN
                    s_uart_next <= start;
                    rst_internal <= '0';
                END IF;
            WHEN start =>
                rst_internal <= '1';
                IF scan_clk = '1' THEN
                    s_uart_next <= data;
                END IF;
            WHEN data => 
                IF bit_cnt = 9 THEN
                    s_uart_next <= stop;
                END IF;
            WHEN stop => 
                IF rx_i = '0' THEN
                    s_uart_next <= idle;
                END IF;
        END CASE;
    END PROCESS p_byte_fsm;
    
    --- save the rx signal via shifting into s_data:
    p_shift : PROCESS(clk_i, rst_internal, rx_i)
    BEGIN
        IF rst_i = '0' THEN
            s_data <= (others => '0');
        ELSIF rising_edge(clk_i) AND scan_clk = '1' THEN
            IF bit_cnt < 8 THEN
                s_data(0) <= rx_i;
                FOR i IN 1 TO 7 LOOP
                    s_data(i) <= s_data(i-1);
                END LOOP;
            END IF;
        END IF;
    END PROCESS p_shift;
        
    p_scan_symbol : PROCESS(rx_i,scan_clk,rst_i)
    BEGIN
        IF rst_i = '0' THEN
            bit_cnt <= 0;
        ELSIF rst_internal = '0' THEN
            bit_cnt <= 0;
        ELSIF rising_edge(clk_i) AND scan_clk = '1' THEN
            IF bit_cnt < 9 THEN
                bit_cnt <= bit_cnt + 1;
            END IF;
        END IF;
    END PROCESS p_scan_symbol;
	
	--- process to generate the clock signal 'scan_clk' to determine when to read rx_i
    p_scan_clk : PROCESS(clk_i,rst_i,rx_i) --(ALL)
    BEGIN
        IF rst_i = '0' THEN
            scan_clk <= '0';
            scan_cnt <= 0;
            wait_cnt <= 0;
        ELSIF rising_edge(clk_i) THEN
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
    
    p_byte_store : PROCESS(rst_i,clk_i) --ALL)
    BEGIN
        IF rst_i = '0' THEN
            s_uart_state <= idle;
        ELSIF rising_edge(clk_i) THEN
            s_uart_state <= s_uart_next;
        END IF;
    END PROCESS p_byte_store;

    -- push to output 
    p_scan_out : PROCESS(clk_i,bit_cnt,rst_i,s_uart_state,s_uart_next)
    BEGIN 
        IF rst_i = '0' THEN
            data_o <= "00000000";
            rdy_o <= '0';
        ELSIF rising_edge(clk_i) THEN
            IF s_uart_state = data AND s_uart_next = stop THEN
                data_o <= s_data;
                rdy_o <= '1'; 
            ELSE
                rdy_o <= '0'; -- eventually catch throwing of multiple events
            END IF;
        END IF;        
    END PROCESS p_scan_out;

END ARCHITECTURE e_uart_receive_data_arch;
