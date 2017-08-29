----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Point Doubling IN K163
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 27.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- K163 elliptic curve point doubling package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE e_k163_point_doubling_package IS
  --CONSTANT M: natural := 8;
  CONSTANT M: natural := 9;
  --CONSTANT M: natural := 163;
  CONSTANT A: std_logic_vector(M-1 downto 0):= "000000001"; --for M=9 bits 
END e_k163_point_doubling_package;

------------------------------------------------------------
-- K163 elliptic curve point doubling
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_k163_point_doubling_package.all;

ENTITY e_k163_point_doubling IS
    PORT(
        -- Clock, reset, enable
        clk_i: IN std_logic; 
        rst_i: IN std_logic; 
        enable_i: IN std_logic;
        
        -- Input signals
        x1_i: IN std_logic_vector(M-1 DOWNTO 0);
        y1_i: IN std_logic_vector(M-1 DOWNTO 0); 
        
        -- Output signals
        x2_io: INOUT std_logic_vector(M-1 DOWNTO 0);
        y2_o: OUT std_logic_vector(M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_k163_point_doubling;

ARCHITECTURE rtl of e_k163_point_doubling IS
    -- Import entity e_gf2m_divider
    COMPONENT e_gf2m_divider_inv IS
        PORT(
            clk_i: IN std_logic;  
            rst_i: IN std_logic;  
            enable_i: IN std_logic; 
            g_i: IN std_logic_vector(M-1 DOWNTO 0);  
            h_i: IN std_logic_vector(M-1 DOWNTO 0); 
            z_o: OUT std_logic_vector(M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    end COMPONENT;
    
    -- Import entity e_gf2m_classic_squarer
    COMPONENT e_gf2m_classic_squarer IS
        PORT(
            a_i: IN std_logic_vector(M-1 DOWNTO 0);
            c_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    end COMPONENT;
    
    -- Import entity e_gf2m_interleaved_multiplier
    COMPONENT e_gf2m_interleaved_multiplier IS
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic; 
            a_i: IN std_logic_vector (M-1 DOWNTO 0); 
            b_i: IN std_logic_vector (M-1 DOWNTO 0);
            z_o: OUT std_logic_vector (M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    end COMPONENT;

    -- Temporary signals for divider and multiplier
    SIGNAL div_xy, mult_lx2, lambda, lambda_square, x1_square: std_logic_vector(M-1 DOWNTO 0);
    
    -- Signals to switch between multiplier and divider
    SIGNAL start_div, div_done, start_mult, mult_done: std_logic;
    
    -- Define all available states
    subtype states IS natural RANGE 0 TO 6;
    SIGNAL current_state: states;
BEGIN
    -- Instantiate divider entity
    --  Calculate div_xy = y1 / x1
    divider: e_gf2m_divider_inv PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => start_div,
        g_i => y1_i, 
        h_i => x1_i,  
        z_o => div_xy, 
        ready_o => div_done
    );

    -- Compute lambda 
    --  Calculate lambda = x1 + y1/x1
    multiplier_inputs: FOR i IN 0 TO M-1 GENERATE
        lambda(i) <= x1_i(i) xor div_xy(i);
    END GENERATE;
	
    -- Instantiate squarer 
    --  Calculate lambda^2 and x1^2
    lambda_square_computation: e_gf2m_classic_squarer PORT MAP( 
        a_i => lambda, 
        c_o => lambda_square
    );

    x1_square_computation: e_gf2m_classic_squarer PORT MAP( 
        a_i => x1_i, 
        c_o => x1_square
    );
    
    -- Compute x2_io 
    --  Calculate x2 = lambda^2 + lambda + a
    x2_output: FOR i IN 0 TO M-1 GENERATE
        x2_io(i) <= lambda_square(i) xor lambda(i) xor A(i);
    END GENERATE;
	
    -- Instantiate multiplier entity
    --  Calculate mult_lx2 = lambda * x2_io 
    multiplier: e_gf2m_interleaved_multiplier PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => start_mult, 
        a_i => lambda, 
        b_i => x2_io, 
        z_o => mult_lx2, 
        ready_o => mult_done
    );	
	
    -- Compute y2_o 
    --  Calculate y2 = x1^2 + lambda*x2 + x2
    y2_output: FOR i IN 0 TO M-1 GENERATE
        y2_o(i) <= x1_square(i) xor mult_lx2(i) xor x2_io(i);
    END GENERATE;	

    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2,3   : Calculate s = (py-qy)/(px-qx), s^2
        --  4,5,6 : Calculate rx/ry 
        CASE current_state IS
            WHEN 0 TO 1 => start_div <= '0'; start_mult <= '0'; ready_o <= '1';
            WHEN 2 		=> start_div <= '1'; start_mult <= '0'; ready_o <= '0';
            WHEN 3 		=> start_div <= '0'; start_mult <= '0'; ready_o <= '0';
            WHEN 4 		=> start_div <= '0'; start_mult <= '1'; ready_o <= '0';
            WHEN 5 TO 6 => start_div <= '0'; start_mult <= '0'; ready_o <= '0';
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
                    IF div_done = '1' THEN 
                        current_state <= 4; 
                    END IF;
                WHEN 4 => 
                    current_state <= 5;
                WHEN 5 => 
                    IF mult_done = '1' THEN 
                        current_state <= 6; 
                    END IF;
                WHEN 6 => 
                    current_state <= 0;
            END CASE;
        END IF;
    END PROCESS;
END rtl;