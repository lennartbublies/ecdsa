----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Classic multiplication
--  Computes the polynomial multiplication mod F IN GF(2**m).
--
--  Ports:
-- 
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) classic multiplier PACKAGE
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE p_gf2m_classic_multiplier_parameters IS
    -- Constants
    CONSTANT M: integer := 163;
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --FOR M=163

    -- Types
    TYPE matrix_reductionR IS ARRAY (0 TO M-1) OF STD_LOGIC_VECTOR(M-2 DOWNTO 0);
    
    -- Functions
    FUNCTION reduction_matrix_R RETURN matrix_reductionR;
END p_gf2m_classic_multiplier_parameters;

PACKAGE BODY p_gf2m_classic_multiplier_parameters IS
    FUNCTION reduction_matrix_R RETURN matrix_reductionR IS
    VARIABLE R: matrix_reductionR;
    BEGIN
        -- Initialise matrix WITH zeros
        --   000000
        --   000000
        --   000000
        --   000000
        --   000000
        --   000000
        --   000000
        --   000000
        FOR j IN 0 TO M-1 LOOP
            FOR i IN 0 TO M-2 LOOP
                R(j)(i) := '0'; 
            END LOOP;
        END LOOP;
        
        -- Copy F polynomial "00011011" TO array 
        --   000001
        --   000001
        --   000000
        --   000001
        --   000001
        --   000000
        --   000000
        --   000000
        FOR j IN 0 TO M-1 LOOP
            R(j)(0) := F(j);
        END LOOP;
        
        -- Compute .... (after first round)
        --   0000 0 1
        --   0000 1 1
        --   0000 1 0     
        --   0000 1 1     
        --   0000 1 1     
        --   0000 1 0     
        --   0000 1 0     
        --   0000 1 0     
        FOR i IN 1 TO M-2 LOOP
            FOR j IN 0 TO M-1 LOOP
                IF j = 0 THEN 
                    R(j)(i) := R(M-1)(i-1) and R(j)(0);
                ELSE
                    R(j)(i) := R(j-1)(i-1) xor (R(M-1)(i-1) and R(j)(0)); 
                END IF;
            END LOOP;
        END LOOP;
        
        RETURN R;
    END reduction_matrix_R;
END p_gf2m_classic_multiplier_parameters;

------------------------------------------------------------
-- GF(2^M) classical matrix multiplication
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.p_gf2m_classic_multiplier_parameters.all;

ENTITY e_gf2m_multiplier IS
    PORT (
        -- Input signals
        a: IN std_logic_vector(M-1 DOWNTO 0);
        b: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Output SIGNAL
        d: OUT std_logic_vector(2*M-2 DOWNTO 0)
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
           a_by_b(k)(i) <= A(i) and B(k-i);
        END GENERATE;
    END GENERATE;

    gen_ands2: FOR k IN M TO 2*M-2 GENERATE
        l2: FOR i IN k TO 2*M-2 GENERATE
            a_by_b(k)(i) <= A(k-i+(M-1)) and B(i-(M-1));
        END GENERATE;
    END GENERATE;

    d(0) <= a_by_b(0)(0);
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
            d(k) <= aux;
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
USE work.p_gf2m_classic_multiplier_parameters.all;

ENTITY e_gf2m_cm_reducer IS
    PORT (
        -- Input SIGNAL
        d: IN std_logic_vector(2*M-2 DOWNTO 0);
        
        -- Output SIGNAL
        c: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_cm_reducer;

ARCHITECTURE rtl OF e_gf2m_cm_reducer IS
    -- Initial reduction matrix from polynomial F
    CONSTANT R: matrix_reductionR := reduction_matrix_R;
    -- Temporary SIGNAL, neccessary?
    SIGNAL S: matrix_reductionR;
BEGIN
    S <= R; -- TODO: neccessary?
    
    -- GENERATE M-1 XORs FOR each redcutions matrix row
    gen_xors: FOR j IN 0 TO M-1 GENERATE
        l1: PROCESS(d) 
            VARIABLE aux: std_logic;
            BEGIN
                -- Store j-bit from input
                aux := d(j);
                
                -- Compute target bit FOR each reduction matrix column
                FOR i IN 0 TO M-2 LOOP 
                    aux := aux xor (d(M+i) and R(j)(i)); 
                END LOOP;
                c(j) <= aux;
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
USE work.p_gf2m_classic_multiplier_parameters.all;

ENTITY e_classic_gf2m_multiplier IS
    PORT (
        a_i: IN std_logic_vector(M-1 DOWNTO 0); 
        b_i: IN std_logic_vector(M-1 DOWNTO 0);
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_classic_gf2m_multiplier;

ARCHITECTURE rtl OF e_classic_gf2m_multiplier IS
    -- Instantiate polynomial multiplier
    COMPONENT e_gf2m_multiplier PORT (
        a: IN std_logic_vector(M-1 DOWNTO 0);
        b: IN std_logic_vector(M-1 DOWNTO 0);
        d: OUT std_logic_vector(2*M-2 DOWNTO 0) );
    END COMPONENT;
  
    -- Instantiate polynomial reducer
    COMPONENT e_gf2m_cm_reducer PORT (
        d: IN std_logic_vector(2*M-2 DOWNTO 0);
        c: OUT std_logic_vector(M-1 DOWNTO 0));
    END COMPONENT;

    SIGNAL d: std_logic_vector(2*M-2 DOWNTO 0);
BEGIN
    -- Combine polynomial multiplier and reducer
    instance_multiplier: e_gf2m_multiplier PORT MAP(
        a => a_i, 
        b => b_i, 
        d => d
    );

    instance_reducer: e_gf2m_cm_reducer PORT MAP(
        d => d, 
        c => c_o
    );
END rtl;