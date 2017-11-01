---------------------------------------------------------------------------------------------------
-- Testbench for the UART Connection (Receiver & Transmitter)
--
--  Author: Leander Schulz (inf102143@fh-wedel.de)
--  Date: 28.10.2017
--  Last change: 28.10.2017
---------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

USE work.tld_ecdsa_package.all;

ENTITY tb_uart IS
END ENTITY tb_uart;

ARCHITECTURE tb_uart_arch OF tb_uart IS
--- Import Receiver
    COMPONENT e_uart_receive_mux IS
        PORT ( 
            clk_i   : IN std_logic;
            rst_i   : IN std_logic;
            uart_i  : IN std_logic;
            mode_o  : OUT std_logic;
            r_o     : OUT std_logic_vector(M-1 DOWNTO 0);
            s_o     : OUT std_logic_vector(M-1 DOWNTO 0);
            m_o     : OUT std_logic_vector(M-1 DOWNTO 0);
            ready_o : OUT std_logic
        );
    END COMPONENT e_uart_receive_mux;

--- Import Transmitter
    COMPONENT e_uart_transmit_mux IS
        PORT ( 
            clk_i    : IN std_logic;
            rst_i    : IN std_logic;
            mode_i   : IN std_logic;
            enable_i : IN std_logic;
            r_i      : IN std_logic_vector(M-1 DOWNTO 0);
            s_i      : IN std_logic_vector(M-1 DOWNTO 0);
            v_i      : IN std_logic;
            uart_o   : OUT std_logic
        );
    END COMPONENT e_uart_transmit_mux;

--- helper procedures and functions
    PROCEDURE p_send_byte (
        SIGNAL s_in  : in  std_logic_vector(7 downto 0);
        SIGNAL s_rx  : out std_logic
    ) IS
    BEGIN
        s_rx <= '0';            -- start bit
        WAIT FOR 2000 ns;
        FOR i IN 0 TO 7 LOOP
            s_rx <= s_in(i);    -- send bits 0-7
            WAIT FOR 2000 ns;
        END LOOP;
        s_rx <= '1';            -- stop Bit
        WAIT FOR 2000 ns;
        s_rx <= '1';            -- idle
        WAIT FOR 3000 ns;
    END p_send_byte;
    
    --- helper procedures and functions
    PROCEDURE p_send_point (
        SIGNAL s_in  : in  std_logic_vector(167 downto 0);
        SIGNAL s_rx  : out std_logic
    ) IS
        SIGNAL s_next : std_logic_vector(7 downto 0);
    BEGIN
        FOR i IN 0 TO 21 LOOP
            s_next <= s_in(i*8 DOWNTO (i+1)*8);
            p_send_byte(s_next,s_rx)
        END LOOP;
    END p_send_point;
    

--- Internal Signals
    SIGNAL s_clk        : std_logic;
    SIGNAL s_rst        : std_logic := '0'; 
    SIGNAL s_rx         : std_logic := '1';
    SIGNAL s_tx         : std_logic;
    SIGNAL s_mode       : std_logic;
    SIGNAL s_enable     : std_logic := '0';
    
    SIGNAL s_r          : std_logic_vector(M-1 DOWNTO 0) ;
    SIGNAL s_s          : std_logic_vector(M-1 DOWNTO 0) ;
    SIGNAL s_m_o        : std_logic_vector(M-1 DOWNTO 0) ;
    SIGNAL s_verify     : std_logic := '0';
    
--- test cases
    CONSTANT c_r_1 : std_logic_vector(167 DOWNTO 0) := x"0796d7796309aee88283dbabf698ba6b6f8e26de11ae";
    CONSTANT c_s_1 : std_logic_vector(167 DOWNTO 0) := x"070871e308d5acbc5064bd42e14a021862ebbc85eea6";
    CONSTANT c_m_1 : std_logic_vector(167 DOWNTO 0) := x"074848656c6c6f20454344534120576f726c64212121";

BEGIN
--- Instance of Receiver
    receiver_inst : e_uart_receive_mux
    PORT MAP ( 
        clk_i   => s_clk,
        rst_i   => s_rst,
        uart_i  => s_rx,
        mode_o  => s_mode,
        r_o     => s_r,
        s_o     => s_s,
        m_o     => s_m_o,
        ready_o => s_enable
    );

--- Instance of Transmitter
    transmitter_inst : e_uart_transmit_mux
        PORT MAP ( 
            clk_i       => s_clk,
            rst_i       => s_rst,
            mode_i      => s_mode,
            enable_i    => s_enable,
            r_i         => s_r,
            s_i         => s_s,
            v_i         => s_verify,
            uart_o      => s_tx
        );
        
--- generate clock
    p_clk : PROCESS BEGIN
        s_clk <= '0';
        WAIT FOR 10 ns;
        s_clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS p_clk;
    
--- testing process
    rx_gen : PROCESS
    BEGIN 
        -- intitialize
        s_rx <= '1';
		WAIT FOR 100 ns;
		s_rst <= '1';
		WAIT FOR 20 ns;
		s_rst <= '0';
        WAIT FOR 880 ns;
        
        --begin testing
        p_send_point(c_r_1);
        p_send_point(c_s_1);
        p_send_point(c_m_1);
        
        

        WAIT;
    END PROCESS rx_gen;
END ARCHITECTURE tb_uart_arch;