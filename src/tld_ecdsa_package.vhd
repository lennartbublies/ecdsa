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
--  Autor: Lennart Bublies (inf100434), Leander Schulz (inf102143)
--  Date: 02.07.2017
--  Last Change: 17.11.2017
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
    -- Elliptic curve parameter of sect163k1 and generated private and public key
    --  See http://www.secg.org/SEC2-Ver-1.0.pdf for more information

    -- 163 Bit sect163k1
    CONSTANT M: natural := 163;
    CONSTANT logM: integer := 9;--logM IS the number of bits of m plus an additional sign bit
    CONSTANT N: std_logic_vector(M DOWNTO 0) := x"800000000000000000000000000000000000000C9";
    --CONSTANT N: std_logic_vector(M DOWNTO 0) := x"4000000000000000000020108A2E0CC0D99F8A5EF";
    CONSTANT P: std_logic_vector(M DOWNTO 0) := x"800000000000000000000000000000000000000C9";
    CONSTANT A: std_logic_vector(M-1 downto 0) := (0 => '1', OTHERS=>'0');

    -- Set parameter of sect163k1
    CONSTANT xG: std_logic_vector(M-1 DOWNTO 0) := "010" & x"FE13C0537BBC11ACAA07D793DE4E6D5E5C94EEE8";
    CONSTANT yG: std_logic_vector(M-1 DOWNTO 0) := "010" & x"89070FB05D38FF58321F2E800536D538CCDAA3D9";
    CONSTANT k: std_logic_vector(M-1 DOWNTO 0) := "000" & x"CD06203260EEE9549351BD29733E7D1E2ED49D88";

    -- VDHL point multiplication version 1 - original from C
    --CONSTANT dA: std_logic_vector(M-1 DOWNTO 0) := "101" & x"4E78BA70719678AFC09BA25E822B81FCF23B87CA";
    --CONSTANT xQB: std_logic_vector(M-1 DOWNTO 0) := "110" & x"D4845314B7851DA63B9569E812A6602A22493216";
    --CONSTANT yQB: std_logic_vector(M-1 DOWNTO 0) := "000" & x"0D5B712A2981DD2FB1AFA15FE4079C79A3724BB0";
    
    -- VDHL point multiplication version 2
    CONSTANT dA: std_logic_vector(M-1 DOWNTO 0) := "000" & x"CD06203260EEE9549351BD29733E7D1E2ED49D88";
    CONSTANT xQB: std_logic_vector(M-1 DOWNTO 0) := "000" & x"06E24E8B2B34F45098730E20100D52121AE91873";
    CONSTANT yQB: std_logic_vector(M-1 DOWNTO 0) := "001" & x"5B1340F838650657125A796EBB6B67CDBE442048";    
    --CONSTANT dA: std_logic_vector(M-1 DOWNTO 0) := "101" & x"4E78BA70719678AFC09BA25E822B81FCF23B87CA";
    --CONSTANT xQB: std_logic_vector(M-1 DOWNTO 0) := "010" & x"97677AE929EE458EB7D1945E964194E9152A69D5";
    --CONSTANT yQB: std_logic_vector(M-1 DOWNTO 0) := "110" & x"9A4C4A2DB7725B9DE1485B8C5EF89E4BD540AE6F";
    
    -- 9 Bit testcurve
    --CONSTANT M: natural := 9;
    --CONSTANT logM: integer := 5;
    --CONSTANT N: std_logic_vector(M downto 0) := "1000000011";
    --CONSTANT P: std_logic_vector(M downto 0) := "1000000011";
    --CONSTANT A: std_logic_vector(M-1 downto 0) := (0 => '1', OTHERS=>'0');

    --CONSTANT xG: std_logic_vector(M-1 DOWNTO 0) := "011101110";
    --CONSTANT yG: std_logic_vector(M-1 DOWNTO 0) := "010101111";
    --CONSTANT P: std_logic_vector(M-1 DOWNTO 0) := "000000000";
    --CONSTANT dA: std_logic_vector(M-1 DOWNTO 0) := "000111110";
    --CONSTANT xQB: std_logic_vector(M-1 DOWNTO 0) := "011000101";
    --CONSTANT yQB: std_logic_vector(M-1 DOWNTO 0) := "111011010";
    --CONSTANT k: std_logic_vector(M-1 DOWNTO 0) := "001101001";
    
    -- UART
    CONSTANT U: natural := 8;
    CONSTANT BAUD_RATE: INTEGER RANGE 1200 TO 500000 := 9600;
    
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
