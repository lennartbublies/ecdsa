----------------------------------------------------------------------------------------------------
--  Testbench - ECDSA
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 14.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_textio.ALL;
use ieee.math_real.all; -- FOR UNIFORM, TRUNC
USE std.textio.ALL;

use work.tld_k163_ecdsa_package.all;

ENTITY tb_k163_ecdsa IS
END tb_k163_ecdsa;

ARCHITECTURE rtl OF tb_k163_ecdsa IS 
    -- Import entity tld_ecdsa
    COMPONENT tld_ecdsa IS
        PORT (
            clk_i: IN std_logic; 
            rst_i: IN std_logic;
            enable_i: IN std_logic;
            mode_i: IN std_logic;
            hash_i: IN std_logic_vector(M-1 DOWNTO 0);
            r_i: IN std_logic_vector(M-1 DOWNTO 0);
            s_i: IN std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic;
            valid_o: OUT std_logic;
            sign_r_o: OUT std_logic_vector(M-1 DOWNTO 0);
            sign_s_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;

    -- Internal signals
    SIGNAL ri, si, ro, so:  std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL clk, rst, enable, mode, done, valid, enable_keys_i: std_logic := '0';
    SIGNAL hash: std_logic_vector (M-1 DOWNTO 0) ;
    CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    CONSTANT ONE: std_logic_vector(M-1 DOWNTO 0) := (0 => '1', OTHERS=>'0');
    CONSTANT DELAY : time := 100 ns;
    CONSTANT PERIOD : time := 200 ns;
    CONSTANT DUTY_CYCLE : real := 0.5;
    CONSTANT OFFSET : time := 0 ns;
    CONSTANT NUMBER_TESTS: natural := 1;
BEGIN
    -- Instantiate ecdsa entity
    uut1: tld_ecdsa PORT MAP(
        clk_i => clk, 
        rst_i => rst,
        enable_i => enable, 
        mode_i => mode, 
        hash_i => hash,
        r_i => ri,
        s_i => si, 
        ready_o => done, 
        valid_o => valid,
        sign_r_o => ri,
        sign_s_o => si 
    );

    -- clock process FOR clk
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

    tb : PROCESS 
        -- Procedure to generate random value for k
        PROCEDURE gen_random(X : out std_logic_vector (M-1 DOWNTO 0); w: natural; s1, s2: inout Natural) IS
            VARIABLE i_x, aux: integer;
            VARIABLE rand: real;
        BEGIN
            aux := w/16;
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
            -- Generate random input for k
            gen_random(xx, M, seed1, seed2);
            WHILE (xx = ZERO) LOOP 
                gen_random(xx, M, seed1, seed2); 
            END LOOP;
            hash <= xx;
            
            -- Start test 1:
            -- Count runtime
            enable <= '1'; 
            initial_time := now;
            WAIT FOR PERIOD;
            enable <= '0';
            WAIT UNTIL (done = '1');
            final_time := now;
            cycles := (final_time - initial_time)/PERIOD;
            total_cycles := total_cycles+cycles;
            ASSERT (FALSE) REPORT "Number of Cycles: " & integer'image(cycles) & "  TotalCycles: " 
              & integer'image(total_cycles) SEVERITY WARNING;
            IF cycles > max_cycles THEN  
                max_cycles:= cycles; 
            END IF;
            IF cycles < min_cycles THEN  
                min_cycles:= cycles; 
            END IF;

            -- Start test 2:
            -- Sign and verify
            WAIT FOR 2*PERIOD;
            enable <= '1';
            mode <= '0';
            WAIT FOR PERIOD;
            enable <= '0';
            WAIT UNTIL done = '1';

            WAIT FOR 2*PERIOD;

            WAIT FOR PERIOD;
            enable <= '1';
            mode <= '1';
            WAIT FOR PERIOD;
            enable <= '0';
            WAIT UNTIL done = '1';

            WAIT FOR 2*PERIOD;

            IF ( valid = '0' ) THEN 
                write(TX_LOC,string'("ERROR!!! Signature invalid"));
                write(TX_LOC, string'(" )"));
                TX_STR(TX_LOC.all'range) := TX_LOC.all;
                Deallocate(TX_LOC);
                ASSERT (FALSE) REPORT TX_STR SEVERITY ERROR;
            END IF;  
        END LOOP; 

        WAIT FOR DELAY;

        -- C RESULTS - VALUES MAY BE SWAPPED!

        -- ################## SIGNATURE TEMP ###: 
        -- # k = 
        --     03355BF83C497F922FFAEC53C7315B348FAFB4DA2F
        -- # kP = 
        -- x = 01F8BBFA559093A29A1E240D0BDA21FA344FBBE354
        -- y = 001AF7EE247897E8577EDF70A9AD5F7E640D6C7E19
        -- # r =  (kPx)
        --     01F8BBFA559093A29A1E240D0BDA21FA344FBBE354
        -- # e + d * kPx  = 
        --     0ED2A52CECC3D4987E33F26CD53E4DBB4547C50DF7
        -- # s =  ((e + d * kPx)/k)
        --     03FB3BC46A33F716453F811C26A3F5F5085ABBDE3E
        -- ################## SIGNATURE TEMP ###: 

        -- ################## VERIFIY TEMP ###: 
        -- # w = 
        --     0169D552F6E38168C9BF8803BEB247E02738FE1E84
        -- # u_1 = 
        --     04097C817506A38353AB34C4E30967E9E7D0726F4C
        -- # u_2 = 
        --     07D4ECE872FAECB4205540710DB317AEB9784CCC8E
        -- # x_1 =  (u_1 * P)
        -- x = 016815438D3CDFE16E4D45561A65CD517120D19B12
        -- y = 01E2913A037972B64A5425C26327F6E954B2972CEF
        -- # x_2 =  (u_2 * Q)
        -- x = 00CF503AE721EA9E91CBA9B83C3550C8E691C10BB7
        -- y = 05F26A2407ACBBD2505D40D1D00808BF94BEC04484
        -- # x =  (u_1 * P + u_2 * Q)
        -- x = 03BA0D75DDF7C306071564E6C65868620422FCBEA6
        -- y = 07948DDD26282759A6D4393A984B94738E52FCE86C
        -- ################## VERIFIY TEMP END ###: 

        avg_cycles := real(total_cycles)/real(NUMBER_TESTS);

        -- Report results
        ASSERT (FALSE) REPORT
            "Simulation successful!.  MinCycles: " & integer'image(min_cycles) &
            "  MaxCycles: " & integer'image(max_cycles) & "  TotalCycles: " & integer'image(total_cycles) &
            "  AvgCycles: " & real'image(avg_cycles)
            SEVERITY FAILURE;
    END PROCESS;
END;
