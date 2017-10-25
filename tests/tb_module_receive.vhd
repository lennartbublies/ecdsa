----------------------------------------------------------------------------------------------------
-- Entity - UART Receive Mux Module Testbench
--		Testbench of e_uart_receive_mux
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
--  Last change: 25.10.2017
----------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

USE work.tld_ecdsa_package.all;

ENTITY tb_uart_receive_mux IS
END ENTITY tb_uart_receive_mux;

ARCHITECTURE tb_uart_receive_mux_arch OF tb_uart_receive_mux IS

    -- IMPORT UART COMPONENT
    COMPONENT e_uart_receive_mux IS
        PORT ( 
            clk_i  : IN std_logic;
            rst_i  : IN std_logic;
            uart_i : IN std_logic;
            mode_o  : OUT std_logic;
            r_o     : OUT std_logic_vector(M-1 DOWNTO 0);
            s_o     : OUT std_logic_vector(M-1 DOWNTO 0);
            m_o     : OUT std_logic_vector(M-1 DOWNTO 0);
            ready_o : OUT std_logic
        );
    END COMPONENT e_uart_receive_mux;
	

    -- TB internal signals
    SIGNAL s_clk        : std_logic;
    SIGNAL s_rx         : std_logic := '1';
    SIGNAL s_rst        : std_logic;
    SIGNAL s_mode       : std_logic;
    SIGNAL s_data       : std_logic_vector(7 DOWNTO 0);
	SIGNAL s_r_o        : std_logic_vector(M-1 DOWNTO 0);
	SIGNAL s_s_o        : std_logic_vector(M-1 DOWNTO 0);
	SIGNAL s_m_o        : std_logic_vector(M-1 DOWNTO 0);
	SIGNAL s_rdy_o	    : std_logic;
    
    PROCEDURE p_send_byte (
        SIGNAL s_in  : in  std_logic_vector(7 downto 0);
        SIGNAL s_rx  : out std_logic
    ) IS
    BEGIN
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= s_in(0);    -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= s_in(1);    -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= s_in(2);    -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= s_in(3);    -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= s_in(4);    -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= s_in(5);    -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= s_in(6);    -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= s_in(7);    -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
    END p_send_byte;
    
-- baud table:
-- 9600   baud ^= 104166ns ^= 5208 cycles
-- 115200 baud ^= 8680ns   ^= 434 cycles
-- 500000 baud ^= 2000ns   ^= 100 cycles
BEGIN

    module_instance : e_uart_receive_mux
    PORT MAP ( 
        clk_i   => s_clk,
        rst_i   => s_rst,
        uart_i  => s_rx,
        mode_o  => s_mode,
        r_o     => s_r_o,
        s_o     => s_s_o,
        m_o     => s_m_o,
        ready_o => s_rdy_o
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
		s_rst <= '1';
		WAIT FOR 20 ns;
		s_rst <= '0';
        WAIT FOR 880 ns;
		
        -- set mode to 1 (verify)
        s_data <= "11111111";
        p_send_byte(s_data,s_rx);
        ASSERT FALSE REPORT "R Byte 1-21" SEVERITY NOTE;
        s_data <= "00000001";
        p_send_byte(s_data,s_rx);
        s_data <= "00000010";
        p_send_byte(s_data,s_rx);
        s_data <= "00000011";
        p_send_byte(s_data,s_rx);
        s_data <= "00000100";
        p_send_byte(s_data,s_rx);
        s_data <= "00000101";
        p_send_byte(s_data,s_rx);
        s_data <= "00000110";
        p_send_byte(s_data,s_rx);
        s_data <= "00000111";
        p_send_byte(s_data,s_rx);
        s_data <= "00001000";
        p_send_byte(s_data,s_rx); -- byte 8
        s_data <= "00001001";
        p_send_byte(s_data,s_rx);
        s_data <= "00001010";
        p_send_byte(s_data,s_rx);
        s_data <= "00001011";
        p_send_byte(s_data,s_rx);
        s_data <= "00001100";
        p_send_byte(s_data,s_rx);
        s_data <= "00001101";
        p_send_byte(s_data,s_rx);
        s_data <= "00001110";
        p_send_byte(s_data,s_rx);
        s_data <= "00001111";
        p_send_byte(s_data,s_rx);
        s_data <= "00010000";
        p_send_byte(s_data,s_rx); -- byte 16      
        s_data <= "00010001";
        p_send_byte(s_data,s_rx);
        s_data <= "00010010";
        p_send_byte(s_data,s_rx);
		s_data <= "00010011";
        p_send_byte(s_data,s_rx);
        s_data <= "00010100";
        p_send_byte(s_data,s_rx);
        s_data <= "00010101";
        p_send_byte(s_data,s_rx); -- byte 21
        
        
        ASSERT FALSE REPORT "S Byte 1-21" SEVERITY NOTE;
        s_data <= "10000001";
        p_send_byte(s_data,s_rx);
        s_data <= "10000010";
        p_send_byte(s_data,s_rx);
        s_data <= "10000011";
        p_send_byte(s_data,s_rx);
        s_data <= "10000100";
        p_send_byte(s_data,s_rx);
        s_data <= "10000101";
        p_send_byte(s_data,s_rx);
        s_data <= "10000110";
        p_send_byte(s_data,s_rx);
        s_data <= "10000111";
        p_send_byte(s_data,s_rx);
        s_data <= "10001000";
        p_send_byte(s_data,s_rx); -- byte 8
        s_data <= "10001001";
        p_send_byte(s_data,s_rx);
        s_data <= "10001010";
        p_send_byte(s_data,s_rx);
        s_data <= "10001011";
        p_send_byte(s_data,s_rx);
        s_data <= "10001100";
        p_send_byte(s_data,s_rx);
        s_data <= "10001101";
        p_send_byte(s_data,s_rx);
        s_data <= "10001110";
        p_send_byte(s_data,s_rx);
        s_data <= "10001111";
        p_send_byte(s_data,s_rx);
        s_data <= "10010000";
        p_send_byte(s_data,s_rx); -- byte 16      
        s_data <= "10010001";
        p_send_byte(s_data,s_rx);
        s_data <= "10010010";
        p_send_byte(s_data,s_rx);
		s_data <= "10010011";
        p_send_byte(s_data,s_rx);
        s_data <= "10010100";
        p_send_byte(s_data,s_rx);
        s_data <= "10010101";
        p_send_byte(s_data,s_rx); -- byte 21
        
        
        ASSERT FALSE REPORT "Message Bytes" SEVERITY NOTE;
        s_data <= "11010101";
        p_send_byte(s_data,s_rx);
        s_data <= "10011010";
        p_send_byte(s_data,s_rx);
        s_data <= "10111011";
        p_send_byte(s_data,s_rx);
        
        -- reset between mode switching
        WAIT FOR 20000 ns;
        s_rst  <= '1';
        WAIT FOR 20 ns;
        s_rst  <= '0';
        WAIT FOR 20000 ns;
        
        -- Switching mode_i to 0 (sign)
        s_data <= "00000000";
        p_send_byte(s_data,s_rx);        
        
        ASSERT FALSE REPORT "Verify - Message Bytes" SEVERITY NOTE;
        s_data <= "11010101";
        p_send_byte(s_data,s_rx);
        s_data <= "10011010";
        p_send_byte(s_data,s_rx);
        s_data <= "10111011";
        p_send_byte(s_data,s_rx);
        
        WAIT;
    END PROCESS rx_gen;



END ARCHITECTURE tb_uart_receive_mux_arch;
	
	
	