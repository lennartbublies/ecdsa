----------------------------------------------------------------------------------------------------
--  Testbench - PISO Register (Parallel In Serial Out)
--
--  This testbench is written for the use with production parameters. (M=163, U=8)
--
--  Autor: Lennart Bublies (inf100434), Leander Schulz (inf102143)
--  Date: 18.08.2017
--  Last Change: 16.10.2017 
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.math_real.all; -- FOR UNIFORM, TRUNC
USE std.textio.ALL;
USE work.tld_ecdsa_package.all;

ENTITY tb_nm_piso_register IS
END tb_nm_piso_register;

ARCHITECTURE rtl OF tb_nm_piso_register IS 
    -- Import entity e_piso_register 
    COMPONENT e_nm_piso_register  IS
        PORT(
            clk_i : IN std_logic;
            rst_i : IN std_logic;
            enable_i : IN std_logic;
            load_i : IN std_logic;
            data_i : IN std_logic_vector(M-1 DOWNTO 0);
            data_o : OUT std_logic_vector(U-1 DOWNTO 0)
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL data: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL piso: std_logic_vector(U-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, load: std_logic := '0';
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 20 ns;
  CONSTANT OFFSET : time := 0 ns;
  CONSTANT NUMBER_TESTS: natural := 20;
BEGIN
    -- Instantiate piso register entity
    piso_register: e_nm_piso_register PORT MAP(
        clk_i => clk, 
        rst_i => rst,
        enable_i => enable, 
        load_i => load,         
        data_i => data, 
        data_o => piso
    );

    -- Clock process FOR clk
    PROCESS 
    BEGIN
        WAIT FOR OFFSET;
        CLOCK_LOOP : LOOP
            clk <= '0';
            WAIT FOR PERIOD;
            clk <= '1';
            WAIT FOR PERIOD;
        END LOOP CLOCK_LOOP;
    END PROCESS;

    -- Start test cases
    tb : PROCESS IS 
        PROCEDURE p_ena (
            SIGNAL s_ena : INOUT  std_logic
        ) IS
        BEGIN
            s_ena <= '1';
            WAIT FOR PERIOD*2;
            s_ena <= '0'; 
            WAIT FOR PERIOD*8;
        END p_ena;  
    BEGIN
        -- Disable computation and reset all entities
        enable <= '0'; 
        rst <= '1';
        WAIT FOR PERIOD;
        rst <= '0';
        WAIT FOR PERIOD*4;

        data <= "100" & x"0B0A09080706050403020108A2E0CC0D99F8A5EF";
        load <= '1';
        WAIT FOR PERIOD;
        load <= '0';
        WAIT FOR PERIOD*4;
        
        FOR i IN 0 TO 22 LOOP
            p_ena(enable);
        END LOOP;
        
        
        WAIT FOR DELAY;
        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;