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
USE work.tld_ecdsa_package.all;

ENTITY e_nm_sipo_register IS
    PORT ( 
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        enable_i : IN std_logic;
        data_i : IN std_logic_vector(U-1 DOWNTO 0);
        data_o : OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_nm_sipo_register;

ARCHITECTURE rtl OF e_nm_sipo_register IS
	SIGNAL temp: std_logic_vector(M-1 DOWNTO 0);
BEGIN
    PROCESS(clk_i,rst_i,enable_i)
    BEGIN
        IF rst_i = '1' THEN 
            temp <= (OTHERS => '0');
        ELSIF(clk_i'event and clk_i='1' and enable_i='1') THEN
            temp(M-1 DOWNTO U) <= temp(M-U-1 DOWNTO 0);
            temp(U-1 DOWNTO 0) <= data_i(U-1 DOWNTO 0);
        END IF;
    END PROCESS;
	 
	data_o <= temp;
END rtl;
