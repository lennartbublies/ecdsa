----------------------------------------------------------------------------
-- Classic Multiplier (classic_multiplier.vhd)
--
-- Computes the polynomial multiplication mod f IN GF(2**m)
-- The hardware IS genenerate FOR a specific f.
--
-- Defines 3 entities:
-- poly_multiplier: multiplies two m-bit polynomials and gives a 2*m-1 bits polynomial. 
-- poly_reducer: reduces a (2*m-1)- bit polynomial by f TO an m-bit polinomial
-- classic_multiplication: instantiates a poly_multiplier and a poly_reducer
-- and a Package (classic_multiplier_parameterse)
-- 
----------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE classic_multiplier_parameters IS
    -- Constants
    CONSTANT M: integer := 8;
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "00011011";
    --constant F: std_logic_vector(M-1 DOWNTO 0):= x"001B"; --FOR M=16 bits
    --constant F: std_logic_vector(M-1 DOWNTO 0):= x"0101001B"; --FOR M=32 bits
    --constant F: std_logic_vector(M-1 DOWNTO 0):= x"010100000101001B"; --FOR M=64 bits
    --constant F: std_logic_vector(M-1 DOWNTO 0):= x"0000000000000000010100000101001B"; --FOR M=128 bits
    --constant F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --FOR M=163
    --constant F: std_logic_vector(M-1 DOWNTO 0):= (0=> '1', 74 => '1', others => '0'); --FOR M=233
    
    -- Types
    TYPE matrix_reductionR IS ARRAY (0 TO M-1) OF STD_LOGIC_VECTOR(M-2 DOWNTO 0);
    
    -- Functions
    FUNCTION reduction_matrix_R RETURN matrix_reductionR;
END classic_multiplier_parameters;

PACKAGE BODY classic_multiplier_parameters IS
    FUNCTION reduction_matrix_R RETURN matrix_reductionR IS
    VARIABLE R: matrix_reductionR;
    BEGIN
        FOR j IN 0 TO M-1 LOOP
            FOR i IN 0 TO M-2 LOOP
                R(j)(i) := '0'; 
            END LOOP;
        END LOOP;
        
        FOR j IN 0 TO M-1 LOOP
            R(j)(0) := f(j);
        END LOOP;
        
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
END classic_multiplier_parameters;

------------------------------------------------------------
-- poly_multiplier
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.classic_multiplier_parameters.all;

ENTITY e_gf2m_multiplier IS
    PORT (
        a: IN std_logic_vector(M-1 DOWNTO 0);
        b: IN std_logic_vector(M-1 DOWNTO 0);
        d: OUT std_logic_vector(2*M-2 DOWNTO 0)
    );
END e_gf2m_multiplier;

ARCHITECTURE rtl OF e_gf2m_multiplier IS
    TYPE matrix_ands IS array (0 TO 2*M-2) OF STD_LOGIC_VECTOR(2*M-2 DOWNTO 0);
    SIGNAL a_by_b: matrix_ands;
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
-- poly_reducer
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.classic_multiplier_parameters.all;

ENTITY e_gf2m_reducer IS
    PORT (
        d: IN std_logic_vector(2*M-2 DOWNTO 0);
        c: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_reducer;

ARCHITECTURE rtl OF e_gf2m_reducer IS
    constant R: matrix_reductionR := reduction_matrix_R;
    SIGNAL S: matrix_reductionR;
BEGIN
    S <= R;
    gen_xors: FOR j IN 0 TO M-1 GENERATE
        l1: PROCESS(d) 
            VARIABLE aux: std_logic;
            BEGIN
                aux := d(j);
                FOR i IN 0 TO M-2 LOOP 
                    aux := aux xor (d(M+i) and R(j)(i)); 
                END LOOP;
                c(j) <= aux;
        END PROCESS;
    END GENERATE;
END rtl;


------------------------------------------------------------
-- Classic GF(2^M) Multiplication
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.classic_multiplier_parameters.all;

ENTITY e_classic_gf2m_multiplier IS
    PORT (
        a: IN std_logic_vector(M-1 DOWNTO 0); 
        b: IN std_logic_vector(M-1 DOWNTO 0);
        c: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_classic_gf2m_multiplier;

ARCHITECTURE rtl OF e_classic_gf2m_multiplier IS
    -- Include polynom multiplier
    COMPONENT e_gf2m_multiplier PORT (
        a: IN std_logic_vector(M-1 DOWNTO 0);
        b: IN std_logic_vector(M-1 DOWNTO 0);
        d: OUT std_logic_vector(2*M-2 DOWNTO 0) );
    END COMPONENT;
  
    -- Include polynom reducer
    COMPONENT e_gf2m_reducer PORT (
        d: IN std_logic_vector(2*M-2 DOWNTO 0);
        c: OUT std_logic_vector(M-1 DOWNTO 0));
    END COMPONENT;

    SIGNAL d: std_logic_vector(2*M-2 DOWNTO 0);
BEGIN
    -- Combine polynom multiplier and reducer
    instance_multiplier:  e_gf2m_multiplier PORT MAP(a => a, b => b, d => d);
    instance_reducer: e_gf2m_reducer PORT MAP(d => d, c => c);
END rtl;