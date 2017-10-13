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
----------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY tb_uart_receive_mux IS
END ENTITY tb_uart_receive_mux;

ARCHITECTURE tb_uart_receive_mux_arch OF tb_uart_receive_mux IS

    -- IMPORT UART COMPONENT
    COMPONENT e_uart_receive_mux IS
        PORT ( 
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            uart_i : IN std_logic;
            mode_i : IN std_logic;
            r_o : OUT std_logic_vector(7 DOWNTO 0);
            s_o : OUT std_logic_vector(7 DOWNTO 0);
            m_o : OUT std_logic_vector(7 DOWNTO 0);
            ready_o : OUT std_logic
        );
    END COMPONENT e_uart_receive_mux;
	

    -- TB internal signals
    SIGNAL s_clk        : std_logic;
    SIGNAL s_rx         : std_logic := '1';
    SIGNAL s_rst        : std_logic;
    SIGNAL s_mode       : std_logic := '1';
    SIGNAL s_data       : std_logic;
	SIGNAL s_r_o        : std_logic_vector(7 DOWNTO 0);
	SIGNAL s_s_o        : std_logic_vector(7 DOWNTO 0);
	SIGNAL s_m_o        : std_logic_vector(7 DOWNTO 0);
	SIGNAL s_rdy_o	    : std_logic;
    
-- baud table:
-- 9600   baud ^= 104166ns ^= 5208 cycles
-- 115200 baud ^= 8680ns   ^= 434 cycles
-- 500000 baud ^= 2000ns   ^= 100 cycles
BEGIN

    module_instance : e_uart_receive_mux
    PORT MAP ( 
        clk_i   => s_clk,
        rst_i   => s_rst,
        uart_i  => s_data,
        mode_i  => s_mode,
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
        WAIT FOR 5000 ns;
        
        
        -- change mode to sign
        s_mode <= '0';
        s_rst  <= '0';
        WAIT FOR 20 ns;
        s_rst <= '1';
        WAIT FOR 80 ns;
        
        -- Message Byte 2
        -- "01111101":
        ASSERT FALSE REPORT "M Byte 0" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 4
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
        
        -- Message Byte 1
        -- "10011001":
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
        s_rx <= '1';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
        
        -- Message Byte 0
        -- "10101010":
        ASSERT FALSE REPORT "M Byte 0" SEVERITY NOTE;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- LSB (Bit 0)
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 1
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 2
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 3
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 4
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- Bit 5
        WAIT FOR 2000 ns;
        s_rx <= '0';        -- Bit 6
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 3000 ns;
		
        WAIT;
    END PROCESS rx_gen;



END ARCHITECTURE tb_uart_receive_mux_arch;
	
	
	