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
        -- Clock and reset
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        
        -- UART
        uart_i : IN std_logic;
        
        -- Set mode
        mode_o : IN std_logic;
        
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
    
    -- Import entity sha256
    COMPONENT sha256 IS
        PORT (
            clk : IN std_logic;
            reset : IN std_logic;
            enable : IN std_logic;
            ready : OUT std_logic;
            update : IN std_logic;
            word_address : OUT std_logic_vector(3 DOWNTO 0);
            word_input : IN std_logic_vector(31 DOWNTO 0);
            hash_output : OUT std_logic_vector(255 DOWNTO 0);
            debug_port : OUT std_logic_vector(31 DOWNTO 0)
        );
    END COMPONENT;
	
	--COMPONENT e_uart_receive_data IS
	--	GENERIC ( baud_rate : IN NATURAL RANGE 1200 TO 500000);
	--	PORT (
	--		clk_i : IN	std_logic;
	--		rst_i : IN	std_logic;
	--		rx_i : IN	std_logic;
	--		mode_i : IN	std_logic;
	--		wrreq_o	: OUT std_logic;
	--		fifo_o : OUT std_logic_vector (7 DOWNTO 0);
	--		sig_o : OUT	std_logic_vector (163 DOWNTO 0);
	--		rdy_o : OUT	std_logic
	--	);
	--END COMPONENT e_uart_receive_data;
    
    -- TODO IMPORT UART COMPONENT
    
    -- Internal signals
    SIGNAL uart_data: std_logic_vector(7 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL enable_r_register, enable_s_register, enable_m_register: std_logic := '0';

    -- HASH Entity
    SIGNAL sha256_ready, sha256_update: std_logic := '0';
    SIGNAL sha256_enable: std_logic := '1';
    SIGNAL sha256_word_address : std_logic_vector(3 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL sha256_word_input, sha256_debug_port : std_logic_vector(31 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL sha256_hash_output : std_logic_vector(255 DOWNTO 0) := (OTHERS=>'0');    
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
        data_o => m_o --sha256_word_input
    );
    
    -- Instantiate sha256 entity to compute hashes
    hash: sha256 PORT MAP(
        clk => clk_i,
        reset => rst_i,
        enable => sha256_enable,                               -- ENABLE ENTITY, CAN BE FORCED TO 1!
        ready => sha256_ready,                                 -- READY FLAG FOR HASH COMPUTED
        update => sha256_update, --enable_m_register           -- START GENERATING HASH
        word_address => sha256_word_address,                   
        word_input => sha256_word_input,                       -- INPUT BUFFER 
        hash_output => sha256_hash_output, --m_o(M-1 DOWNTO 0) -- ONLY 163 BIT ARE USED!
        debug_port => sha256_debug_port                        -- NOT NEEDED
    );
     
	--e_uart_receive_data_inst : e_uart_receive_data 
	--GENERIC MAP (
	--	baud_rate => 500000 
	--)
    --PORT MAP ( 
	--	clk_i => clk_i,
	--	rst_i => rst_i,
	--	rx_i => uart_i,
	--	mode_i => mode_o,	--> INPUT? OUTPUT!
	--	wrreq_o	=> uart_data, 		
	--	fifo_o => ,			--> NOT USED
	--	sig_o => ,			--> NOT USED
	--	rdy_o => ready_o 
    --);
	
    -- TODO INSTANTIATE UART ENTITY
    --  -> Read UART from FPGA and write byte to: UART_DATA
    --  -> Switch between register using flags: ENABLE_S_REGISTER, ENABLE_R_REGISTER, ENABLE_M_REGISTER
	--		--> Fill the right register!
    --  -> Set READY_O flag to active ECDSA entity (after reading all necessary input data)
	--		--> After all registers are full, activate ECDSA entity
    --  -> Set MODE_O flag
	--		--> Set mode flag to activate SIGN/VERFIY feature
	--
    --  OPTIONAL: 
	--		-> Create hashes
    --      --> Change M_REGISTER to 32 output
    --      --> Change 
END rtl;