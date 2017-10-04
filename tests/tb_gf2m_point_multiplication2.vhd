----------------------------------------------------------------------------------------------------
--  Testbench - gf2m Point Addition 
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 18.08.2017
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

ENTITY tb_gf2m_point_multiplication2 IS
END tb_gf2m_point_multiplication2;

ARCHITECTURE rtl OF tb_gf2m_point_multiplication2 IS 
    -- Import entity e_gf2m_doubleadd_point_multiplication
    COMPONENT e_gf2m_doubleadd_point_multiplication IS
        PORT (
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic;
            xp_i: IN std_logic_vector(M-1 DOWNTO 0); 
            yp_i: IN std_logic_vector(M-1 DOWNTO 0); 
            k: IN std_logic_vector(M-1 DOWNTO 0);
            xq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            yq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL xP, yP, xR, yR, k:  std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, done: std_logic := '0';
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  CONSTANT ONE: std_logic_vector(M-1 DOWNTO 0) := (0 => '1', OTHERS=>'0');
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 200 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET : time := 0 ns;
  CONSTANT NUMBER_TESTS: natural := 20;
BEGIN
    -- Instantiate first point multiplier entity
    uut1: e_gf2m_doubleadd_point_multiplication PORT MAP(
        clk_i => clk, 
        rst_i => rst, 
        enable_i => enable, 
        xp_i => xP, 
        yp_i => yP, 
        k => k,
        xq_io => xR, 
        yq_io => yR, 
        ready_o => done 
    );

    -- Clock process FOR clk
    PROCESS 
    BEGIN
        WAIT FOR OFFSET;
        CLOCK_LOOP : LOOP
            clk <= '0';
            WAIT FOR (PERIOD *(1.0 - DUTY_CYCLE));
            clk <= '1';
            WAIT FOR (PERIOD * DUTY_CYCLE);
        END LOOP CLOCK_LOOP;
    END PROCESS;

    -- Start test cases
    tb : PROCESS
    BEGIN
        -- Disable computation and reset all entities
        enable <= '0'; 
        rst <= '1';
        WAIT FOR PERIOD;
        rst <= '0';
        WAIT FOR PERIOD;
        
        -- Set point P for the computation
        --xP <= "000000010"; 
        --yP <= "000001111"; 
        --k  <= "000000010";

        --xP <= "011101110"; 
        --yP <= "010101111"; 
        --k  <= "001101001";
       
        xP  <= "011101110";
        yP  <= "010101111";
        k   <= "110100010";
        
        -- Start computation
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL (done = '1');
        
        WAIT FOR DELAY;

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!"
            SEVERITY FAILURE;
    END PROCESS;
END;