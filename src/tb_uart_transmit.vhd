-------------------------------------------------------------------------------
-- Module:       transmit_data_tb
-- Purpose:      Testbench for module transmit_data.
--               Test if an ascii character is transmitted correctly
-- Author:       Leander Schulz
-- Date:         07.09.2016
-- Last change:  07.09.2016
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY transmit_data_tb IS
END ENTITY transmit_data_tb;

ARCHITECTURE td_tb_arch OF transmit_data_tb IS

    -- component to test
    COMPONENT transmit_data IS
        GENERIC(baud_rate : IN NATURAL RANGE 1200 TO 115200);
        PORT( clk       : IN std_logic;
              rst       : IN std_logic;
              start_bit : IN std_logic;
              char_data : IN std_logic_vector (7 DOWNTO 0);
              out_tx    : OUT std_logic );
    END COMPONENT transmit_data;

    SIGNAL s_clk        : std_logic;
    SIGNAL s_baud_clk   : std_logic;
    SIGNAL s_rst        : std_logic := '1'; 
    SIGNAL s_start_bit  : std_logic := '0';
    SIGNAL s_char       : std_logic_vector (7 DOWNTO 0) := "10010110";
    SIGNAL s_tx         : std_logic;
    
BEGIN
    
    s_start_bit <= '1' AFTER 10000 ns, '0' AFTER 10020 ns, 
                   '1' AFTER 120000 ns, '0' AFTER 120020 ns;
    s_char <= "01010101" AFTER 100000 ns;
    
--- instances and clock signals    
    td_inst : transmit_data
    GENERIC MAP(baud_rate => 115200) 
    PORT MAP( clk       => s_clk,
              rst       => s_rst,   
              start_bit => s_start_bit,
              char_data => s_char,
              out_tx    => s_tx
    );
    
    p_clk : PROCESS BEGIN
        s_clk <= '0';
        WAIT FOR 10 ns;
        s_clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS p_clk;

END ARCHITECTURE td_tb_arch;
