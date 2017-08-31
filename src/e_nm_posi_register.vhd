----------------------------------------------------------------------------------------------------
--  ENTITY - Parallel In Serial Out Register
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY e_nm_posi_register IS
    GENERIC (
        N : integer;
        M : integer
    );
    PORT(
        clk_i : IN std_logic;
        rst_i : IN std_logic;
        enable_i : IN std_logic;
        load_i : IN std_logic;
        data_i : IN std_logic_vector(N-1 DOWNTO 0);
        data_o : OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_nm_posi_register;

ARCHITECTURE rtl OF e_nm_posi_register IS
    SIGNAL temp : std_logic_vector(N-1 DOWNTO 0);
BEGIN
    PROCESS (clk_i, rst_i, load_i, data_i) IS
    BEGIN
        IF (rst_i='1') THEN
            temp <= (OTHERS=>'0');
        ELSIF (load_i = '1') THEN
            temp <= data_i ;
        ELSIF (clk_i'event and clk_i='1' and enable_i='1') THEN
            temp(N-M-1 DOWNTO 0) <= temp(N-1 DOWNTO M);
            data_o(M-1 DOWNTO 0) <= temp(M-1 DOWNTO 0);
        END IF;
    END PROCESS;
END rtl;