----------------------------------------------------------------------------------------------------
-- Entity - UART Receive Data
--		Receives data from RX of UART interface. Can be toggled between SIG and VALID mode. 
--
-- Generic:
--		baud_rate : baud rate of UART
-- Ports:
--  	clk_i    : clock signal
--  	rst_i    : global reset
--	 	rx_i		: RX input of UART
--		mode_i	: toggle SIG (0) and VALID (1)
--		wrreq_o	: write request for FIFO input of data
--		fifo_o	: parallel byte-aligned data output 
--		sig_o		: 163bit signature, only used in VALID mode
--		rdy_o		: marks if receipt of data has finished and outputs are ready
--    
--  Author: Leander Schulz (inf102143@fh-wedel.de)
--  Date: 10.07.2017
----------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY e_uart_receive_data IS
	GENERIC ( baud_rate : IN NATURAL RANGE 1200 TO 500000);
	PORT (
		clk_i    : IN	std_logic;
		rst_i    : IN	std_logic;
	 	rx_i		: IN	std_logic;
		mode_i	: IN	std_logic;
		wrreq_o	: OUT	std_logic;
		fifo_o	: OUT	std_logic_vector (7 DOWNTO 0);
		sig_o		: OUT	std_logic_vector (163 DOWNTO 0);
		rdy_o		: OUT	std_logic);
END ENTITY e_uart_receive_data;

ARCHITECTURE e_uart_receive_data_arch OF e_uart_receive_data IS
--	signal declaration
	TYPE uart_state_type IS (idle, start, data0, data1, data2, data3, data4, data5, data6, data7, parity, stop);
	SIGNAL s_uart_state, s_uart_next : uart_state_type;
	
	SIGNAL scan_clk, rst_internal : std_logic;
	SIGNAL scan_cnt, wait_cnt, symbol_cycles, wait_rate, bit_cnt : INTEGER;
	
BEGIN

	-- UART Receive State Machine
	p_uart_state : PROCESS(clk_i,rst_i,rx_i)
	BEGIN
		IF rst_i = '0' THEN
			-- reset everything
			s_uart_state <= idle;
			s_uart_next  <= idle;
		ELSIF rising_edge(clk_i) THEN
			s_uart_state <= idle;
			
			
		END IF;
	
	END PROCESS p_uart_state;
	
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



END ARCHITECTURE e_uart_receive_data_arch;
