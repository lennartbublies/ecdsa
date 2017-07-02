--------------------------------------------------------------------------------
-- Test_Simple_K163_point_multiplication 
-- VHDL Test Bench FOR module: K163_point_multiplication.vhd 
--  
--
-- Executes NUMBER_TESTS operations with random values of K. 
-- Test k.P = (k-1).P + P, FOR a fixed known P.
--
-- Finally k = n-1, being N= order of point P and test:
-- k.P = (n-1).P = -P = (xP, xP+yP)
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
use ieee.math_real.all; -- FOR UNIFORM, TRUNC
USE std.textio.ALL;

use work.e_k163_point_multiplication_package.all;

ENTITY tb_k163_point_multupliation_and_addition IS
END tb_k163_point_multupliation_and_addition;

ARCHITECTURE behavior OF tb_k163_point_multupliation_and_addition IS 
    -- Import entity e_k163_point_multiplication
    COMPONENT e_k163_point_multiplication IS
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

    -- Import entity e_k163_point_addition
    COMPONENT e_k163_point_addition IS
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic;
            x1_i: IN std_logic_vector(M-1 DOWNTO 0);
            y1_i: IN std_logic_vector(M-1 DOWNTO 0); 
            x2_i: IN std_logic_vector(M-1 DOWNTO 0); 
            y2_i: IN std_logic_vector(M-1 DOWNTO 0);
            x3_io: INOUT std_logic_vector(M-1 DOWNTO 0);
            y3_o: OUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    END COMPONENT;

  -- Internal signals
  SIGNAL xP, yP, k, k_minus_1, xQ1, yQ1, xQ2, yQ2, xQ3, yQ3, xP_plus_yP:  std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL clk, rst, enable, start_add, ready, done_2, done_add: std_logic := '0';
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
  CONSTANT ONE: std_logic_vector(M-1 DOWNTO 0) := (0 => '1', OTHERS=>'0');
  CONSTANT DELAY : time := 100 ns;
  CONSTANT PERIOD : time := 200 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET : time := 0 ns;
  CONSTANT NUMBER_TESTS: natural := 20;
  CONSTANT P_order : std_logic_vector(M-1 DOWNTO 0) := "100" & x"000000000000000000020108a2e0cc0d99f8a5ee";
BEGIN
    -- Instantiate first point multiplier entity
    uut1: e_k163_point_multiplication PORT MAP(
        clk_i => clk, 
        rst_i => rst, 
        enable_i => enable, 
        xp_i => xP, 
        yp_i => yP, 
        k => k,
        xq_io => xQ1, 
        yq_io => yQ1, 
        ready_o => ready 
    );

    -- Instantiate seccond point multiplier entity
    uut2: e_k163_point_multiplication PORT MAP(
        clk_i => clk, 
        rst_i => rst, 
        enable_i => enable, 
        xp_i => xP, 
        yp_i => yP, 
        k => k,
        xq_io => xQ1, 
        yq_io => yQ1, 
        ready_o => ready 
    );

    -- Instantiate point addition entity
    uut3: e_k163_point_addition port map( 
        clk_i => clk, 
        rst_i => rst, 
        enable_i => start_add,
        x1_i => xP, 
        y1_i => yP, 
        x2_i => xQ2, 
        y2_i => yQ2,
        x3_io => xQ3, 
        y3_o => yQ3,
        ready_o => done_add
    );

    k_minus_1 <= k - '1';
    xP <= "010" & x"fe13c0537bbc11acaa07d793de4e6d5e5c94eee8";
    yP <= "010" & x"89070fb05d38ff58321f2e800536d538ccdaa3d9";
    xP_plus_yP <= xP xor yP;

    PROCESS -- clock process FOR clk
    BEGIN
        WAIT FOR OFFSET;
        CLOCK_LOOP : LOOP
            clk <= '0';
            WAIT FOR (PERIOD *(1.0 - DUTY_CYCLE));
            clk <= '1';
            WAIT FOR (PERIOD * DUTY_CYCLE);
        END LOOP CLOCK_LOOP;
    END PROCESS;

    tb_proc : PROCESS --generate values
        PROCEDURE gen_random(X : out std_logic_vector (M-1 DOWNTO 0); w: natural; s1, s2: inout Natural) IS
            VARIABLE i_x, aux: integer;
            VARIABLE rand: real;
        BEGIN
            aux := W/16;
            FOR i IN 1 TO aux LOOP
                UNIFORM(s1, s2, rand);
                i_x := INTEGER(TRUNC(rand * real(65536)));-- real(2**16)));
                x(i*16-1 DOWNTO (i-1)*16) := CONV_STD_LOGIC_VECTOR (i_x, 16);
            END LOOP;
            UNIFORM(s1, s2, rand);
            i_x := INTEGER(TRUNC(rand * real(2**(w-aux*16))));
            x(w-1 DOWNTO aux*16) := CONV_STD_LOGIC_VECTOR (i_x, (w-aux*16));
        END PROCEDURE;
        
        -- Internal signals
        VARIABLE TX_LOC : LINE;
        VARIABLE TX_STR : String(1 TO 4096);
        VARIABLE seed1, seed2: positive; 
        VARIABLE i_x, i_y, i_p, i_z, i_yz_modp: integer;
        VARIABLE cycles, max_cycles, min_cycles, total_cycles: integer := 0;
        VARIABLE avg_cycles: real;
        VARIABLE initial_time, final_time: time;
        VARIABLE xx: std_logic_vector (M-1 DOWNTO 0) ;
    BEGIN
        min_cycles:= 2**20;
        
        -- Disable computation and reset all entities
        enable <= '0'; 
        rst <= '1';
        WAIT FOR PERIOD;
        rst <= '0';
        WAIT FOR PERIOD;
        
        -- Loop over all test cases
        FOR I IN 1 TO NUMBER_TESTS LOOP
            -- Generate random input
            gen_random(xx, M, seed1, seed2);
            WHILE (xx >= P_order) LOOP 
                gen_random(xx, M, seed1, seed2); 
            END LOOP;
            
            -- Start test 1:
            k <= xx;
            enable <= '1'; 
            initial_time := now;
            WAIT FOR PERIOD;
            enable <= '0';
            WAIT UNTIL (ready = '1') and (done_2 = '1');
            final_time := now;
            cycles := (final_time - initial_time)/PERIOD;
            total_cycles := total_cycles+cycles;
            --ASSERT (FALSE) REPORT "Number of Cycles: " & integer'image(cycles) & "  TotalCycles: " & integer'image(total_cycles) SEVERITY WARNING;
            IF cycles > max_cycles THEN  
                max_cycles:= cycles; 
            END IF;
            IF cycles < min_cycles THEN  
                min_cycles:= cycles; 
            END IF;

            -- Start test 2:
            WAIT FOR PERIOD;
            start_add <= '1';
            WAIT FOR PERIOD;
            start_add <= '0';
            WAIT UNTIL done_add = '1';

            WAIT FOR 2*PERIOD;

            IF ( xQ1 /= xQ3 or (yQ1 /= yQ3) ) THEN 
                write(TX_LOC,string'("ERROR!!! k.P /= (k-1)*P + P; k = ")); write(TX_LOC, k);
                write(TX_LOC, string'(" )"));
                TX_STR(TX_LOC.all'range) := TX_LOC.all;
                Deallocate(TX_LOC);
                ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
            END IF;  
        END LOOP;

        WAIT FOR DELAY;
     
        -- Start test 3:
        k <= P_order;
        enable <= '1'; 
        WAIT FOR PERIOD;
        enable <= '0';
        WAIT UNTIL ready = '1';
        IF ( xQ1 /= xP or (yQ1 /= xP_plus_yP) ) THEN 
            write(TX_LOC,string'("ERROR!!! k.P = (n-1).P = -P = (xP, xP+yP) with n order of P")); write(TX_LOC, k);
            write(TX_LOC, string'(" )"));
            TX_STR(TX_LOC.all'range) := TX_LOC.all;
            Deallocate(TX_LOC);
            ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
        END IF;  
        WAIT FOR 10*PERIOD;
        
        avg_cycles := real(total_cycles)/real(NUMBER_TESTS);

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!.  MinCycles: " & integer'image(min_cycles) &
            "  MaxCycles: " & integer'image(max_cycles) & "  TotalCycles: " & integer'image(total_cycles) &
            "  AvgCycles: " & real'image(avg_cycles)
            SEVERITY FAILURE;
    END PROCESS;
END;