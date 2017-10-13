----------------------------------------------------------------------------------------------------
--  TOP LEVEL ENTITY - ECDSA
--  FPGA implementation of ECDSA algorithm  
--
--  Constants:
--   M     - Galois field base GF(p=2^M)
--   P     - Number of element in GF(p=2^M)
--   logM  - Helper for M
--   N     - N part of ECC curve
--   A     - A part of ECC curve
--   U     - Length of UART input/output
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

PACKAGE tld_ecdsa_package IS
    -- 163 Bit sect163k1
    CONSTANT M: natural := 163;
    CONSTANT logM: integer := 9;--logM IS the number of bits of m plus an additional sign bit
    --CONSTANT N: std_logic_vector(M DOWNTO 0):= x"800000000000000000000000000000000000000C9";
    CONSTANT N: std_logic_vector(M DOWNTO 0):= x"4000000000000000000020108A2E0CC0D99F8A5EF";
    CONSTANT P: std_logic_vector(M DOWNTO 0):= x"800000000000000000000000000000000000000C9";
    CONSTANT A: std_logic_vector(M-1 downto 0) := (0 => '1', OTHERS=>'0');

    -- 9 Bit testcurve
    --CONSTANT M: natural := 9;
    --CONSTANT logM: integer := 5;
    --CONSTANT N: std_logic_vector(M downto 0):= "1000000011";
    --CONSTANT P: std_logic_vector(M-1 downto 0):= "000000011";
    --CONSTANT A: std_logic_vector(M-1 downto 0) := (0 => '1', OTHERS=>'0');

    -- UART
    CONSTANT U: natural := 8;
    
    -- Other
    CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS => '0');
    CONSTANT ONES: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'1');
    CONSTANT ONE: std_logic_vector(M downto 0) := (0 => '1', OTHERS=>'0');

    -- Types for reduction matrix
    TYPE matrix_reduction_return IS ARRAY (0 TO M-1) OF STD_LOGIC_VECTOR(M-2 DOWNTO 0);
    SUBTYPE matrix_reduction_arg IS STD_LOGIC_VECTOR(M-1 DOWNTO 0);
    
    -- Functions
    FUNCTION reduction_matrix(MODULO: matrix_reduction_arg) RETURN matrix_reduction_return;
END tld_ecdsa_package;

PACKAGE BODY tld_ecdsa_package IS
    FUNCTION reduction_matrix(MODULO: matrix_reduction_arg) RETURN matrix_reduction_return IS
    VARIABLE R: matrix_reduction_return;
    BEGIN
        -- Initialise matrix
        FOR j IN 0 TO M-1 LOOP
            FOR i IN 0 TO M-2 LOOP
                R(j)(i) := '0'; 
            END LOOP;
        END LOOP;
        
        -- Copy polynomial 
        FOR j IN 0 TO M-1 LOOP
            R(j)(0) := MODULO(j);
        END LOOP;
        
        -- Compute lookup table   
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
    END reduction_matrix;
END tld_ecdsa_package;
