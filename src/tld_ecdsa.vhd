----------------------------------------------------------------------------------------------------
--  TOP LEVEL ENTITY - ECDSA
--  FPDA implementation of ECDSA algorithm  
--
--  Ports:
--   
--  Autor: Lennart Bublies (inf100434)
--  Date: 02.07.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
use work.e_k163_point_multiplication_package.all;

ENTITY tld_ecdsa IS
    PORT (
        -- Clock and reset
        clk_i: IN std_logic; 
        rst_i: IN std_logic;
        
        -- Generate (private) and public key
        gen_keys_i : IN std_logic;
        
        -- Switch between SIGN and VALIDATE
        mode_i: IN std_logic
    );
END tld_ecdsa;

ARCHITECTURE rtl OF tld_ecdsa IS 
    -- Components -----------------------------------------
    
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
    SIGNAL sha256_enable, sha256_ready, sha256_update : std_logic := '0';
    SIGNAL sha256_word_address : std_logic_vector(3 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL sha256_word_input, sha256_debug_port : std_logic_vector(31 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL sha256_hash_output : std_logic_vector(255 DOWNTO 0) := (OTHERS=>'0');
    
    -- Import entity e_k163_point_multiplication
    COMPONENT e_k163_point_multiplication IS
        PORT (
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic;
            xp_i: IN std_logic_vector(M-1 DOWNTO 0); 
            yp_i: IN std_logic_vector(M-1 DOWNTO 0); 
            k: IN std_logic_vector(M-1 DOWNTO 0);
            xq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            yq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;

    -- Import entity e_k163_point_addition
    COMPONENT e_k163_point_addition IS
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic;
            x1_i: IN std_logic_vector(M-1 DOWNTO 0);
            y1_i: IN std_logic_vector(M-1 DOWNTO 0); 
            x2_i: IN std_logic_vector(M-1 DOWNTO 0); 
            y2_i: IN std_logic_vector(M-1 DOWNTO 0);
            x3_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            y3_o: OUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;
    SIGNAL px, py, qx, qy, rx, ry: std_logic_vector(M-1 DOWNTO 0); 
    SIGNAL enable, ready: std_logic;
    
    -- Internal signals -----------------------------------------
    
    -- Elliptic curve parameter of sect163k1 and generated private and public key
    --  See http://www.secg.org/SEC2-Ver-1.0.pdf for more information
    SIGNAL xG : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- X of generator point G = (x, y)
    SIGNAL yG : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- Y of generator point G = (x, y)
    SIGNAL dA : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- Private key dA = k
    SIGNAL xQA : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- X component of public key qA = k.G = (xQA, yQA)
    SIGNAL yQA : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- Y component of public key qA = k.G = (xQA, yQA)
    SIGNAL N : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');   -- Order of generator point G
    SIGNAL done_gen_key: std_logic := '0';
    
    -- States for state machine
    subtype states IS natural RANGE 0 TO 1;
    SIGNAL current_state: states;
BEGIN
    -- Set parameter of sect163k1
    xG  <= "010" & x"FE13C0537BBC11ACAA07D793DE4E6D5E5C94EEE8";
    yG  <= "010" & x"89070FB05D38FF58321F2E800536D538CCDAA3D9";
    N   <= "100" & x"000000000000000000020108A2E0CC0D99f8A5EE";
    dA  <= "000" & x"2FA9FB1832696E2A6D29776BCA3653C3F398D370";
    --xQA <= "000" & x"0000000000000000000000000000000000000000";
    --yQA <= "000" & x"0000000000000000000000000000000000000000";
 
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
    
    -- Instantiate multiplier to generate private and public key
    gen_key_multiplier: e_k163_point_multiplication PORT MAP(
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => gen_keys_i, 
        xp_i => xG, 
        yp_i => yG, 
        k => dA,
        xq_io => xQA, 
        yq_io => yQA, 
        ready_o => done_gen_key 
    );

    -- Instantiate point addition entity
    adder: e_k163_point_addition PORT MAP ( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable,
        x1_i => px, 
        y1_i => py, 
        x2_i => qx, 
        y2_i => qy,
        x3_io => rx, 
        y3_o => ry,
        ready_o => ready
    );
    
    -- State machine process
    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
    
    END PROCESS;
END;