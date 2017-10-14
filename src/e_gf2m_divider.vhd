----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Binary polynomial divider
--  Computes the g/h mod f IN GF(2**m)
--
--  Ports:
--   clk_i    - Clock
--   rst_i    - Reset flag
--   enable_i - Enable computation
--   g_i      - First input value
--   h_i      - Seccond input value
--   z_o      - Output value
--   ready_o  - Ready flag after computation
--
--  Example:
--   1100101 / 1101 = 1001
--                 
--   BIT-SHIFT and XOR:        
--    1100101 / 1101 = 1001  
--    1101
--     0011
--     0000
--      0110
--      0000
--       1101
--       1101
--          0 Remainder
--
--  Based on:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/binary_algorithm_polynomials.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) binary polynomial divider
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_divider IS
    GENERIC (
        MODULO : std_logic_vector(M DOWNTO 0) := ONE
    );
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
END e_gf2m_divider;

ARCHITECTURE rtl of e_gf2m_divider IS
    -- Internal signals
    SIGNAL a : std_logic_vector(M DOWNTO 0);
    SIGNAL b, c, d, next_b, next_d: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL alpha, beta, next_beta, dec_input: std_logic_vector(logM-1 DOWNTO 0);
    SIGNAL ce_ac, ce_bd, load, beta_non_negative, alpha_gt_beta, b_zero: std_logic;
    
    -- Define all available states
    type states IS RANGE 0 TO 4;
    SIGNAL current_state: states;
BEGIN
    -- Load arguments for next computation
    registers_ac: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            -- First computation  (global arguments)
            IF load = '1' THEN 
                a <= MODULO; 
                c <= (OTHERS => '0');
            -- Seccond computation
            ELSIF ce_ac = '1' THEN 
                a <= '0'&b; 
                c <= d; 
            END IF;
        END IF;
    END PROCESS registers_ac;

    registers_bd: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            -- First computation (input arguments)
            IF load = '1' THEN 
                b <= h_i; 
                d <= g_i;
            -- Seccond computation
            ELSIF ce_bd = '1' THEN 
                b <= next_b; 
                d <= next_d;
            END IF;
        END IF;
    END PROCESS registers_bd;

    register_alpha: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            -- First computation (input arguments)
            IF load = '1' THEN 
                alpha <= conv_std_logic_vector(M, logM);
            -- Seccond computation
            ELSIF ce_ac = '1' THEN 
                alpha <= beta;
            END IF;
        END IF;
    END PROCESS register_alpha;
    
    register_beta: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            -- First computation (input arguments)
            IF load = '1' THEN 
                beta <= conv_std_logic_vector(M-1, logM);
            -- Seccond computation
            ELSIF ce_bd = '1' THEN 
                beta <= next_beta;
            END IF;
        END IF;
    END PROCESS register_beta;

    -- Shift and Add
    --  IF b(0)=0 THEN
    --      next_b(i) = b(i+1) 
    --  ELSIF b(0)=1 THEN 
    --      next_b(i) = b(i+1) + a(i+1)
    --  ENDIF
    first_iteration: FOR i IN 0 TO M-2 GENERATE
        next_b(i) <= (b(0) and (b(i+1) xor a(i+1))) or (not(b(0)) and b(i+1));
    END GENERATE;
    next_b(M-1) <= b(0) and a(M);

    -- Shift and Add
    --  IF b(0)=0 THEN
    --      next_d(i) = (MODULO(i+1)&next_d(M-1)) + d(i+1)              ????? (MODULO(i+1)&next_d(M-1)) ?????
    --  ELSIF b(0)=1 THEN 
    --      next_d(i) = (MODULO(i+1)&next_d(M-1)) + d(i+1) + c(i+1)     ????? (MODULO(i+1)&next_d(M-1)) ?????
    --  ENDIF
    second_iteration: FOR i IN 0 TO M-2 GENERATE
        next_d(i) <= (MODULO(i+1) and next_d(M-1)) xor ((b(0) and (d(i+1) xor c(i+1))) or (not(b(0)) and d(i+1)));
    END GENERATE;
    next_d(M-1) <= (b(0) and (d(0) xor c(0))) or (not(b(0)) and d(0));

    WITH ce_ac SELECT dec_input <= beta WHEN '0', alpha WHEN OTHERS;
    next_beta <= dec_input - 1;
    
    beta_non_negative <= '1' WHEN beta(logM-1) = '0' ELSE '0';
    alpha_gt_beta <= '1' WHEN alpha > beta ELSE '0';
    b_zero <= '1' WHEN b(0) = '0' ELSE '0';

    -- Set output
    z_o <= c;

    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state, beta_non_negative, alpha_gt_beta, b_zero)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2     : Load input arguments
        --  3,4   : Calculation...
        CASE current_state IS
            WHEN 0 TO 1 => 
                ce_ac <= '0'; ce_bd <='0'; load <= '0'; ready_o <= '1';
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
            WHEN 4 => 
                ce_ac <= '0'; ce_bd <='0'; load <= '0'; ready_o <= '0';
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
