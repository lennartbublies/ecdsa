----------------------------------------------------------------------------------------------------
--  TOP LEVEL ENTITY - ECDSA
--  FPDA implementation of ECDSA algorithm  
--
--  Ports:
--   
--  Autor: Lennart Bublies (inf100434), Leander Schulz (inf102143)
--  Date: 02.07.2017
--  Last Change: 10.11.2017
----------------------------------------------------------------------------------------------------
--
-- Pin Assignment:
--
-- clk_i        : PIN_N2  (Clock 50 Mhz)
-- rst_i        : PIN_N25 (Switch 0)
-- uart_rx_i    : PIN_C25 (UART Receiver)
-- uart_wx_i    : PIN_B25 (UART Transmitter)
--
------------------------------------------------------------
-- GF(2^M) ecdsa top level entity
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.ALL;
USE work.tld_ecdsa_package.all;

ENTITY tld_ecdsa IS
    PORT (
        -- Clock and reset
        clk_i: IN std_logic; 
        rst_i: IN std_logic;
        
        -- Uart read/write
        uart_rx_i : IN std_logic;
        uart_wx_i : OUT std_logic
    );
END tld_ecdsa;

ARCHITECTURE rtl OF tld_ecdsa IS 

    -- Components -----------------------------------------
    
    -- Import entity e_ecdsa
    COMPONENT e_ecdsa IS
        PORT (
            clk_i: IN std_logic; 
            rst_i: IN std_logic;
            enable_i: IN std_logic;
            mode_i: IN std_logic;
            hash_i: IN std_logic_vector(M-1 DOWNTO 0);
            r_i: IN std_logic_vector(M-1 DOWNTO 0);
            s_i: IN std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic;
            valid_o: OUT std_logic;
            sign_r_o: OUT std_logic_vector(M-1 DOWNTO 0);
            sign_s_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Import entity e_uart_receive_mux
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
    END COMPONENT;

    -- Import entity e_uart_transmit_mux
    COMPONENT e_uart_transmit_mux IS
        PORT ( 
            clk_i   : IN std_logic;
            rst_i   : IN std_logic;
            mode_i  : IN std_logic;
            enable_i : IN std_logic;
            r_i     : IN std_logic_vector(M-1 DOWNTO 0);
            s_i     : IN std_logic_vector(M-1 DOWNTO 0);
            v_i     : IN std_logic;
            uart_o  : OUT std_logic
        );
    END COMPONENT;
    
    -- Internal signals -----------------------------------------
    
    -- ECDSA Entity
    SIGNAL ecdsa_enable, ecdsa_mode, ecdsa_done, ecdsa_valid: std_logic := '0';
    SIGNAL ecdsa_r_in, ecdsa_s_in, ecdsa_r_out, ecdsa_s_out, ecdsa_hash: std_logic_vector(M-1 DOWNTO 0); 
BEGIN
    -- Instantiate ecdsa entity
    ecdsa: e_ecdsa PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => ecdsa_enable, 
        mode_i => ecdsa_mode, 
        hash_i => ecdsa_hash,
        r_i => ecdsa_r_in,
        s_i => ecdsa_s_in,
        ready_o => ecdsa_done,
        valid_o => ecdsa_valid,
        sign_r_o => ecdsa_r_out,
        sign_s_o => ecdsa_s_out
    );

    -- Instantiate uart entity to receive data
    uart_receive: e_uart_receive_mux PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        uart_i => uart_rx_i,
        mode_o => ecdsa_mode,
        r_o => ecdsa_r_in,
        s_o => ecdsa_s_in,
        m_o => ecdsa_hash,
        ready_o => ecdsa_enable
    );

    -- Instantiate uart entity to send data
    uart_transmit: e_uart_transmit_mux PORT MAP(
        clk_i => clk_i,
        rst_i => rst_i,
        mode_i => ecdsa_mode,
        enable_i => ecdsa_done,
        r_i => ecdsa_r_out,
        s_i => ecdsa_s_out,
        v_i => ecdsa_valid,
        uart_o => uart_wx_i
    );
END;
