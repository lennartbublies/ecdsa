----------------------------------------------------------------------------------------------------
--  Entity - Randum Number Generator
--  Generate simple random number with UNIFORM function. This is not a cryptografic save function!
--  Do not use it in real applications. This is only for testing.  
--
--  Generic:
--   range_of_rand : Convert random number from 0..1 to real range like 0..1000
--
--  Ports:
<<<<<<< HEAD
--   rst_i    : global reset
--   clk_i    : clock signal
--   enable_i : enables or disables random number generation
--   rng_o    : random number as integer converet to needed range
=======
--   rst_i : global reset
--   clk_i : clock signal
--   en_i  : enables or disables random number generation
--   rng_o : random number as integer converet to needed range
>>>>>>> e51a984c8b2acc482aa5fc5fa96ec48f380a161c
--    
--  Autor: Lennart Bublies (inf100434)
--  Date: 14.06.2017
----------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.math_real.all;
USE ieee.std_logic_1164.ALL;
 
ENTITY e_rng IS
	GENERIC (
<<<<<<< HEAD
		-- The range of random values created.
		range_of_rand : real := 1000.0
	);
    PORT(
        -- Clock and reset signal
        rst_i : IN  std_logic;
        clk_i : IN  std_logic;
        
        -- Enable signal
        enable_i : IN std_logic;
        
        -- Integer output
=======
		-- the range of random values created.
		range_of_rand : real := 1000.0
	);
    PORT(
        -- clock and reset signal
        rst_i   : IN  std_logic;
        clk_i   : IN  std_logic;
        
        -- enable signal
        en_i : IN std_logic;
        
        -- integer output
>>>>>>> e51a984c8b2acc482aa5fc5fa96ec48f380a161c
        rng_o : OUT integer := 0
    );
END e_rng;
 
ARCHITECTURE rtl OF e_rng IS 
    SIGNAL random_number : integer := 0;
BEGIN
	-- Clock process
	clock : PROCESS(clk_i, rst_i)
        -- Seed values for random generator
        VARIABLE seed1, seed2: positive;
        -- Random real-number value in range 0 to 1.0
        VARIABLE rand: real;
    BEGIN        
<<<<<<< HEAD
        -- Reset entity on reset
        IF (rst_i = '1') THEN 
            random_number <= 0;
        ELSIF (clk_i='1' and clk_i'event and enable_i='1') THEN
            -- Eenerate random number
            uniform(seed1, seed2, rand);
            -- Rescale and convert integer 
            random_number <= integer(rand*range_of_rand);    
            --wait for 10 ns;
        END IF;
=======
      -- Reset entity on reset
      IF (rst_i = '1') THEN 
        random_number <= 0;
      ELSIF (clk_i='1' and clk_i'event and en_i='1') THEN
        -- Eenerate random number
        uniform(seed1, seed2, rand);
        -- Rescale and convert integer 
        random_number <= integer(rand*range_of_rand);    
        --wait for 10 ns;
      END IF;
>>>>>>> e51a984c8b2acc482aa5fc5fa96ec48f380a161c
    END PROCESS clock;
    
    -- Output process
    output : PROCESS(random_number)
    BEGIN
        rng_o <= random_number;
    END PROCESS output;
END rtl;