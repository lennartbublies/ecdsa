----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Key Generation 
--
--  Ports:
--   clk_i     - Clock
--   rst_i     - Reset flag
--   enable_i  - Enable sign or verify
--   k_i       - Input private key_generation
--   xQ_o      - x component of public key
--   yQ_o      - y component of public key
--   ready_o   - Ready flag if sign or validation is complete
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 02.07.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) ecdsa top level entity
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.ALL;
USE work.tld_ecdsa_package.all;

ENTITY e_ecdsa_key_generation IS
    PORT (
        -- Clock and reset
        clk_i: IN std_logic; 
        rst_i: IN std_logic;

        -- Enable computation
        enable_i: IN std_logic;

        -- Private Key
        k_i: IN std_logic_vector(M-1 DOWNTO 0);

        -- Public Key
        xQ_o: INOUT std_logic_vector(M-1 DOWNTO 0);
        yQ_o: INOUT std_logic_vector(M-1 DOWNTO 0);
        
        -- Ready flag
        ready_o: OUT std_logic
    );
END e_ecdsa_key_generation;

ARCHITECTURE rtl OF e_ecdsa_key_generation IS 

    -- Components -----------------------------------------

    -- Import entity e_gf2m_doubleadd_point_multiplication
    COMPONENT e_gf2m_point_multiplication IS
    --COMPONENT e_gf2m_doubleadd_point_multiplication IS
        GENERIC (
            MODULO : std_logic_vector(M DOWNTO 0)
        );
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
    
    -- Internal signals -----------------------------------------
    
    --SIGNAL k : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');   -- k for point generator, should be cryptograic secure randum number!
    SIGNAL xG : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- X of generator point G = (x, y)
    SIGNAL yG : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- Y of generator point G = (x, y)    
BEGIN
    -- Set parameter of sect163k1
    xG  <= "010" & x"FE13C0537BBC11ACAA07D793DE4E6D5E5C94EEE8";
    yG  <= "010" & x"89070FB05D38FF58321F2E800536D538CCDAA3D9";
    --k   <= "000" & x"CD06203260EEE9549351BD29733E7D1E2ED49D88";
    
    -- Instantiate multiplier to compute (xQ, yQ) = dP
    key_generation: e_gf2m_point_multiplication GENERIC MAP (
    --key_generation: e_gf2m_doubleadd_point_multiplication GENERIC MAP (
            MODULO => P
    ) PORT MAP (
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_i, 
        xp_i => xG, 
        yp_i => yG, 
        k => k_i,
        xq_io => xQ_o, 
        yq_io => yQ_o, 
        ready_o => ready_o
    );
END;