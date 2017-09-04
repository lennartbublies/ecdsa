----------------------------------------------------------------------------------------------------
-- Entity - UART Receive Data Testbench
--		Testbench of e_uart_receive_data
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
--  Date: 08.08.2017
----------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY e_uart_receive_data_tb IS
END ENTITY e_uart_receive_data_tb;

ARCHITECTURE e_uart_receive_data_tb_arch OF e_uart_receive_data_tb IS

    -- IMPORT UART COMPONENT
	COMPONENT e_uart_receive_data IS
		GENERIC ( 
            baud_rate : IN NATURAL RANGE 1200 TO 500000;
            N : IN NATURAL RANGE 1 TO 256;
            M : IN NATURAL RANGE 1 TO 256);
		PORT (
            clk_i    : IN  std_logic;
            rst_i    : IN  std_logic;
            rx_i     : IN  std_logic;
            mode_i   : IN  std_logic;
            data_o   : OUT std_logic_vector (M-1 DOWNTO 0);
            ena_r_o	 : OUT std_logic;
            ena_s_o	 : OUT std_logic;
            ena_m_o	 : OUT std_logic;
            rdy_o    : OUT std_logic);
	END COMPONENT e_uart_receive_data;
	

    -- TB internal signals
    SIGNAL s_clk        : std_logic;
    SIGNAL s_rx         : std_logic := '1';
    SIGNAL s_rst        : std_logic;
    SIGNAL s_mode       : std_logic;
    SIGNAL s_data       : std_logic_vector(7 DOWNTO 0);
	SIGNAL s_ena_r_o      : std_logic;
	SIGNAL s_ena_s_o      : std_logic;
	SIGNAL s_ena_m_o      : std_logic;
	SIGNAL s_rdy_o	    : std_logic;
    
-- baud table:
-- 9600   baud ^= 104166ns ^= 5208 cycles
-- 115200 baud ^= 8680ns   ^= 434 cycles
-- 500000 baud ^= 2000ns   ^= 100 cycles
BEGIN
   	 
	uart_receiver: e_uart_receive_data
	GENERIC MAP ( 
		baud_rate => 500000,
		N => 1,	    -- length of message
		M => 9)     -- length of key
	PORT MAP (
		clk_i    => s_clk,
		rst_i    => s_rst,
		rx_i     => s_rx,
		mode_i   => s_mode,
		data_o   => s_data,
		ena_r_o	 => s_ena_r_o, 
		ena_s_o	 => s_ena_s_o, 
		ena_m_o	 => s_ena_m_o,
		rdy_o    => s_rdy_o
	);
	 
    clk_gen : PROCESS
    BEGIN
        s_clk <= '0'; 
        WAIT FOR 10 ns; 
        s_clk <= '1'; 
        WAIT FOR 10 ns;
    END PROCESS clk_gen;
	 
	rx_gen : PROCESS
    BEGIN 
    
        s_rx <= '1';
		WAIT FOR 100 ns;
		s_rst <= '0';
		WAIT FOR 20 ns;
		s_rst <= '1';
        WAIT FOR 880 ns;
		
        
		-- R Byte 1
        -- "01100101"
        ASSERT FALSE REPORT "R Byte 1" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
        
		-- R Byte 0
        -- "01101001":
        ASSERT FALSE REPORT "R Byte 0" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
		  
		-- S Byte 1
		-- "01010101"
        ASSERT FALSE REPORT "S Byte 1" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
        
        -- S Byte 0
        -- "01101001":
        ASSERT FALSE REPORT "S Byte 0" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
        
        -- Message Byte 0
        -- "01101001":
        ASSERT FALSE REPORT "M Byte 0" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
		
        WAIT;
    END PROCESS rx_gen;



END ARCHITECTURE e_uart_receive_data_tb_arch;
	
	
	