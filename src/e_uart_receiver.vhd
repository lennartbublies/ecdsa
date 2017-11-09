----------------------------------------------------------------------------------------------------
-- Entity - UART Receiver
--		Receives data from RX of UART interface. Can be toggled between SIG and VALID mode. 
--
--      The key has to be right aligned if it is not byte-aligned:
--          i.e. M=9 => 9 Bits => rx_i will get 2 Bytes: "0000_0001" and "1111_1111" 
--          with 0 being ignored and 1 being the key.
--
--
-- Generic:
--		baud_rate : baud rate of UART
--      N 
--      M - Key length in Bits
-- Ports:
--		clk_i	- global clock signal
--		rst_i	- global reset signal
--	 	rx_i	- uart rx input (receive data)
--		mode_i	- Mode of ECDSA: 0 = Sign (receive message), 1 = Verify (receive R, S and message)
--		data_o	- byte wise output of data
--		ena_r_o	- enable write to R register
--		ena_s_o	- enable write to S register
--		ena_m_o	- enable write to R register
--		rdy_o	- ready at end of incoming data 
--    
--  Author:         Leander Schulz (inf102143@fh-wedel.de)
--  Date:           10.07.2017
--  Last change:    25.10.2017
----------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY e_uart_receiver IS
    
    GENERIC (   
        baud_rate : IN NATURAL RANGE 1200 TO 500000;
        N : IN NATURAL RANGE 1 TO 256;
        M : IN NATURAL RANGE 1 TO 256); 
    PORT (
		clk_i	: IN std_logic;
		rst_i	: IN std_logic;
	 	rx_i	: IN std_logic;
		mode_o	: OUT std_logic;
		data_o	: OUT std_logic_vector (7 DOWNTO 0);
		ena_r_o	: OUT std_logic;
		ena_s_o	: OUT std_logic;
		ena_m_o	: OUT std_logic;
		rdy_o	: OUT std_logic);
    END ENTITY e_uart_receiver;

ARCHITECTURE e_uart_receiver_arch OF e_uart_receiver IS
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

-- p_calc_bytes
    CONSTANT  param_bytes_a : NATURAL RANGE 1 TO 128 := M / 8;
    CONSTANT  param_bytes_b : NATURAL RANGE 0 TO 7 := M MOD 8; -- for check if M is byte aligned
    SIGNAL    param_bytes   : NATURAL RANGE 1 TO 128;

-- p_cnt_bytes
    -- dmode    = detect mode ("00000000" for sign or "11111111" for verify)
    -- smode    = set mode ('0' or '1')
    -- phase1   = read point r
    -- phase2   = read point s
    -- phase3   = read message
    TYPE phase_state_type IS (idle, dmode, smode, phase1, phase2, phase3, stop);
	SIGNAL s_phase, s_phase_next : phase_state_type;
    
    SIGNAL s_cnt_phas1 : NATURAL RANGE 0 TO 128;
    SIGNAL s_cnt_phas2 : NATURAL RANGE 0 TO 128;
    SIGNAL s_cnt_phas3 : NATURAL RANGE 0 TO 256 := N;
    SIGNAL s_phas1_tmp : NATURAL RANGE 0 TO 128;
    SIGNAL s_phas2_tmp : NATURAL RANGE 0 TO 128;
    SIGNAL s_phas3_tmp : NATURAL RANGE 0 TO 128;

    SIGNAL s_rdy    : std_logic;
    SIGNAL s_data   : std_logic_vector (0 TO 7);
    SIGNAL s_data_o : std_logic_vector (0 TO 7);
    
    -- detect mode
    CONSTANT c_mode_sign   : std_logic_vector (7 DOWNTO 0) := "00000000";
    CONSTANT c_mode_verify : std_logic_vector (7 DOWNTO 0) := "11111111";
    SIGNAL s_mode, s_mode_tmp : std_logic;
    SIGNAL s_mode_start, s_mode_start_tmp : std_logic;
	
BEGIN

	-- UART Receive State Machine
    p_byte_fsm : PROCESS(s_uart_state,s_uart_next,rst_internal,rx_i,scan_clk,bit_cnt,s_rdy)
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
                IF rx_i = '0' OR s_rdy = '1' THEN
                    s_uart_next <= idle;
                END IF;
        END CASE;
    END PROCESS p_byte_fsm;
    
    --- save the rx signal via shifting into s_data:
    p_shift : PROCESS(clk_i,rst_i,rst_internal,rx_i,s_data,scan_clk,bit_cnt,s_uart_state) --ALL)
    BEGIN
        IF rst_i = '1' THEN
            s_data <= (others => '0');
        ELSIF rising_edge(clk_i) AND scan_clk = '1' THEN
            IF bit_cnt < 8 AND NOT (s_uart_state = idle) THEN
                s_data(0) <= rx_i;
                FOR i IN 1 TO 7 LOOP
                    s_data(i) <= s_data(i-1);
                END LOOP;
            END IF;
        END IF;
    END PROCESS p_shift;
        
    p_scan_symbol : PROCESS(clk_i,rx_i,scan_clk,rst_i,bit_cnt,rst_internal)
    BEGIN
        IF rst_i = '1' THEN
            bit_cnt <= 0;
        ELSIF rst_internal = '0' THEN
            bit_cnt <= 0;
        ELSIF rising_edge(clk_i) AND scan_clk = '1' THEN
            IF bit_cnt < 9 AND NOT (s_uart_state = idle) THEN
                bit_cnt <= bit_cnt + 1;
            END IF;
        END IF;
    END PROCESS p_scan_symbol;
	
	--- process to generate the clock signal 'scan_clk' to determine when to read rx_i
    -- p_scan_clk : PROCESS(ALL)
    p_scan_clk : PROCESS(clk_i,rst_i,rx_i,rst_internal,wait_cnt,bit_cnt,scan_cnt) 
    BEGIN
        IF rst_i = '1' THEN
            scan_clk <= '0';
            scan_cnt <= 0;
            wait_cnt <= 0;
        ELSIF rising_edge(clk_i) THEN
            IF rst_internal = '0' THEN                      
                    scan_clk <= '0';
                    scan_cnt <= 0;
                    wait_cnt <= 0;
            ELSIF wait_cnt < wait_rate THEN
                wait_cnt <= wait_cnt + 1;
            ELSE
                IF bit_cnt = 9 AND NOT (s_uart_state = idle) THEN                  
                    scan_clk <= '0';
                    scan_cnt <= 0;
                    wait_cnt <= 0;
                ELSIF scan_cnt = 0 THEN
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
    
    p_byte_store : PROCESS(rst_i,clk_i,param_bytes) --ALL)
    BEGIN
        IF rst_i = '1' THEN
            s_uart_state <= idle;
            s_phase <= idle;
            s_phas1_tmp <= param_bytes;
            s_phas2_tmp <= param_bytes;
            s_phas3_tmp <= N;
            s_mode      <= '0';
            s_mode_start <= '0';
        ELSIF rising_edge(clk_i) THEN
            s_uart_state <= s_uart_next;
            s_phase     <= s_phase_next;
            s_phas1_tmp <= s_cnt_phas1;
            s_phas2_tmp <= s_cnt_phas2;
            s_phas3_tmp <= s_cnt_phas3;
            s_mode       <= s_mode_tmp;
            s_mode_start <= s_mode_start_tmp;
        END IF;
    END PROCESS p_byte_store;

    -- push to output 
    p_scan_out : PROCESS(clk_i,rst_i,s_uart_state,s_uart_next)
    BEGIN 
        IF rst_i = '1' THEN
            s_data_o <= "00000000";
            s_rdy <= '0';
            s_mode_start_tmp <= '0';
        ELSIF rising_edge(clk_i) THEN
            IF s_uart_state = data AND s_uart_next = stop THEN
                -- detect mode
                IF s_phase = dmode THEN
                    IF s_data = c_mode_sign THEN
                        -- sign
                        s_mode_tmp <= '0';
                        s_mode_start_tmp <= '1';
                    ELSIF s_data = c_mode_verify THEN
                        -- verify
                        s_mode_tmp <= '1';
                        s_mode_start_tmp <= '1';
                        s_rdy <= '1';
                    ELSE
                        -- mode detection failed
                        -- raise huge error
                        ASSERT FALSE REPORT "Mode Detection Failed!" SEVERITY FAILURE;
                    END IF;
                ELSE
                    s_data_o <= s_data;
                    s_rdy <= '1'; 
                    s_mode_start_tmp <= '0';
                END IF;
            ELSE
                s_mode_start_tmp <= '0';
                s_rdy <= '0';
            END IF;
        END IF;        
    END PROCESS p_scan_out;
    
    -- calculate bytes to read
    p_calc_bytes : PROCESS(param_bytes)
    BEGIN
        IF (param_bytes_b = 0) THEN
            param_bytes <= param_bytes_a;
        ELSE
            param_bytes <= param_bytes_a+1;
        END IF;
    END PROCESS p_calc_bytes;    
    
    -- state machine 
    p_cnt_bytes : PROCESS(rst_i,rst_internal,s_mode,s_phase,s_rdy,s_mode_start,s_phas1_tmp,s_phas2_tmp,s_phas3_tmp,param_bytes)
    BEGIN
        s_phase_next <= s_phase;
        s_cnt_phas1  <= s_phas1_tmp;
        s_cnt_phas2  <= s_phas2_tmp;
        s_cnt_phas3  <= s_phas3_tmp;
        CASE s_phase IS
            WHEN idle =>
                s_cnt_phas1 <= param_bytes;
                s_cnt_phas2 <= param_bytes;
                s_cnt_phas3 <= N;
                IF rst_internal = '0' THEN
                    s_phase_next <= dmode;
                END IF;
            WHEN dmode =>
                IF s_mode_start = '1'  THEN
                    s_phase_next <= smode;
                END IF;
            WHEN smode =>
                IF s_mode = '1' THEN
                    -- verify
                    s_phase_next <= phase1;
                ELSIF s_mode = '0' THEN
                    -- sign
                    s_phase_next <= phase3;
                END IF;
            WHEN phase1 =>
                IF s_rdy = '1' THEN
                    s_cnt_phas1 <= s_phas1_tmp - 1;
                END IF;
                IF s_phas1_tmp = 0 THEN
                    s_phase_next <= phase2;
                END IF;
            WHEN phase2 => 
                IF s_rdy = '1' THEN
                    s_cnt_phas2 <= s_phas2_tmp - 1;
                END IF;
                IF s_phas2_tmp = 0 THEN
                    s_phase_next <= phase3;
                END IF;
            WHEN phase3 => 
                IF s_rdy = '1' THEN
                    s_cnt_phas3 <= s_phas3_tmp - 1;
                END IF;
                IF s_phas3_tmp = 0 THEN
                    s_phase_next <= stop;
                END IF;
            WHEN stop => 
                s_phase_next <= idle;
        END CASE;
    END PROCESS p_cnt_bytes;
    
        -- push to output 
    p_bytes_out : PROCESS(clk_i,rst_i,s_phase,s_phase_next,s_mode)
    BEGIN 
        IF rst_i = '1' THEN
            mode_o  <= '0';
            data_o  <= "00000000";
            rdy_o   <= '0';
            ena_r_o <= '0';
            ena_s_o <= '0';
            ena_m_o <= '0';
        ELSIF rising_edge(clk_i) THEN
            IF s_mode_start = '1' THEN
                mode_o <= s_mode;
            END IF;
            IF s_rdy = '1' THEN
                IF s_phase = idle OR s_phase = dmode or s_phase = smode THEN
                    data_o  <= "00000000";
                    ena_r_o <= '0';
                    ena_s_o <= '0';
                    ena_m_o <= '0';
                ELSIF s_phase = phase1 THEN
                    data_o  <= s_data_o;
                    ena_r_o <= '1';
                    ena_s_o <= '0';
                    ena_m_o <= '0';
                ELSIF s_phase = phase2 THEN
                    data_o  <= s_data_o;
                    ena_r_o <= '0';
                    ena_s_o <= '1';
                    ena_m_o <= '0';
                ELSIF s_phase = phase3 THEN
                    data_o  <= s_data_o;
                    ena_r_o <= '0';
                    ena_s_o <= '0';
                    ena_m_o <= '1';
                ELSIF s_phase = stop THEN
                    ena_r_o <= '0';
                    ena_s_o <= '0';
                    ena_m_o <= '0';
                END IF;               
            ELSE
                data_o  <= "00000000";
                ena_r_o <= '0';
                ena_s_o <= '0';
                ena_m_o <= '0';
            END IF;
            IF s_phase_next = stop THEN
                rdy_o <= '1';
            ELSE
                rdy_o <= '0';
            END IF;
        END IF;        
    END PROCESS p_bytes_out;
        
END ARCHITECTURE e_uart_receiver_arch;
