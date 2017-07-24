----------------------------------------------------------------------------------------------------
--  Testbench - GF(2^M) classic multiplication
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE work.p_gf2m_classic_multiplier_parameters.all;

ENTITY tb_classic_gf2m_multiplication IS
END tb_classic_gf2m_multiplication;

ARCHITECTURE rtl OF tb_classic_gf2m_multiplication IS 
    -- Import entity e_classic_gf2m_multiplier
    COMPONENT e_classic_gf2m_multiplier IS
        PORT(
            a: IN std_logic_vector(M-1 DOWNTO 0); 
            b: IN std_logic_vector(M-1 DOWNTO 0);
            c: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;

	-- Input signals:
	SIGNAL rst : std_logic := '0';
	SIGNAL clk : std_logic;
	SIGNAL enable : std_logic;
    SIGNAL ready : std_logic;
    SIGNAL a :  std_logic_vector(M-1 DOWNTO 0) := (others=>'0');
    SIGNAL b :  std_logic_vector(M-1 DOWNTO 0) := (others=>'0');

    -- Outputs
    SIGNAL c :  std_logic_vector(M-1 DOWNTO 0);
    
    -- Constants
    CONSTANT clk_period : time := 100 ns;
BEGIN
    -- Instantiate the unit under test
    uut: e_classic_gf2m_multiplier PORT MAP( 
            a => a, 
            b => b, 
            c => c 
        );

    -- Create clock signal
	clock: PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clk_period / 2;
		clk <= '1';
		WAIT FOR clk_period / 2;
	END PROCESS clock;

    -- Compute tests
    tb : PROCESS
    BEGIN
        -- WAIT 100 ns FOR global reset to finish
        --WAIT FOR clk_period;
        --a <= "10101010";
        --b <= "10101010";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
        
        --WAIT FOR clk_period;
        --a <= "10101010";
        --b <= "00000000";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
             
        --WAIT FOR clk_period;
        --a <= "11111111";
        --b <= "10101010";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
             
        --WAIT FOR clk_period;
        --a <= "10101010";
        --b <= "01010101";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
             
        --WAIT FOR clk_period;
        --a <= "01010101";
        --b <= "01010101";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
             
        --WAIT FOR clk_period;
        --a <= "10000000";
        --b <= "00000010";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
             
        --WAIT FOR clk_period;
        --a <= "01000000";
        --b <= "00000100";
        --ASSERT c = "00000000" REPORT "00000000 * 00000000 MOD f != 00000000";
             
        WAIT FOR clk_period;
        WAIT; -- will WAIT forever
    END PROCESS;
END;