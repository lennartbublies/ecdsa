----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Point Multiplication
--  Implementation with Double-And-Add algorithm
--
--  Ports:
--   clk_i    - Clock
--   rst_i    - Reset flag
--   enable_i - Enable computation
--   xp_i     - X part of input point
--   yp_i     - Y part of input point
--   k        - Multiplier k
--   xq_io    - X part of output point
--   yq_io    - Y part of output point
--   ready_o  - Ready flag
--
--  Algorithm:
--      ro = INFINITY
--      for (i=0; i>k-1; i++) {
--          ro = point_double(ro)
--          if k(i) == 1 {
--              ro = point_add(ro, p)
--          }
--      }
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

ENTITY e_gf2m_doubleadd_point_multiplication IS
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
        k: IN std_logic_vector(M-1 DOWNTO 0);
        
        xq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
        yq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_gf2m_doubleadd_point_multiplication;

ARCHITECTURE rtl of e_gf2m_doubleadd_point_multiplication IS
    -- Import entity e_k163_point_doubling 
    COMPONENT e_gf2m_point_doubling  IS
        GENERIC (
            MODULO : std_logic_vector(M DOWNTO 0)
        );
        PORT(
			clk_i: IN std_logic; 
			rst_i: IN std_logic; 
			enable_i: IN std_logic;
			x1_i: IN std_logic_vector(M-1 DOWNTO 0);
			y1_i: IN std_logic_vector(M-1 DOWNTO 0); 
			x2_io: INOUT std_logic_vector(M-1 DOWNTO 0);
			y2_o: OUT std_logic_vector(M-1 DOWNTO 0);
			ready_o: OUT std_logic
        );
    END COMPONENT;

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

    -- Internal signals
    SIGNAL start_doubling, doubling_done, start_addition, addition_done: std_logic;
    SIGNAL sel, ch_q, ch_a, ch_aa, q_infinity, a_equal_0, a_equal_1, load, k_ready: std_logic;
    SIGNAL next_xq, next_yq: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL x_double, y_double, x_doubleadd, y_doubleadd: std_logic_vector(M-1 DOWNTO 0);
	SIGNAL a, aa, next_a, next_aa: std_logic_vector(M DOWNTO 0); 
    SIGNAL kk: std_logic_vector(0 TO M-1); 
    
    -- Define all available states
    subtype states IS natural RANGE 0 TO 13;
    SIGNAL current_state: states;
BEGIN
    reverse_k: FOR i IN 0 TO M-1 GENERATE 
        kk(i) <= k(i);
    END GENERATE;
    
    -- Instantiate point doubling entity
    doubling: e_gf2m_point_doubling GENERIC MAP (
        MODULO => MODULO
    ) PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => start_doubling,  
            x1_i => xq_io, 
            y1_i => yq_io, 
            x2_io => x_double,   --> Result if k(i)=0
            y2_o => y_double,    --> Result if k(i)=0
            ready_o => doubling_done
        );

    -- Instantiate point addition entity
	addition: e_gf2m_point_addition GENERIC MAP (
        MODULO => MODULO
    ) PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => start_addition,  
            x1_i => x_double, 
            y1_i => y_double, 
            x2_i => xp_i,  
            y2_i => yp_i, 
            x3_io => x_doubleadd,   --> Result if k(i)=1
            y3_o => y_doubleadd,    --> Result if k(i)=1
            ready_o => addition_done
        );

    -- Select entity output from point addition or point doubling entity in dependence of k
    WITH sel SELECT next_yq <= y_double WHEN '0', y_doubleadd WHEN OTHERS;
    WITH sel SELECT next_xq <= x_double WHEN '0', x_doubleadd WHEN OTHERS;

    -- Output register
    register_q: PROCESS(clk_i)
    BEGIN
        IF clk_i' event and clk_i = '1' THEN 
            IF load = '1' THEN 
                xq_io <= (OTHERS=>'1');
                yq_io <= (OTHERS=>'1');
                q_infinity <= '1';
            ELSIF ch_q = '1' THEN 
                xq_io <= next_xq; 
                yq_io <= next_yq; 
                q_infinity <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- Register for k
    register_a: PROCESS(clk_i)
    BEGIN
        IF clk_i' event and clk_i = '1' THEN 
            IF load = '1' THEN 
                a  <= ('0'&kk); 
                aa <= ('0'&ONES); 
                k_ready <= '0';
            ELSIF ch_aa = '1' THEN 
                a  <= next_a; 
                aa <= next_aa; 
            ELSIF ch_a = '1' THEN 
                a  <= next_a; 
                aa <= next_aa; 
                k_ready <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- Shift k
    shift_a: FOR i IN 0 TO m-1 GENERATE 
        next_a(i) <= a(i+1);
        next_aa(i) <= aa(i+1);
    END GENERATE;
    next_a(m) <= a(m);
    next_aa(m) <= aa(m);
    
    -- If '1' enable point addition, otherwise only doubling
    a_equal_0  <= '1' WHEN a = 0 ELSE '0';
    a_equal_1  <= '1' WHEN a = 1 ELSE '0';
	
    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state, a_equal_0, a_equal_1, a(0), q_infinity)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2,3   : Intialize registers
        --  4,5   :
        CASE current_state IS
            WHEN 0 TO 1 => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '1';
            WHEN 2      => load <= '1'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 3      => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 4      => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '1'; start_addition <='0'; ready_o <= '0';
            WHEN 5      => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 6      => load <= '0'; sel <= '0'; ch_q <= '1'; ch_a <= '1'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 7      => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '1'; start_addition <='0'; ready_o <= '0';
            WHEN 8      => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 9      => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='1'; ready_o <= '0';
            WHEN 10     => load <= '0'; sel <= '1'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 11     => load <= '0'; sel <= '1'; ch_q <= '1'; ch_a <= '1'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 12     => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '0'; ch_aa <= '1'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
            WHEN 13     => load <= '0'; sel <= '0'; ch_q <= '0'; ch_a <= '1'; ch_aa <= '0'; start_doubling <= '0'; start_addition <='0'; ready_o <= '0';
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
                    -- Shift beginning zero bits (result of inversion of k)
                    IF (a(0) = '0') and (k_ready = '0') THEN
                        current_state <= 12;
                    ELSIF (a(0) = '1') and (k_ready = '0') THEN
                        current_state <= 13;
                    -- k is completely processed --> finish
                    ELSIF (a_equal_0 = '1') and (a = aa) THEN
                        current_state <= 0;
                    ELSIF a_equal_0 = '1' THEN
                        current_state <= 4;
                    ELSIF (a_equal_1 = '1') and (q_infinity = '1') THEN
                        current_state <= 0;
                    -- Double but skip addition
                    ELSIF a(0) = '0' THEN
                        current_state <= 4;
                    -- Double and add
                    ELSE
                        current_state <= 7;
                    END IF;
                -- Case: Only doubling
                WHEN 4 =>
                    current_state <= 5; --> Double
                WHEN 5 =>
                    IF doubling_done = '1' THEN
                        current_state <= 6;
                    END IF;
                WHEN 6 =>
                    current_state <= 3;
                -- Case: Double and add
                WHEN 7 =>
                    current_state <= 8; --> Double
                WHEN 8 =>
                    IF doubling_done = '1' THEN
                        current_state <= 9;
                    END IF;
                WHEN 9 =>
                    current_state <= 10; --> Add
                WHEN 10 =>
                    IF addition_done = '1' THEN
                        current_state <= 11;
                    END IF;
                WHEN 11 =>
                    current_state <= 3;
                WHEN 12 =>
                    current_state <= 3;
                WHEN 13 =>
                    current_state <= 3;
            END CASE;
        END IF;
    END PROCESS;
END rtl;