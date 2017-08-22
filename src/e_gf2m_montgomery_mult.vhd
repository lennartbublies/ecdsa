----------------------------------------------------------------------------------------------------
--  ENTITY - GF(2^M) Montgomery Multiplier
--  Computes the polynomial multiplication x.y.r^-1 mod f IN GF(2**m)
--
--  Ports:
-- 
--  Example:
--   (x^2+x+1)*(x^2+1) = x^4+x^3+x+1
--    1 1 1   * 1 0 1  = 11011 (bit-shift and XOR, shifts 2*M-2 bits)
--                 
--   BIT-SHIFT and XOR:        
--    11100 <- [1] 0  1   shift 2 bits
--      111 <-  1  0 [1]  shift 0 bits
--    11011 <-            XOR result
--
--    -> Result has more THEN M bits, so we've TO reduce it by irreducible polynomial like 1011
--       11011 
--       1011  <- shift 1 bits (degree 4 - degree 3)
--        1101 <- shift 0 bits (degree 3 - degree 3)
--        1011
--         110
--
--  Source:
--   http://www.arithmetic-circuits.org/finite-field/vhdl_Models/chapter7_codes/VHDL/montgomery_mult.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 22.06.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE e_gf2m_montgomery_mult_package IS
    CONSTANT M: integer := 8;
    --CONSTANT M: integer := 9;
    --CONSTANT M: integer := 163;
    CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "00011011"; --for M=8 bits
    --CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "000000011"; --for M=9 bits
    --CONSTANT F: std_logic_vector(M-1 DOWNTO 0):= "000"&x"00000000000000000000000000000000000000C9"; --for M=163
END e_gf2m_montgomery_mult_package;

-----------------------------------
--  GF(2^M) Montgomery multiplier data path
-----------------------------------
LIBRARY ieee; 
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE work.e_gf2m_montgomery_mult_package.all;

ENTITY e_gf2m_montgomery_data_path IS
    PORT (
        c_i: IN std_logic_vector(M-1 DOWNTO 0);
        b_i: IN std_logic_vector(M-1 DOWNTO 0);
        a_i: IN std_logic;
        c_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_gf2m_montgomery_data_path;

ARCHITECTURE rtl OF e_gf2m_montgomery_data_path IS
    SIGNAL prev_c0: std_logic;
BEGIN
    prev_c0 <= c_i(0) xor (a_i and b_i(0));

    datapath: for i IN 1 TO M-1 generate
        c_o(i-1) <= c_i(i) xor (a_i and b_i(i)) xor (F(i) and prev_c0);
    END generate;
    c_o(M-1) <= prev_c0;
END rtl;

-----------------------------------
-- GF(2^M) Montgomery multiplier
-----------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_gf2m_montgomery_mult_package.all;

ENTITY e_gf2m_montgomery_mult IS
    PORT (
        clk_i: IN std_logic; 
        rst_i: IN std_logic; 
        enable_i: IN std_logic; 
        a_i: IN std_logic_vector (M-1 DOWNTO 0); 
        b_i: IN std_logic_vector (M-1 DOWNTO 0);
        z_o: OUT std_logic_vector (M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_gf2m_montgomery_mult;

ARCHITECTURE rtl OF e_gf2m_montgomery_mult IS
    -- Import entity e_gf2m_montgomery_data_path
    COMPONENT e_gf2m_montgomery_data_path IS
        PORT (
            c_i: IN std_logic_vector(M-1 DOWNTO 0);
            b_i: IN std_logic_vector(M-1 DOWNTO 0);
            a_i: IN std_logic;
            c_o: OUT std_logic_vector(M-1 DOWNTO 0)
        );
    END COMPONENT e_gf2m_montgomery_data_path;

    SIGNAL inic, shift_r, ce_c: std_logic;
    SIGNAL count: natural RANGE 0 TO M;
    TYPE states IS RANGE 0 TO 3;
    SIGNAL current_state: states;
    SIGNAL aa, bb, cc, c: std_logic_vector (M-1 DOWNTO 0);
BEGIN
    -- Instantiate montgomery data path
    data_path: e_gf2m_montgomery_data_path PORT MAP (
        c_i => cc, 
        b_i => bb, 
        a_i => aa(0), 
        c_o => c
    );

    counter: PROCESS(rst_i, clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            count <= 0;
        ELSIF clk_i' event and clk_i = '1' THEN
            -- Load counter
            IF inic = '1' THEN 
                count <= 0;
            -- Increase counter WHEN shifting
            ELSIF shift_r = '1' THEN
                count <= count+1; 
            END IF;
        END IF;
    END PROCESS counter;

    sh_register_A: PROCESS(clk_i) --Shift register A
    BEGIN
        IF rst_i = '1' THEN 
            aa <= (OTHERS => '0');
        ELSIF clk_i'event and clk_i = '1' THEN
            IF inic = '1' THEN
                -- Load register a
                aa <= a_i;
            else
                -- Shift register b
                aa <= '0' & aa(M-1 DOWNTO 1);
            END IF;
        END IF;
    END PROCESS sh_register_A;

    register_B: PROCESS(clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            bb <= (OTHERS => '0');
        ELSIF clk_i'event and clk_i = '1' THEN
            IF inic = '1' THEN 
                -- Load register b
                bb <= b_i; 
            END IF;
        END IF;
    END PROCESS register_B;

    register_C: PROCESS(inic, clk_i)
    BEGIN
        IF inic = '1' or rst_i = '1' THEN 
            -- Load register a
            cc <= (OTHERS => '0');
        ELSIF clk_i'event and clk_i = '1' THEN
            IF ce_c = '1' THEN 
                -- Store output
                cc <= c; 
            END IF;
        END IF;
    END PROCESS register_C;
  
    -- Set output
    z_o <= cc;

    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2     : Load input arguments (initialize registers)
        --  3     : Shift and add
        CASE current_state IS
            WHEN 0 TO 1 => inic <= '0'; shift_r <= '0'; ready_o <= '1'; ce_c <= '0';
            WHEN 2      => inic <= '1'; shift_r <= '0'; ready_o <= '0'; ce_c <= '0';
            WHEN 3      => inic <= '0'; shift_r <= '1'; ready_o <= '0'; ce_c <= '1';
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