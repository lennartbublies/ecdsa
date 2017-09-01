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

ENTITY e_uart_transmit_mux IS
    PORT ( 
        -- Clock and reset
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        
        -- Enable flag
        enable_i : IN std_logic;
        
        -- Input
        r_i : IN std_logic_vector(M-1 DOWNTO 0);
        s_i : IN std_logic_vector(M-1 DOWNTO 0);
        v_i : IN std_logic;
        
        -- UART
        uart_o : OUT std_logic
    );
END e_uart_transmit_mux;

ARCHITECTURE rtl OF e_uart_transmit_mux IS
    -- Import entity e_posi_register 
    COMPONENT e_nm_posi_register  IS
        GENERIC (
            N : integer;
            M : integer
        );
        PORT(
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            enable_i : IN std_logic;
            load_i : IN std_logic;
            data_i : IN std_logic_vector(N-1 DOWNTO 0);
            data_o : OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;

    -- TODO IMPORT UART COMPONENT
    
    -- Internal signals
    SIGNAL uart_data: std_logic_vector(7 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL enable_r_register, enable_s_register: std_logic := '0';
BEGIN
    -- Instantiate sipo register entity for r register
    r_register: e_nm_posi_register GENERIC MAP (
        N => M,
        M => 8
    ) PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => enable_r_register, 
        load_i => enable_i,         
        data_i => r_i, 
        data_o => uart_data
    );
        
    -- Instantiate sipo register entity for r register
    s_register: e_nm_posi_register GENERIC MAP (
        N => M,
        M => 8
    ) PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => enable_s_register, 
        load_i => enable_i,         
        data_i => s_i, 
        data_o => uart_data
    );
	
	-- TODO VERIFY FLAG TO UART 
	--v_i -> uart_data
	
	-- TODO INSTANTIATE UART ENTITY
	--	-> Write to UART from FPGA. Read from POSI registers
	--	-> Swtich between the right input register: ENABLE_S_REGISTER, ENABLE_R_REGISTER and VERIFY FLAG
	--		--> Input register are automatically loaded when ECDSA entity is ready (load_i => enable_i)
	--		--> Ready from register entity when ENABLE_I is set
END rtl;