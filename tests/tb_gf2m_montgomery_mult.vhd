--------------------------------------------------------------------------------
-- Simple testbench for "montgomery_mult" module (for m=8)
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use work.tld_ecdsa_package.all;

ENTITY tb_gf2m_montgomery_mult IS
END tb_gf2m_montgomery_mult;

ARCHITECTURE behavior OF tb_gf2m_montgomery_mult IS 
    -- Import entity e_gf2m_interleaved_multiplier
    COMPONENT e_gf2m_interleaved_multiplier is
        PORT (
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic; 
            a_i: IN std_logic_vector (M-1 DOWNTO 0); 
            b_i: IN std_logic_vector (M-1 DOWNTO 0);
            z_o: OUT std_logic_vector (M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;

    --Inputs
    SIGNAL a :  std_logic_vector(m-1 downto 0) := (others=>'0');
    SIGNAL b :  std_logic_vector(m-1 downto 0) := (others=>'0');
    SIGNAL clk, reset, start: std_logic;

    --Outputs
    SIGNAL z :  std_logic_vector(m-1 downto 0);
    SIGNAL done: std_logic;

    constant PERIOD : time := 200 ns;
    constant DUTY_CYCLE : real := 0.5;
    constant OFFSET : time := 0 ns;
BEGIN
    -- Instantiate montgomery multiplier
    uut: e_gf2m_interleaved_multiplier PORT MAP( 
        clk_i => clk, 
        rst_i => reset, 
        enable_i => start, 
        a_i => a, 
        b_i => b, 
        z_o => Z, 
        ready_o => done 
    );

    -- Clock process for clk
    PROCESS 
    BEGIN
        WAIT for OFFSET;
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
        reset <= '0';
        start <= '0';
        -- Wait 100 ns for global reset to finish
        wait for 100 ns;
        reset <= '1';
        a <= "10101010";
        b <= "10101010";
        wait for PERIOD;
        reset <= '0';
        wait for PERIOD;
        start <= '1';
        wait for PERIOD;
        start <= '0';
        WAIT until (done = '1'); WAIT FOR 2*PERIOD;

        a <= "10101010";
        b <= "00000000";
        start <= '1';
        wait for PERIOD;
        start <= '0';
        WAIT until (done = '1'); WAIT FOR 2*PERIOD;

        a <= "11111111";
        b <= "10101010";

        start <= '1';
        wait for PERIOD;
        start <= '0';
        WAIT until (done = '1'); WAIT FOR 2*PERIOD;

        a <= "10101010";
        b <= "01010101";
        start <= '1';
        wait for PERIOD;
        start <= '0';
        WAIT until (done = '1'); WAIT FOR 2*PERIOD;

        a <= "01010101";
        b <= "01010101";
        start <= '1';
        wait for PERIOD;
        start <= '0';
        WAIT until (done = '1'); WAIT FOR 2*PERIOD;

        ASSERT (FALSE) REPORT
            "Simulation finished (not a failure). No problems detected. "
            SEVERITY FAILURE;
    END PROCESS;
END;