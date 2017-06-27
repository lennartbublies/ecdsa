----------------------------------------------------------------------------------------------------
--  Testbench - Randum Number Generator 
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 14.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY tb_rng IS
END ENTITY tb_rng;

ARCHITECTURE testbench OF tb_rng IS
	-- Input signals:
	SIGNAL rst : std_logic := '0';
	SIGNAL clk : std_logic;
	SIGNAL enable : std_logic;

    -- Output signals:
    SIGNAL randum_number : integer := 0;

    -- Constants
    CONSTANT clk_period : time := 10 ns;

	-- Functions
	FUNCTION GEN_RN(r : integer) RETURN integer IS
	BEGIN
		-- Validate random number
		report "Randum number = " & integer'image(r);

		-- Check range
		IF (r >= 0 and r <= 1000) THEN
			return 1;
		ELSE
			return 0;
		END IF;
	END GEN_RN;
BEGIN
    -- Instantiate the unit under test
	rng: ENTITY work.e_rng
		PORT MAP(
			clk_i => clk,
			rst_i => rst,
			enable_i => enable,
			rng_o => randum_number
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
		ASSERT randum_number = 0 REPORT "Randum number should be zero after reset!";	
		WAIT FOR clk_period;

				-- Enable randum number generation
		enable <= '1';
		WAIT FOR clk_period;
		
        -- Generate random numbers and check range
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;
        ASSERT GEN_RN(randum_number) = 1 REPORT "Random number out of range!";
        WAIT FOR clk_period;

		WAIT FOR clk_period;
		enable <= '0';
   
		REPORT "Finish testbench TB_RNG";

		WAIT; -- will WAIT forever
	END PROCESS tb;
END ARCHITECTURE testbench;
