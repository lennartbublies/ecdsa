----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Classic Squaring
--  Computes the polynomial multiplication A.A mod f IN GF(2**m)
--
--  Its IS based on classic modular multiplier, but USE the fact that
--  squaring a polinomial IS simplier than multiply.
--
--  Ports:
-- 
--  Source:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/classic_squarer.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 26.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) classic squaring package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE p_gf2m_classic_squarer_parameters IS
    -- Constants
    CONSTANT M: integer := 8;
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "00011011";
    --CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --FOR M=163
END p_gf2m_classic_squarer_parameters;

------------------------------------------------------------
-- GF(2^M) classic squaring
------------------------------------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.p_gf2m_classic_squarer_parameters.all;
USE work.p_gf2m_classic_multiplier_parameters.all;

ENTITY e_classic_gf2m_squarer IS
    PORT (
        -- Input SIGNAL
        a: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Output SIGNAL
        c: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_classic_gf2m_squarer;

ARCHITECTURE rtl OF e_classic_gf2m_squarer IS
    SIGNAL d: std_logic_vector(2*M-2 DOWNTO 0);
BEGIN
    D(0) <= a(0);

    -- TODO THIS SHOULD BE WRONG?
    square: FOR i IN 1 TO M-1 GENERATE
        d(2*i-1) <= '0';
        d(2*i) <= a(i);
    END GENERATE;

    -- Instantiate polynomial reducer
    reducer: work.e_gf2m_reducer PORT MAP(
            d => d, 
            c => c
        );
END rtl;