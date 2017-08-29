----------------------------------------------------------------------------------------------------
--  ENTITY - Serial In Parallel Out Register
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY e_sipo_register IS
    GENERIC (
        N : integer
    );
    PORT ( 
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        enable_i : IN std_logic;
        data_i : IN std_logic;
        data_o : OUT std_logic_vector(N-1 DOWNTO 0)
    );
END e_sipo_register;

ARCHITECTURE rtl OF e_sipo_register IS
	SIGNAL temp: std_logic_vector(N-1 DOWNTO 0);
BEGIN
    PROCESS(clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            temp <= (OTHERS => '0');
        ELSIF(clk_i'event and clk_i='1' and enable_i='1') THEN
            temp(N-1 DOWNTO 1) <= temp(N-2 DOWNTO 0);
            temp(0) <= data_i;
        END IF;
    END PROCESS;
	 
	data_o <= temp;
END rtl;
