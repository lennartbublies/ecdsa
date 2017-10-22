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
USE work.tld_ecdsa_package.all;

ENTITY tb_module_transmit IS
END ENTITY tb_module_transmit;

ARCHITECTURE tb_arch OF tb_module_transmit IS
    
    --CONSTANT M : integer := 8;

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
    SIGNAL s_rst        : std_logic := '0'; 
    SIGNAL s_mode       : std_logic := '0';
    SIGNAL s_enable     : std_logic := '0';
    -- bytes from int(1) to int(20) + '111'
    SIGNAL s_r_i        : std_logic_vector(M-1 DOWNTO 0) := "1110000000100000010000000110000010000000101000001100000011100001000000010010000101000001011000011000000110100001110000011110001000000010001000100100001001100010100";
    SIGNAL s_s_i        : std_logic_vector(M-1 DOWNTO 0) := "101" & x"1B1A19181716151413121118A2E0CC0D99F8A5EF";
    SIGNAL s_verify     : std_logic := '0';
    
    SIGNAL s_tx         : std_logic;
    
BEGIN
    -- Instantiate uart transmitter
    transmit_instance : e_uart_transmit_mux
        PORT MAP ( 
            clk_i       => s_clk,
            rst_i       => s_rst,
            mode_i      => s_mode,
            enable_i    => s_enable,
            r_i         => s_r_i,
            s_i         => s_s_i,
            v_i         => s_verify,
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
        -- Simulate Transmission of example keys
        -- Simulation time ~ 850us
        WAIT FOR 80 ns;
        s_rst <= '1';
        WAIT FOR 20 ns;
        s_rst <= '0';
        WAIT FOR 200 ns;
        
        s_enable <= '1';
        WAIT FOR 20 ns;
        s_enable <= '0';
        
        WAIT FOR 990000 ns;
        
        -- Simulation of verify (mode = 1; verify = True = 1)
        -- Simulation time ~850us
        s_mode <= '1'; 
        s_verify <= '1';
        
        -- run
        WAIT FOR 100 ns;
        s_enable <= '1';
        WAIT FOR 20 ns;
        s_enable <= '0';
        
        WAIT FOR 100 us;
        
        -- Simulation of verify (mode = 1; verify = False = 0)
        -- Simulation time ~850us
        s_mode <= '1'; 
        s_verify <= '0';
        
        -- run
        WAIT FOR 100 ns;
        s_enable <= '1';
        WAIT FOR 20 ns;
        s_enable <= '0';
        
        WAIT;
        
    END PROCESS tx_gen;
    
END ARCHITECTURE tb_arch;
