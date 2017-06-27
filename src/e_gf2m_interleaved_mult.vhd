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
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --FOR M=163
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
        -- Input signals
        A: IN std_logic_vector(M-1 DOWNTO 0);
        B: IN std_logic_vector(M-1 DOWNTO 0);
        clk, inic, shift_r, rst, ce_c: IN std_logic;

        -- Output signals
        Z: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_interleaved_data_path;

ARCHITECTURE rtl OF e_gf2m_interleaved_data_path IS
    -- Internal signals
    SIGNAL aa, bb, cc: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL new_a, new_c: std_logic_vector(M-1 DOWNTO 0);
BEGIN
    -- Register and multiplexer
    register_a: PROCESS(clk)
    BEGIN
        IF rst = '1' THEN 
            aa <= (OTHERS => '0');
        ELSIF clk'event and clk = '1' THEN
            IF inic = '1' THEN
                aa <= a;
            ELSE
                aa <= new_a;
            END IF;
        END IF;
    END PROCESS register_A;

    shift_register_b: PROCESS(clk)
    BEGIN
        IF rst = '1' THEN 
            bb <= (OTHERS => '0');
        ELSIF clk'event and clk = '1' THEN
            IF inic = '1' THEN 
                bb <= b;
            END IF;
            IF shift_r = '1' THEN 
                bb <= '0' & bb(M-1 DOWNTO 1);
            END IF;
        END IF;
    END PROCESS sh_register_B;

    register_c: PROCESS(inic, clk)
    BEGIN
        IF inic = '1' or rst = '1' THEN 
            cc <= (OTHERS => '0');
        ELSIF clk'event and clk = '1' THEN
            IF ce_c = '1' THEN 
                cc <= new_c; 
            END IF;
        END IF;
    END PROCESS register_C;

    z <= cc;

    new_a(0) <= aa(m-1) and F(0);
    new_a_calc: FOR i IN 1 TO M-1 GENERATE
        new_a(i) <= aa(i-1) xor (aa(m-1) and F(i));
    END GENERATE;

    new_c_calc: FOR i IN 0 TO M-1 GENERATE
        new_c(i) <= cc(i) xor (aa(i) and bb(0));
    END GENERATE;
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
        -- Input signals
        A, B: IN std_logic_vector (M-1 DOWNTO 0);
        clk, rst, start: IN std_logic; 
        
        -- Output signals
        Z: OUT std_logic_vector (M-1 DOWNTO 0);
        ready: OUT std_logic
    );
END interleaved_mult;

ARCHITECTURE rtl OF interleaved_mult IS
    SIGNAL inic, shift_r, ce_c: std_logic;
    SIGNAL count: natural RANGE 0 TO M;
    type states IS RANGE 0 TO 3;
    SIGNAL current_state: states;
BEGIN
    -- Instantiate interleaved data path
    data_path: work.e_gf2m_interleaved_data_path PORT MAP (
            A => A, 
            B => B,
            clk => clk, 
            inic => inic, 
            shift_r => shift_r, 
            rst => rst, 
            ce_c => ce_c,
            Z => Z
        );

    -- Clock signals
    counter: PROCESS(rst, clk)
    BEGIN
        IF rst = '1' THEN 
            count <= 0;
        ELSIF clk' event and clk = '1' THEN
            IF inic = '1' THEN 
                count <= 0;
            ELSIF shift_r = '1' THEN
                count <= count+1; 
            END IF;
        END IF;
    END PROCESS counter;

    -- State machine
    control_unit: PROCESS(clk, rst, current_state)
    BEGIN
        CASE current_state IS
            WHEN 0 TO 1 => inic <= '0'; shift_r <= '0'; ready <= '1'; ce_c <= '0';
            WHEN 2 => inic <= '1'; shift_r <= '0'; ready <= '0'; ce_c <= '0';
            WHEN 3 => inic <= '0'; shift_r <= '1'; ready <= '0'; ce_c <= '1';
        END CASE;

        IF rst = '1' THEN 
            current_state <= 0;
        ELSIF clk'event and clk = '1' THEN
            CASE current_state IS
                WHEN 0 => IF start = '0' THEN current_state <= 1; END IF;
                WHEN 1 => IF start = '1' THEN current_state <= 2; END IF;
                WHEN 2 => current_state <= 3;
                WHEN 3 => IF count = M-1 THEN current_state <= 0; END IF;
            END CASE;
        END IF;
    END PROCESS control_unit;
END rtl;