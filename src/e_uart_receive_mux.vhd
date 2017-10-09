----------------------------------------------------------------------------------------------------
--  ENTITY - Multiplexer for UART
--
--  Autor: Lennart Bublies (inf100434), Leander Schulz (inf102143)
--  Date: 29.06.2017
--  Modified: 17.09.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

USE work.tld_ecdsa_package.all;

ENTITY e_uart_receive_mux IS
    PORT ( 
        -- Clock and reset
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        
        -- UART
        uart_i : IN std_logic;
        
        -- Set mode
        mode_i : IN std_logic;
        
        -- Output
        r_o : OUT std_logic_vector(M-1 DOWNTO 0);
        s_o : OUT std_logic_vector(M-1 DOWNTO 0);
        m_o : OUT std_logic_vector(M-1 DOWNTO 0);
        
        -- Ready flag
        ready_o : OUT std_logic
    );
END e_uart_receive_mux;

ARCHITECTURE rtl OF e_uart_receive_mux IS
    -- Import entity e_sipo_register 
    COMPONENT e_nm_sipo_register  IS
        PORT(
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            enable_i : IN std_logic;
            data_i : IN std_logic_vector(U-1 DOWNTO 0);
            data_o : OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;

    -- IMPORT UART COMPONENT
	COMPONENT e_uart_receive_data IS
		GENERIC ( 
			baud_rate : IN NATURAL RANGE 1200 TO 500000;
            N : IN NATURAL RANGE 1 TO 256;
            M : IN NATURAL RANGE 1 TO 256);
		PORT (
			clk_i    : IN  std_logic;
			rst_i    : IN  std_logic;
			rx_i     : IN  std_logic;
			mode_i   : IN  std_logic;
			data_o   : OUT std_logic_vector (7 DOWNTO 0);
			ena_r_o	 : OUT std_logic;
			ena_s_o	 : OUT std_logic;
			ena_m_o	 : OUT std_logic;
			rdy_o    : OUT std_logic);
	 END COMPONENT e_uart_receive_data;
    
    -- Internal signals
    SIGNAL uart_data: std_logic_vector(7 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL enable_r_register, enable_s_register, enable_m_register: std_logic := '0';

	-- UART signals
	--SIGNAL s_uart_data: std_logic_vector (M-1 DOWNTO 0) := (OTHERS=>'0');
	
BEGIN
    -- Instantiate sipo register entity for r register
    r_register: e_nm_sipo_register PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => enable_r_register,  
        data_i => uart_data, 
        data_o => r_o
    );
        
    -- Instantiate sipo register entity for s register
    s_register: e_nm_sipo_register PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => enable_s_register,  
        data_i => uart_data, 
        data_o => s_o
    );

    -- Instantiate sipo register entity for m register
    m_register: e_nm_sipo_register PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => enable_m_register,  
        data_i => uart_data, 
        data_o => m_o
    );
     
    -- INSTANTIATE UART ENTITY
    --  -> Read UART from FPGA and write byte to: UART_DATA
    --  -> Switch between register using flags: ENABLE_S_REGISTER, ENABLE_R_REGISTER, ENABLE_M_REGISTER 
    --  -> Set READY_O flag to active ECDSA entity (after reading all necessary input data)
    --  -> Set MODE_O flag
    --  -> Create hashes
    --      --> Change M_REGISTER to 32 output
    --      --> Change 
	uart_receiver: e_uart_receive_data
	GENERIC MAP ( 
		baud_rate => 500000, -- 9600 in production
		N => 8,	-- length of message
		M => M)  -- length of key
	PORT MAP (
		clk_i    => clk_i,
		rst_i    => rst_i,
		rx_i     => uart_i,
		mode_i   => mode_i,
		data_o   => uart_data,
		ena_r_o	 => enable_r_register, 
		ena_s_o	 => enable_s_register, 
		ena_m_o	 => enable_m_register,
		rdy_o    => ready_o
	);
	
END rtl;
