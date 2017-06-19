--------------------------------------------------------------------------------
-- Simple testbench FOR "classic_multiplier" module (FOR m=8)
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use work.classic_multiplier_parameters.all;

ENTITY tb_classic_gf2m_multiplication IS
END tb_classic_gf2m_multiplication;

ARCHITECTURE rtl OF tb_classic_gf2m_multiplication IS 
    -- Component Declaration FOR the Unit Under Test (UUT)
    COMPONENT e_classic_gf2m_multiplier
        PORT(
            a : IN std_logic_vector(m-1 downto 0);
            b : IN std_logic_vector(m-1 downto 0);
            c : OUT std_logic_vector(m-1 downto 0)
        );
    END COMPONENT;

    -- Inputs
    SIGNAL a :  std_logic_vector(m-1 downto 0) := (others=>'0');
    SIGNAL b :  std_logic_vector(m-1 downto 0) := (others=>'0');

    -- Outputs
    SIGNAL c :  std_logic_vector(m-1 downto 0);
BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: e_classic_gf2m_multiplier PORT MAP( 
            a => a, 
            b => b, 
            c => c 
        );

    tb : PROCESS
    BEGIN
        -- WAIT 100 ns FOR global reset to finish
        WAIT FOR 100 ns;
        a <= "10101010";
        b <= "10101010";
        
        WAIT FOR 100 ns;
        a <= "10101010";
        b <= "00000000";
        
        WAIT FOR 100 ns;
        a <= "11111111";
        b <= "10101010";
        
        WAIT FOR 100 ns;
        a <= "10101010";
        b <= "01010101";
        
        WAIT FOR 100 ns;
        a <= "01010101";
        b <= "01010101";
        
        WAIT FOR 100 ns;
        a <= "10000000";
        b <= "00000010";
        
        WAIT FOR 100 ns;
        a <= "01000000";
        b <= "00000100";
        
        WAIT FOR 100 ns;
        WAIT; -- will WAIT forever
    END PROCESS;
END;