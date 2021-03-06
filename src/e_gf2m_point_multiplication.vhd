----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Point Multiplication
--
--  Ports:
--   clk_i    - Clock
--   rst_i    - Reset flag
--   enable_i - Enable computation
--   xp_i     - X part of input point
--   yp_i     - Y part of input point
--   k_i      - Multiplier k
--   xq_io    - X part of output point
--   yq_io    - Y part of output point
--   ready_o  - Ready flag
--
--  Based on:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/K163_point_multiplication.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) point multiplication
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.tld_ecdsa_package.all;

ENTITY e_gf2m_point_multiplication IS
    GENERIC (
        MODULO : std_logic_vector(M DOWNTO 0) := ONE
    );
    PORT (
        -- Clock, reset, enable
        clk_i: IN std_logic; 
        rst_i: IN std_logic; 
        enable_i: IN std_logic;
        
        xp_i: IN std_logic_vector(M-1 DOWNTO 0); 
        yp_i: IN std_logic_vector(M-1 DOWNTO 0); 
        k_i: IN std_logic_vector(M-1 DOWNTO 0);
        
        xq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
        yq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_gf2m_point_multiplication;

ARCHITECTURE rtl of e_gf2m_point_multiplication IS
    -- Import entity e_gf2m_point_addition
    COMPONENT e_gf2m_point_addition IS
        GENERIC (
            MODULO : std_logic_vector(M DOWNTO 0)
        );
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
    
    -- Import entity e_gf2m_classic_squarer
    COMPONENT e_gf2m_classic_squarer IS
        GENERIC (
            MODULO : std_logic_vector(M-1 DOWNTO 0)
        );
        PORT(
            a_i: IN std_logic_vector(M-1 DOWNTO 0);
            c_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Internal signals
    SIGNAL a, next_a, a_div_2: std_logic_vector(m DOWNTO 0);
    SIGNAL b, next_b: std_logic_vector(m-1 DOWNTO 0);
    SIGNAL xxP, yyP, next_xQ, next_yQ, xxPxoryyP, square_xxP, square_yyP, y1, x3, y3: std_logic_vector(m-1 DOWNTO 0);

    SIGNAL ce_P, ce_Q, ce_ab, load, sel_1, start_addition, addition_done, carry, Q_infinity, aEqual0, bEqual0, a1xorb0: std_logic;

    SIGNAL sel_2: std_logic_vector(1 DOWNTO 0);

    -- Define all available states
    subtype states IS natural RANGE 0 TO 12;
    SIGNAL current_state: states;
BEGIN
    -- Instantiate point addition entity
    --  Calculate (x3, y3) = (xxp, y1) + (xq, yq)
    first_component: e_gf2m_point_addition GENERIC MAP (
            MODULO => MODULO
        ) PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => start_addition,  
            x1_i => xxP, 
            y1_i => y1, 
            x2_i => xq_io,  
            y2_i => yq_io, 
            x3_io => x3, 
            y3_o => y3, 
            ready_o => addition_done
        );

    -- Instantiate squarer entity for x part
    --  Calculate xxp^2
    x_squarer: e_gf2m_classic_squarer GENERIC MAP (
            MODULO => MODULO(M-1 DOWNTO 0)
        ) PORT MAP( 
            a_i => xxP, 
            c_o => square_xxP
        );

    -- Instantiate squarer entity for y part    
    --  Calculate yyp^2
    y_squarer: e_gf2m_classic_squarer GENERIC MAP (
            MODULO => MODULO(M-1 DOWNTO 0)
        ) PORT MAP( 
            a_i => yyP, 
            c_o => square_yyP
        );

    -- Calculate xxp XOR yyp
    xor_gates: FOR i IN 0 TO m-1 GENERATE 
        xxPxoryyP(i) <= xxP(i) xor yyP(i); 
    END GENERATE;

    WITH sel_1 SELECT y1 <= yyP WHEN '0', xxPxoryyP WHEN OTHERS;
    WITH sel_2 SELECT next_yQ <= y3 WHEN "00", yyP WHEN "01", xxPxoryyP WHEN OTHERS;
    WITH sel_2 SELECT next_xQ <= x3 WHEN "00", xxP WHEN OTHERS;

    register_P: PROCESS(clk_i)
    BEGIN
        IF clk_i' event and clk_i = '1' THEN 
            IF load = '1' THEN 
                xxP <= xp_i; 
                yyP <= yp_i;
            ELSIF ce_P = '1' THEN 
                xxP <= square_xxP; 
                yyP <= square_yyP; 
            END IF;
        END IF;
    END PROCESS;

    register_Q: PROCESS(clk_i)
    BEGIN
        IF clk_i' event and clk_i = '1' THEN 
            IF load = '1' THEN 
                Q_infinity <= '1';
            ELSIF ce_Q = '1' THEN 
                xq_io <= next_xQ; 
                yq_io <= next_yQ; 
                Q_infinity <= '0'; 
            END IF;
        END IF;
    END PROCESS;

    divide_by_2: FOR i IN 0 TO m-1 GENERATE 
        a_div_2(i) <= a(i+1);
    END GENERATE;
    a_div_2(m) <= a(m);
    
    next_a <= (b(m-1)&b) + a_div_2 + carry;
    next_b <= zero - (a_div_2(m-1 DOWNTO 0) + carry);

    register_ab: PROCESS(clk_i)
    BEGIN
        IF clk_i' event and clk_i = '1' THEN 
            IF load = '1' THEN 
                a <= ('0'&k_i); 
                b <= zero;
            ELSIF ce_ab = '1' THEN 
                a <= next_a; 
                b <= next_b; 
            END IF;
        END IF;
    END PROCESS;

    aEqual0 <= '1' WHEN a = 0 ELSE '0';
    bEqual0 <= '1' WHEN b = 0 ELSE '0';
    a1xorb0 <= a(1) xor b(0);

    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state, addition_done, aEqual0, bEqual0, a(0), a1xorb0, Q_infinity)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2,3   : Load k, xp, yp, ...
        --  4,5   : Square xxp, yyp, ...
        --  6,7   :
        --
        CASE current_state IS
            WHEN 0 TO 1 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready_o <= '1';
            WHEN 2 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '1'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready_o <= '0';
            WHEN 3 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready_o <= '0';
            WHEN 4 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '1'; ce_Q <= '0'; ce_ab <= '1'; start_addition <= '0'; ready_o <= '0';
            WHEN 5 => sel_1 <= '0'; sel_2 <= "01"; carry <= '0'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready_o <= '0';
            WHEN 6 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '1'; ready_o <= '0';
            WHEN 7 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready_o <= '0';
            WHEN 8 => sel_1 <= '0'; sel_2 <= "00"; carry <= '0'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready_o <= '0';
            WHEN 9 => sel_1 <= '1'; sel_2 <= "10"; carry <= '1'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready_o <= '0';
            WHEN 10 => sel_1 <= '1'; sel_2 <= "00"; carry <= '1'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '1'; ready_o <= '0';
            WHEN 11 => sel_1 <= '1'; sel_2 <= "00"; carry <= '1'; load <= '0'; ce_P <= '0'; ce_Q <= '0'; ce_ab <= '0'; start_addition <= '0'; ready_o <= '0';
            WHEN 12 => sel_1 <= '1'; sel_2 <= "00"; carry <= '1'; load <= '0'; ce_P <= '1'; ce_Q <= '1'; ce_ab <= '1'; start_addition <= '0'; ready_o <= '0';
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
                    IF (aEqual0 = '1') and (bEqual0 = '1') THEN 
                        current_state <= 0;
                    ELSIF a(0) = '0' THEN 
                        current_state <= 4;
                    ELSIF (a1xorb0 = '0') and (Q_infinity = '1') THEN 
                        current_state <= 5;
                    ELSIF (a1xorb0 = '0') and (Q_infinity = '0') THEN 
                        current_state <= 6;
                    ELSIF (a1xorb0 = '1') and (Q_infinity = '1') THEN 
                        current_state <= 9;
                    ELSE 
                        current_state <= 10;
                    END IF;
                WHEN 4 => 
                    current_state <= 3;
                WHEN 5 => 
                    current_state <= 3;
                WHEN 6 => 
                    current_state <= 7;
                WHEN 7 => 
                    IF addition_done = '1' THEN 
                        current_state <= 8; 
                    END IF;
                WHEN 8 => 
                    current_state <= 3;
                WHEN 9 => 
                    current_state <= 3;
                WHEN 10 => 
                    current_state <= 11;
                WHEN 11 => 
                    IF addition_done = '1' THEN 
                        current_state <= 12; 
                    END IF;
                WHEN 12 => 
                    current_state <= 3;
            END CASE;
        END IF;
    END PROCESS;
END rtl;
