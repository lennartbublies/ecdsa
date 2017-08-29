----------------------------------------------------------------------------------------------------
--  TOP LEVEL ENTITY - ECDSA
--  FPDA implementation of ECDSA algorithm  
--
--  Ports:
--   
--  Autor: Lennart Bublies (inf100434)
--  Date: 02.07.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) ecdsa package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.ALL;

PACKAGE tld_k163_ecdsa_package IS
  --CONSTANT M: natural := 8;
  CONSTANT M: natural := 9;
  --CONSTANT M: natural := 163;
END tld_k163_ecdsa_package;

------------------------------------------------------------
-- GF(2^M) ecdsa top level entity
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.ALL;
USE work.tld_k163_ecdsa_package.all;

ENTITY tld_ecdsa IS
    PORT (
        -- Clock and reset
        clk_i: IN std_logic; 
        rst_i: IN std_logic
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
    
    -- Internal signals -----------------------------------------
    
    -- ECDSA Entity
    SIGNAL ecdsa_enable, ecdsa_mode, ecdsa_done, ecdsa_valid: std_logic := '0';
    SIGNAL ecdsa_r_in, ecdsa_s_in, ecdsa_r_out, ecdsa_s_out: std_logic_vector(M-1 DOWNTO 0); 
    
    -- HASH Entity
    SIGNAL sha256_enable, sha256_ready, sha256_update: std_logic := '0';
    SIGNAL sha256_word_address : std_logic_vector(3 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL sha256_word_input, sha256_debug_port : std_logic_vector(31 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL sha256_hash_output : std_logic_vector(255 DOWNTO 0) := (OTHERS=>'0');    
BEGIN
    -- Instantiate ecdsa entity
    ecdsa: e_ecdsa PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i,
        enable_i => ecdsa_enable, 
        mode_i => ecdsa_mode, 
        hash_i => sha256_hash_output(M-1 DOWNTO 0),
        r_i => ecdsa_r_in,
        s_i => ecdsa_s_in,
        ready_o => ecdsa_done,
        valid_o => ecdsa_valid,
        sign_r_o => ecdsa_r_out,
        sign_s_o => ecdsa_s_out
    );

    -- Instantiate sha256 entity to compute hashes
    hash: sha256 PORT MAP(
        clk => clk_i,
        reset => rst_i,
        enable => sha256_enable, 
        ready => sha256_ready,
        update => sha256_update,
        word_address => sha256_word_address,
        word_input => sha256_word_input,
        hash_output => sha256_hash_output, -- ONLY 163 BIT ARE USED!
        debug_port => sha256_debug_port
    );

END;
