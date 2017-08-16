----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Interleaved Multiplier
--  Computes the polynomial multiplication mod F IN GF(2**M) (LSB first)
--
--  Ports:
-- 
--  Source:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/interleaved_mult.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) interleaved multiplier PACKAGE
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE p_gf2m_interleaved_mult_package IS
    -- Constants
    CONSTANT M: integer := 163;
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --for M=163
END p_gf2m_interleaved_mult_package;

-----------------------------------
-- GF(2^M) interleaved MSB-first multipication data path
-----------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.p_gf2m_interleaved_mult_package.all;

ENTITY e_gf2m_interleaved_data_path IS
    PORT (
        -- Clock and reset signals
        clk_i: IN std_logic; 
        rst_i: IN std_logic;
        
        -- Input signals
        a_i: IN std_logic_vector(M-1 DOWNTO 0);
        b_i: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Load input, shift right and ???
        inic_i: IN std_logic; 
        shiftr_i: IN std_logic;  
        cec_i: IN std_logic;

        -- Output signals
        z_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_interleaved_data_path;

ARCHITECTURE rtl OF e_gf2m_interleaved_data_path IS
    -- Internal signals
    SIGNAL aa, bb, cc: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL new_a, new_c: std_logic_vector(M-1 DOWNTO 0);
BEGIN
    -- Register and multiplexer
    register_a: PROCESS(clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            aa <= (OTHERS => '0');
        ELSIF clk_i'event and clk_i = '1' THEN
            IF inic_i = '1' THEN
                -- Load register a
                aa <= a_i;
            ELSE
                -- Override register a with ???
                aa <= new_a;
            END IF;
        END IF;
    END PROCESS register_a;

    shift_register_b: PROCESS(clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            bb <= (OTHERS => '0');
        ELSIF clk_i'event and clk_i = '1' THEN
            IF inic_i = '1' THEN 
                -- Load register b
                bb <= b_i;
            END IF;
            IF shiftr_i = '1' THEN 
                -- Shift input of register b
                bb <= '0' & bb(M-1 DOWNTO 1);
            END IF;
        END IF;
    END PROCESS shift_register_b;

    register_c: PROCESS(inic_i, clk_i)
    BEGIN
        IF inic_i = '1' or rst_i = '1' THEN 
            cc <= (OTHERS => '0');
        ELSIF clk_i'event and clk_i = '1' THEN
            IF cec_i = '1' THEN 
                -- Set output register
                cc <= new_c; 
            END IF;
        END IF;
    END PROCESS register_c;
    
    -- Calculate next value for register a and c
    new_a(0) <= aa(M-1) and F(0);
    new_a_calc: FOR i IN 1 TO M-1 GENERATE
        new_a(i) <= aa(i-1) xor (aa(M-1) and F(i));
    END GENERATE;

    new_c_calc: FOR i IN 0 TO M-1 GENERATE
        new_c(i) <= cc(i) xor (aa(i) and bb(0));
    END GENERATE;

    -- Set output 
    z_o <= cc;    
END rtl;

-----------------------------------
-- GF(2^M) interleaved multipication
-----------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.p_gf2m_interleaved_mult_package.all;

ENTITY e_gf2m_interleaved_multiplier IS
    PORT (
        -- Clock, reset, enable
        clk_i: IN std_logic; 
        rst_i: IN std_logic; 
        enable_i: IN std_logic; 
        
        -- Input signals
        a_i: IN std_logic_vector (M-1 DOWNTO 0); 
        b_i: IN std_logic_vector (M-1 DOWNTO 0);
        
        -- Output signals
        z_o: OUT std_logic_vector (M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_gf2m_interleaved_multiplier;

ARCHITECTURE rtl OF e_gf2m_interleaved_multiplier IS    
    -- Import entity e_gf2m_interleaved_data_path
    COMPONENT e_gf2m_interleaved_data_path IS
        PORT(
            clk_i: IN std_logic; 
            rst_i: IN std_logic;
            a_i: IN std_logic_vector(M-1 DOWNTO 0);
            b_i: IN std_logic_vector(M-1 DOWNTO 0);
            inic_i: IN std_logic; 
            shiftr_i: IN std_logic;  
            cec_i: IN std_logic;
            z_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL inic, shiftr, cec: std_logic;
    SIGNAL count: natural RANGE 0 TO M;
    
    -- Define all available states
    type states IS RANGE 0 TO 3;
    SIGNAL current_state: states;
BEGIN
    -- Instantiate interleaved data path
    -- Used to computes the polynomial multiplication mod F in one step
    data_path: e_gf2m_interleaved_data_path PORT MAP (
            clk_i => clk_i,  
            rst_i => rst_i, 
            a_i => a_i, 
            b_i => b_i,
            inic_i => inic, 
            shiftr_i => shiftr,
            cec_i => cec,
            z_o => z_o
        );

    -- Clock signals
    counter: PROCESS(rst_i, clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            count <= 0;
        ELSIF clk_i' event and clk_i = '1' THEN
            -- Shift until all input bits are proceeds
            IF inic = '1' THEN 
                count <= 0;
            ELSIF shiftr = '1' THEN
                count <= count+1; 
            END IF;
        END IF;
    END PROCESS counter;

    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        -- Handle current state
        CASE current_state IS
            WHEN 0 TO 1 => inic <= '0'; shiftr <= '0'; ready_o <= '1'; cec <= '0';
            WHEN 2 => inic <= '1'; shiftr <= '0'; ready_o <= '0'; cec <= '0';
            WHEN 3 => inic <= '0'; shiftr <= '1'; ready_o <= '0'; cec <= '1';
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
                    IF count = M-1 THEN 
                        current_state <= 0; 
                    END IF;
            END CASE;
        END IF;
    END PROCESS control_unit;
END rtl;