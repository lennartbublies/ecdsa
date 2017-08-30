----------------------------------------------------------------------------------------------------
--  ENTITY - Multiplexer for UART
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

USE work.e_k163_ecdsa_package.all;

ENTITY e_uart_receive_mux IS
    PORT ( 
        -- Clock, reset and enable
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        enable_i : IN std_logic;
        
        -- UART
        uart_i : IN std_logic;
        
        -- Output
        r_o : OUT std_logic_vector(M-1 DOWNTO 0)
        s_o : OUT std_logic_vector(M-1 DOWNTO 0)
        m_o : OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_uart_receive_mux;

ARCHITECTURE rtl OF e_uart_receive_mux IS
    -- Import entity e_sipo_register 
    COMPONENT e_nm_sipo_register  IS
        GENERIC (
            N : integer;
            M : integer
        );
        PORT(
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            enable_i : IN std_logic;
            data_i : IN std_logic_vector(N-1 DOWNTO 0);
            data_o : OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;
    
    -- TODO IMPORT UART COMPONENT
    
    -- Internal signals
    SIGNAL uart_data: std_logic_vector(7 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL enable_r_register, enable_s_register, enable_m_register: std_logic := '0';
BEGIN
    -- Instantiate sipo register entity for r register
    r_register: e_nm_sipo_register GENERIC MAP (
            N => 8,
            M => M
        ) PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => enable_r_register,  
            data_i => uart_data, 
            data_o => r_o
        );
        
    -- Instantiate sipo register entity for s register
    s_register: e_nm_sipo_register GENERIC MAP (
            N => 8,
            M => M
        ) PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => enable_s_register,  
            data_i => uart_data, 
            data_o => s_o
        );

    -- Instantiate sipo register entity for m register
    m_register: e_nm_sipo_register GENERIC MAP (
            N => 8,
            M => M
        ) PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => enable_m_register,  
            data_i => uart_data, 
            data_o => m_o
        );
        
    -- TODO INSTANTIATE UART ENTITY
END rtl;
