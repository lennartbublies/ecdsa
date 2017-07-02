----------------------------------------------------------------------------------------------------
--  Entity - GF(2^M) Adder
--  Calculate sum of two binary strings with size M-1 modulo F.
--
--  Ports:
--   rst_i    : global reset
--   clk_i    : clock signal
--   enable_i : enables or disables random number generation
--   a_i      : first input
--   b_i      : seccond input
--   c_o      : sum of first and seccond input modulo F
--   ready_o  : ready flag when finished
--    
--  TODO:
--   Ready flag not working correctly 
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 21.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) adder package
------------------------------------------------------------
LIBRARY ieee;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE p_gf2m_adder_parameters IS
    -- Constants
    CONSTANT M: integer := 8;
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "00011011";
    --constant F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --FOR M=163
END p_gf2m_adder_parameters;

------------------------------------------------------------
-- GF(2^M) adder
------------------------------------------------------------
LIBRARY ieee;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.p_gf2m_adder_parameters.all;

ENTITY e_gf2m_adder IS
    PORT(
        -- Clock and reset signal
        rst_i : IN  std_logic;
        clk_i : IN  std_logic;

        -- Enable signal
        enable_i : IN std_logic;

        -- Input signals
        a_i: IN std_logic_vector(M-1 DOWNTO 0); 
        b_i: IN std_logic_vector(M-1 DOWNTO 0);

        -- Ready signal
        ready_o : OUT std_logic;

        -- Output signal
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_adder;
 
ARCHITECTURE rtl OF e_gf2m_adder IS
    SIGNAL result : std_logic_vector(M-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ready : std_logic := '0';
BEGIN
	-- Clock process
	clock : PROCESS(clk_i, rst_i)
    BEGIN        
        -- Reset entity on reset
        IF (rst_i = '1') THEN 
            result <= (OTHERS => '0');
            ready <= '0';
        ELSIF (clk_i='1' and clk_i'event and enable_i='1') THEN
            FOR i IN 0 TO M-1 LOOP
                result(i) <= a_i(i) xor b_i(i);
            END LOOP;
            ready <= '1';
        END IF;
    END PROCESS clock;
    
    c_o <= result;
    ready_o <= ready;
END rtl;