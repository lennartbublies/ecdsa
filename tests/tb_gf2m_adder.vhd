----------------------------------------------------------------------------------------------------
--  Testbench - GF(2^M) adder
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 21.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.p_gf2m_adder_parameters.all;

ENTITY tb_gf2m_adder IS
END ENTITY tb_gf2m_adder;

ARCHITECTURE testbench OF tb_gf2m_adder IS
	-- Input signals:
	SIGNAL rst : std_logic := '0';
	SIGNAL clk : std_logic;
	SIGNAL enable : std_logic;
    SIGNAL ready : std_logic;
    SIGNAL a : std_logic_vector(M-1 DOWNTO 0); 
    SIGNAL b : std_logic_vector(M-1 DOWNTO 0);

    -- Output signals:
    SIGNAL c : std_logic_vector(M-1 DOWNTO 0);
    
    -- Constants
    CONSTANT clk_period : time := 10 ns;
BEGIN
    -- Instantiate the unit under test
	adder: ENTITY work.e_gf2m_adder
		PORT MAP(
			clk_i => clk,
			rst_i => rst,
			enable_i => enable,
            a_i => a,
            b_i => b,
			ready_o => ready,
            c_o => c
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
	tb: PROCESS
	BEGIN
		WAIT FOR clk_period * 2;

		-- Reset the module
		rst <= '1';
		WAIT FOR clk_period;
		rst <= '0';
		WAIT FOR clk_period;

		-- The module should now be ready for work
		ASSERT c = "00000000" REPORT "Sum should be zero after reset!";	
		WAIT FOR clk_period;

        -- Enable entity
		enable <= '1';
		WAIT FOR clk_period;
        
        a <= "00000000";
        b <= "11111111";
		WAIT FOR clk_period;
        ASSERT c = "11111111" REPORT "00000000 + 11111111 != 11111111";
		WAIT FOR clk_period;

        a <= "10101010";
        b <= "01010101";
		WAIT FOR clk_period;
        ASSERT c = "11111111" REPORT "10101010 + 01010101 != 11111111";
		WAIT FOR clk_period;

        a <= "00001100";
        b <= "11000000";
		WAIT FOR clk_period;
        ASSERT c = "11001100" REPORT "00001100 + 11000000 != 11001100";
		WAIT FOR clk_period;

        a <= "00000000";
        b <= "00000000";
		WAIT FOR clk_period;
        ASSERT c = "00000000" REPORT "00000000 + 00000000 != 00000000";
		WAIT FOR clk_period;

        a <= "11111111";
        b <= "11111111";
		WAIT FOR clk_period;
        ASSERT c = "00000000" REPORT "11111111 + 11111111 != 00000000";
		WAIT FOR clk_period;

		WAIT FOR clk_period;
		enable <= '0';
   
		REPORT "Finish testbench TB_GF2M_ADDER";

		WAIT; -- will WAIT forever
	END PROCESS tb;
END ARCHITECTURE testbench;
