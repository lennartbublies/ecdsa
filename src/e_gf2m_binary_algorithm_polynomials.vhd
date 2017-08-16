----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Binary algorithm polynomials
--  Computes the x/y mod f IN GF(2**m)
--
--  Ports:
-- 
--  Source:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/binary_algorithm_polynomials.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) binary algorithm polynomials package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE e_gf2m_binary_algorithm_polynomials_parameters IS
    -- Constants
    CONSTANT M: integer := 163;
    CONSTANT logM: integer := 9;--logM IS the number of bits of m plus an additional sign bit
    CONSTANT F: std_logic_vector(M DOWNTO 0):= x"800000000000000000000000000000000000000C9"; --FOR M=163
END e_gf2m_binary_algorithm_polynomials_parameters;

------------------------------------------------------------
-- GF(2^M) binary algorithm polynomials
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_gf2m_binary_algorithm_polynomials_parameters.all;

ENTITY e_gf2m_binary_algorithm_polynomials IS
    PORT(
        -- Clock, reset and enable
        clk_i: IN std_logic;  
        rst_i: IN std_logic;  
        enable_i: IN std_logic; 
        
        -- Input signals
        g_i: IN std_logic_vector(M-1 DOWNTO 0);  
        h_i: IN std_logic_vector(M-1 DOWNTO 0); 

        -- Output signals  
        z_o: OUT std_logic_vector(M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_gf2m_binary_algorithm_polynomials;

ARCHITECTURE rtl of e_gf2m_binary_algorithm_polynomials IS
    -- Internal signals
    SIGNAL a : std_logic_vector(M DOWNTO 0);
    SIGNAL b, c, d, next_b, next_d: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL alpha, beta, next_beta, dec_input: std_logic_vector(logM-1 DOWNTO 0);
    SIGNAL ce_ac, ce_bd, load, beta_non_negative, alpha_gt_beta, b_zero: std_logic;
    
    -- Define all available states
    type states IS RANGE 0 TO 4;
    SIGNAL current_state: states;
BEGIN
    first_iteration: FOR i IN 0 TO M-2 GENERATE
        next_b(i) <= (b(0) and (b(i+1) xor a(i+1))) or (not(b(0)) and b(i+1));
    END GENERATE;
    
    next_b(M-1) <= b(0) and a(M);
    next_d(M-1) <= (b(0) and (d(0) xor c(0))) or (not(b(0)) and d(0));
    
    second_iteration: FOR i IN 0 TO M-2 GENERATE
        next_d(i) <= (f(i+1) and next_d(M-1)) xor ((b(0) and (d(i+1) xor c(i+1))) or (not(b(0)) and d(i+1)));
    END GENERATE;

    registers_ac: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            IF load = '1' THEN 
                a <= f; 
                c <= (OTHERS => '0');
            ELSIF ce_ac = '1' THEN 
                a <= '0'&b; 
                c <= d; 
            END IF;
        END IF;
    END PROCESS registers_ac;

    registers_bd: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            IF load = '1' THEN 
                b <= h_i; 
                d <= g_i;
            ELSIF ce_bd = '1' THEN 
                b <= next_b; 
                d <= next_d;
            END IF;
        END IF;
    END PROCESS registers_bd;

    register_alpha: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            IF load = '1' THEN 
                alpha <= conv_std_logic_vector(M, logM);
            ELSIF ce_ac = '1' THEN 
                alpha <= beta;
            END IF;
        END IF;
    END PROCESS register_alpha;

    WITH ce_ac SELECT dec_input <= beta WHEN '0', alpha WHEN OTHERS;
    next_beta <= dec_input - 1;

    register_beta: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            IF load = '1' THEN 
                beta <= conv_std_logic_vector(M-1, logM);
            ELSIF ce_bd = '1' THEN 
                beta <= next_beta;
            END IF;
        END IF;
    END PROCESS register_beta;

    z_o <= c;

    beta_non_negative <= '1' WHEN beta(logM-1) = '0' ELSE '0';
    alpha_gt_beta <= '1' WHEN alpha > beta ELSE '0';
    b_zero <= '1' WHEN b(0) = '0' ELSE '0';

    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state, beta_non_negative, alpha_gt_beta, b_zero)
    BEGIN
        -- Handle current state
        CASE current_state IS
            WHEN 0 TO 1 => ce_ac <= '0'; ce_bd <='0'; load <= '0'; ready_o <= '1';
            WHEN 2 => 
                ce_ac <= '0'; ce_bd <= '0'; load <= '1'; ready_o <= '0';
            WHEN 3 => 
                IF beta_non_negative = '0' THEN 
                    ce_ac <= '0'; ce_bd <= '0'; 
                ELSIF b_zero = '1' THEN 
                    ce_ac <= '0'; ce_bd <= '1'; 
                ELSIF alpha_gt_beta = '1' THEN 
                    ce_ac <= '1'; ce_bd <= '1'; 
                ELSE 
                    ce_ac <= '0'; ce_bd <= '1'; 
                END IF;
                load <= '0'; ready_o <='0';
            WHEN 4 => ce_ac <= '0'; ce_bd <='0'; load <= '0'; ready_o <= '0';
        END CASE;

        IF rst_i = '1' THEN 
            -- Reset state if reset is high
            current_state <= 0;
        ELSIF clk_i'event and clk_i = '1' THEN
            -- Set next state
            CASE current_state IS
                WHEN 0 => 
                    IF enable_i = '0' THEN 
                        current_state <= 1; 
                    END IF;
                WHEN 1 => 
                    IF enable_i = '1' THEN 
                        current_state <= 2; 
                    END IF;
                WHEN 2 => 
                    current_state <= 3;
                WHEN 3 => 
                    IF beta_non_negative = '0' THEN 
                        current_state <= 4; 
                    END IF;
                WHEN 4 => 
                    current_state <= 0;
            END CASE;
        END IF;
    END PROCESS control_unit;
END rtl;
