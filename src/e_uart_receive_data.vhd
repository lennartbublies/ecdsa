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
	GENERIC ( baud_rate : IN NATURAL RANGE 1200 TO 115200);
	PORT MAP (
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
--	Signal declaration

BEGIN


END ARCHITECTURE e_uart_receive_data_arch;
