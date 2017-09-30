----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Classic Squaring
--  Computes the polynomial multiplication A.A mod f IN GF(2**m)
--
--  Ports:
--   a_i : Input to square
--   c_o : Square of input
-- 
--  Example:
--   (x^2 + x + 1)^2 = (x^4+x^2+1) 
--     1 1 1         =   1 0 1 0 1
--
--  Based on:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/classic_squarer.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 26.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) polynomial reduction
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_reducer IS
    PORT (
        -- Input SIGNAL
        d_i: IN std_logic_vector(2*M-2 DOWNTO 0);
        
        -- Output SIGNAL
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_reducer;

ARCHITECTURE rtl OF e_gf2m_reducer IS
    -- Initial reduction matrix from polynomial F
    CONSTANT R: matrix_reductionR := reduction_matrix_R;
BEGIN
    -- GENERATE M-1 XORs FOR each redcutions matrix row
    gen_xors: FOR j IN 0 TO M-1 GENERATE
        l1: PROCESS(d_i) 
            VARIABLE aux: std_logic;
            BEGIN
                -- Store j-bit from input
                aux := d_i(j);
                
                -- Compute target bit FOR each reduction matrix column
                FOR i IN 0 TO M-2 LOOP 
                    aux := aux xor (d_i(M+i) and R(j)(i)); 
                END LOOP;
                c_o(j) <= aux;
        END PROCESS;
    END GENERATE;
END rtl;

------------------------------------------------------------
-- GF(2^M) classic squaring entity
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_classic_squarer IS
    PORT (
        -- Input SIGNAL
        a_i: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Output SIGNAL
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_classic_squarer;

ARCHITECTURE rtl OF e_gf2m_classic_squarer IS
    -- Import entity e_gf2m_reducer
    COMPONENT e_gf2m_reducer IS
        PORT(
            d_i: IN std_logic_vector(2*M-2 DOWNTO 0);
            c_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    end COMPONENT;

    SIGNAL d: std_logic_vector(2*M-2 DOWNTO 0);
BEGIN
    d(0) <= a_i(0);

    -- Polynomial multiplication
    --  Calculates: x * x
    --    1 1 1 = 1 0 1 0 1
    --        -           -
    --      -         -
    --    -       -
    square: FOR i IN 1 TO M-1 GENERATE
        d(2*i-1) <= '0';
        d(2*i) <= a_i(i);
    END GENERATE;

    -- Instantiate polynomial reducer
    reducer: e_gf2m_reducer PORT MAP(
            d_i => d, 
            c_o => c_o
        );
END rtl;