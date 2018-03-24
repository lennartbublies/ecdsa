----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Classic multiplication
--  Computes the polynomial multiplication mod F IN GF(2**m).
--
--  Ports:
--   a_i - First input value
--   b_i - Seccond input value
--   c_i - Output value
-- 
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) classical matrix multiplication
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_multiplier IS
    PORT (
        -- Input signals
        a_i: IN std_logic_vector(M-1 DOWNTO 0);
        b_i: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Output SIGNAL
        d_o: OUT std_logic_vector(2*M-2 DOWNTO 0)
    );
END e_gf2m_multiplier;

ARCHITECTURE rtl OF e_gf2m_multiplier IS
    -- Target matrix WITH double size of input
    TYPE matrix_ands IS array (0 TO 2*M-2) OF STD_LOGIC_VECTOR(2*M-2 DOWNTO 0);
    SIGNAL a_by_b: matrix_ands;
    
    -- Temporary output SIGNAL
    SIGNAL c: std_logic_vector(2*M-2 DOWNTO 0);
BEGIN
    gen_ands: FOR k IN 0 TO M-1 GENERATE
        l1: FOR i IN 0 TO k GENERATE
           a_by_b(k)(i) <= a_i(i) and b_i(k-i);
        END GENERATE;
    END GENERATE;

    gen_ands2: FOR k IN M TO 2*M-2 GENERATE
        l2: FOR i IN k TO 2*M-2 GENERATE
            a_by_b(k)(i) <= a_i(k-i+(M-1)) and b_i(i-(M-1));
        END GENERATE;
    END GENERATE;

    d_o(0) <= a_by_b(0)(0);
    gen_xors: FOR k IN 1 TO 2*M-2 GENERATE
        l3: PROCESS(a_by_b(k),c(k)) 
            VARIABLE aux: std_logic;
        BEGIN
            IF (k < M) THEN
                aux := a_by_b(k)(0);
                FOR i IN 1 TO k LOOP 
                    aux := a_by_b(k)(i) xor aux; 
                END LOOP;
            ELSE
                aux := a_by_b(k)(k);
                FOR i IN k+1 TO 2*M-2 LOOP 
                    aux := a_by_b(k)(i) xor aux; 
                END LOOP;
            END IF;
            d_o(k) <= aux;
        END PROCESS;
    END GENERATE;
END rtl;

------------------------------------------------------------
-- GF(2^M) polynomial reduction
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_reducer IS
    GENERIC (
        MODULO : std_logic_vector(M-1 DOWNTO 0)
    );
    PORT (
        -- Input SIGNAL
        d_i: IN std_logic_vector(2*M-2 DOWNTO 0);
        
        -- Output SIGNAL
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_reducer;

ARCHITECTURE rtl OF e_gf2m_reducer IS
    -- Initial reduction matrix from polynomial F
    CONSTANT R: matrix_reduction_return := reduction_matrix(MODULO);
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
-- GF(2^M) classic multiplication tld
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_classic_multiplier IS
    GENERIC (
        MODULO : std_logic_vector(M-1 DOWNTO 0)
    );
    PORT (
        a_i: IN std_logic_vector(M-1 DOWNTO 0); 
        b_i: IN std_logic_vector(M-1 DOWNTO 0);
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_classic_multiplier;

ARCHITECTURE rtl OF e_gf2m_classic_multiplier IS
    -- Instantiate polynomial multiplier
    COMPONENT e_gf2m_multiplier PORT (
        a_i: IN std_logic_vector(M-1 DOWNTO 0);
        b_i: IN std_logic_vector(M-1 DOWNTO 0);
        d_o: OUT std_logic_vector(2*M-2 DOWNTO 0) );
    END COMPONENT;
  
    -- Import entity e_gf2m_reducer
    COMPONENT e_gf2m_reducer IS
        GENERIC (
            MODULO : std_logic_vector(M-1 DOWNTO 0)
        );
        PORT(
            d_i: IN std_logic_vector(2*M-2 DOWNTO 0);
            c_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    end COMPONENT;

    SIGNAL d: std_logic_vector(2*M-2 DOWNTO 0);
BEGIN
    -- Combine polynomial multiplier and reducer
    instance_multiplier: e_gf2m_multiplier PORT MAP(
        a_i => a_i, 
        b_i => b_i, 
        d_o => d
    );

    -- Instantiate polynomial reducer
    reducer: e_gf2m_reducer GENERIC MAP (
            MODULO => MODULO
        ) PORT MAP(
            d_i => d, 
            c_o => c_o
        );
END rtl;