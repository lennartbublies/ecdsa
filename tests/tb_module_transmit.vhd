-------------------------------------------------------------------------------
-- Module:       tb_module_transmit
-- Purpose:      Testbench for module e_uart_transmit_mux.
--               
-- Author:       Leander Schulz
-- Date:         15.09.2017
-- Last change:  15.09.2017
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY tb_module_transmit IS
END ENTITY tb_module_transmit;

ARCHITECTURE tb_arch OF tb_module_transmit IS

    -- IMPORT e_uart_transmit_mux COMPONENT
    COMPONENT e_uart_transmit_mux IS
        PORT ( 
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            mode_i : IN std_logic;
            enable_i : IN std_logic;
            r_i : IN std_logic_vector(M-1 DOWNTO 0);
            s_i : IN std_logic_vector(M-1 DOWNTO 0);
            v_i : IN std_logic;
            uart_o : OUT std_logic
        );
    END COMPONENT e_uart_transmit_mux;

    SIGNAL s_clk        : std_logic;
    SIGNAL s_rst        : std_logic := '1'; 
    SIGNAL s_mode       : std_logic := '0';
    SIGNAL s_enable     : std_logic := '0';
    SIGNAL s_r_i        : std_logic_vector(M-1 DOWNTO 0) := "00000000";
    SIGNAL s_s_i        : std_logic_vector(M-1 DOWNTO 0) := "00000000";
    SIGNAL s_v_i        : std_logic;
    
    SIGNAL s_tx         : std_logic;
    
BEGIN
    -- Instantiate uart transmitter
    transmit_instance : e_uart_transmit
        PORT MAP ( 
            clk_i       => s_clk,
            rst_i       => s_rst,
            mode_i      => s_mode,
            enable_i    => s_enable,
            r_i         => s_r_i,
            s_i         => s_s_i,
            v_i         => s_v_i,
            uart_o      => s_tx
        );
    
    p_clk : PROCESS BEGIN
        s_clk <= '0';
        WAIT FOR 10 ns;
        s_clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS p_clk;

    tx_gen : PROCESS
    BEGIN
        s_r_i <= "10011001";
        s_s_i <= "10011001";
        
        WAIT FOR 80 ns;
        s_rst <= '0';
        WAIT FOR 20 ns;
        s_rst <= '1';
        WAIT FOR 200 ns;
        
        enable_i <= '1';
        WAIT FOR 20 ns;
        enable_i <= '0';
        
        WAIT;
        
    END PROCESS tx_gen;
    
END ARCHITECTURE tb_arch;
