----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Polynom Division with Inversio+Multiplication
--  Computes the x/y mod f IN GF(2**m)
--
--  Ports:
-- 
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) divider with inversion package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE e_gf2m_divider_inv_parameters IS
    -- Constants
    --CONSTANT M: integer := 8;
    CONSTANT M: integer := 9;
    --CONSTANT M: integer := 163;
END e_gf2m_divider_inv_parameters;

------------------------------------------------------------
-- GF(2^M) divider with inversion
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_gf2m_divider_inv_parameters.all;

ENTITY e_gf2m_divider_inv IS
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
END e_gf2m_divider_inv;

ARCHITECTURE rtl of e_gf2m_divider_inv IS
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

    -- Import entity e_gf2m_eea_inversion
    COMPONENT e_gf2m_eea_inversion IS
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic; 
            enable_i: IN std_logic; 
            a_i: IN std_logic_vector (M-1 DOWNTO 0);
            z_o: OUT std_logic_vector (M-1 DOWNTO 0);
            ready_o: OUT std_logic
        );
    end COMPONENT;
    
    SIGNAL invh: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL enable_inversion, done_inversion, enable_multiplication, done_multiplication: std_logic;

    -- Define all available states
    subtype states IS natural RANGE 0 TO 6;
    SIGNAL current_state: states;
BEGIN
    -- Instantiate inversion entity to compute h^-1
    inversion: e_gf2m_eea_inversion PORT MAP (
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_inversion,
        a_i => h_i,
        z_o => invh,
        ready_o => done_inversion
    );

    -- Instantiate multiplier entity to g * h^-1
    multiplier: e_gf2m_interleaved_multiplier PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_multiplication, 
        a_i => g_i,
        b_i => invh,
        z_o => z_o,
        ready_o => done_multiplication
    );
    
    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2,3   : Calculate inversion
        --  4,5   : Calculate multiplication
        CASE current_state IS
            WHEN 0 TO 1 => enable_inversion <='0'; enable_multiplication <= '0'; ready_o <= '1';
            WHEN 2      => enable_inversion <='1'; enable_multiplication <= '0'; ready_o <= '0';
            WHEN 3      => enable_inversion <='0'; enable_multiplication <= '0'; ready_o <= '0';
            WHEN 4      => enable_inversion <='0'; enable_multiplication <= '1'; ready_o <= '0';
            WHEN 5 TO 6 => enable_inversion <='0'; enable_multiplication <= '0'; ready_o <= '0';
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
                    IF done_inversion = '1' THEN 
                        current_state <= 4; 
                    END IF;
                WHEN 4 =>
                    current_state <= 5;
                WHEN 5 =>
                    IF done_multiplication = '1' THEN 
                        current_state <= 6; 
                    END IF;
                WHEN 6 =>
                    current_state <= 0; 
            END CASE;
        END IF;
    END PROCESS control_unit;
END rtl;
