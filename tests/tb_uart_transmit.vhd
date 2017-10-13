-------------------------------------------------------------------------------
-- Module:       tb_uart_transmit
-- Purpose:      Testbench for module e_uart_transmit.
--               
-- Author:       Leander Schulz
-- Date:         07.09.2017
-- Last change:  07.09.2017
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY tb_uart_transmit IS
END ENTITY tb_uart_transmit;

ARCHITECTURE tb_arch OF tb_uart_transmit IS

    -- IMPORT UART COMPONENT
    COMPONENT e_uart_transmit IS
        GENERIC(
            baud_rate : IN NATURAL RANGE 1200 TO 500000;
            N : integer;
            M : integer 
        );
        PORT( 
            clk_i     : IN std_logic;
            rst_i     : IN std_logic;
            mode_i    : IN std_logic;
            verify_i  : IN std_logic;
            start_i   : IN std_logic;
            data_i    : IN std_logic_vector (7 DOWNTO 0);
            tx_o      : OUT std_logic;
            reg_o     : OUT std_logic );
    END COMPONENT e_uart_transmit;

    SIGNAL s_clk        : std_logic;
    SIGNAL s_rst        : std_logic := '0'; 
    SIGNAL s_mode       : std_logic := '0';
    SIGNAL s_verify     : std_logic := '0';
    SIGNAL s_start_bit  : std_logic := '0';
    SIGNAL s_uart_data  : std_logic_vector (7 DOWNTO 0) := "00000000";
    
    SIGNAL s_tx         : std_logic;
    SIGNAL s_reg_ctrl   : std_logic;
    
BEGIN
    -- Instantiate uart transmitter
    transmit_instance : e_uart_transmit
        GENERIC MAP (
            baud_rate   => 500000,
            N           => 3, -- message length [byte]
            M           => 8  -- key length [bit]
        ) PORT MAP ( 
            clk_i    => s_clk,
            rst_i    => s_rst,
            mode_i   => s_mode,
            verify_i => s_verify,
            start_i  => s_start_bit,
            data_i   => s_uart_data,
            tx_o     => s_tx,
            reg_o    => s_reg_ctrl
        );
    
    p_clk : PROCESS BEGIN
        s_clk <= '0';
        WAIT FOR 10 ns;
        s_clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS p_clk;

    tx_gen : PROCESS
    BEGIN
        s_uart_data <= "10011001";
        
        WAIT FOR 80 ns;
        s_rst <= '1';
        WAIT FOR 20 ns;
        s_rst <= '0';
        WAIT FOR 200 ns;
        
        s_start_bit <= '1';
        WAIT FOR 20 ns;
        s_start_bit <= '0';
        
        
        WAIT FOR 20 us;
        s_uart_data <= "01011010";
        
        WAIT FOR 20 us;
        s_uart_data <= "01100110";
        
        WAIT FOR 20 us;
        s_uart_data <= "01010101";
        
        WAIT;
        
    END PROCESS tx_gen;
    
END ARCHITECTURE tb_arch;
