----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Point Multiplication IN K163
--  Implementation WITH Double-And-Add algorithm
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------
 
------------------------------------------------------------
-- K163 point multiplication PACKAGE
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE e_k163_montgomery_point_multiplication_parameters IS
    --CONSTANT M: integer := 8;
    CONSTANT M: integer := 9;
    --CONSTANT M: integer := 163;
    --CONSTANT logM: integer := 4; --for M=8 bits
    CONSTANT logM: integer := 5; --for M=9 bits
    --CONSTANT logM: integer := 9; --logM IS the number OF bits OF m plus an additional sign bit
    --CONSTANT F: std_logic_vector(M DOWNTO 0):= "100011011"; --FOR M=8 bits
    --CONSTANT F: std_logic_vector(M downto 0):= "100011011"; --for M=8 bits
    CONSTANT F: std_logic_vector(M downto 0):= "1000000011"; --for M=9 bits
    --CONSTANT F: std_logic_vector(M DOWNTO 0):= x"800000000000000000000000000000000000000C9"; --FOR M=163
END e_k163_montgomery_point_multiplication_parameters;


------------------------------------------------------------
-- K163 point multiplication data path
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_k163_montgomery_point_multiplication_parameters.all;

ENTITY Montgomery_projective_data_path IS
    PORT(
        xP, yP: IN std_logic_vector(M-1 DOWNTO 0);
        clk, rst, start_mult, start_div,load, en_XA, en_XB, en_ZA, en_ZB, en_T1, en_T2: IN std_logic;
        sel_a: IN std_logic_vector(2 DOWNTO 0);
        sel_b, sel_c, sel_div, sel_square, sel_XA, sel_XB, sel_ZA: IN std_logic_vector(1 DOWNTO 0);
        xQ, yQ: OUT std_logic_vector(M-1 DOWNTO 0);
        mult_done, div_done, infinity: OUT std_logic
    );
END Montgomery_projective_data_path;

ARCHITECTURE rtl OF Montgomery_projective_data_path IS
    -- Import entity e_gf2m_divider
    COMPONENT e_gf2m_divider IS
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

    SIGNAL XA, XB, ZA, ZB, T1, T2, next_XA, next_XB, next_ZA, square1, square2, square3, a, b, c, product, 
    mult_out, num, den, div_out, s1, s2, s3, s4, XAxorxP, XBxorxP, xPxoryP: std_logic_vector (M-1 DOWNTO 0);
    CONSTANT zero: std_logic_vector(M-1 DOWNTO 0) := (OTHERS => '0');
    CONSTANT one: std_logic_vector(M-1 DOWNTO 0) := conv_std_logic_vector(1, M);
BEGIN
    a_mod_f_multiplier: e_gf2m_interleaved_multiplier PORT MAP (
        clk_i => clk, 
        rst_i => rst, 
        enable_i => start_mult, 
        a_i => a, 
        b_i => b, 
        z_o => product, 
        ready_o => mult_done
    );

    a_mod_f_divider: e_gf2m_divider PORT MAP(
        clk_i => clk, 
        rst_i => rst, 
        enable_i => start_div, 
        g_i => num, 
        h_i => den, 
        z_o => div_out, 
        ready_o => div_done
    );
    
    a_squarer: e_gf2m_classic_squarer PORT MAP (
        a_i => s3, 
        c_o => square2
    );

    a_second_squarer: e_gf2m_classic_squarer PORT MAP (
        a_i => square2, 
        c_o => square1
    );

    a_third_squarer: e_gf2m_classic_squarer PORT MAP (
        a_i => xP, 
        c_o => s4
    );

    xor_gates1: FOR i IN 0 TO M-1 GENERATE 
        XAxorxP(i) <= XA(i) XOR xP(i); 
    END GENERATE;
    
    WITH sel_a SELECT a <= XA WHEN "000", XB WHEN "001", xP WHEN "010", T1 WHEN "011", XAxorxP WHEN OTHERS;

    xor_gates2: FOR i IN 0 TO M-1 GENERATE 
        XBxorxP(i) <= XB(i) XOR xP(i); 
    END GENERATE;
    
    WITH sel_b SELECT b <= ZB WHEN "00", ZA WHEN "01", T2 WHEN "10", XBxorxP WHEN OTHERS;

    WITH sel_c SELECT c <= XB WHEN "00", XA WHEN "01", square3 WHEN "10", zero WHEN OTHERS;
    
    xor_gates7: FOR i IN 0 TO M-1 GENERATE 
        mult_out(i) <= product(i) XOR c(i); 
    END GENERATE;

    WITH sel_div SELECT num <= XA WHEN "00", XB WHEN "01", ZA WHEN OTHERS;
    WITH sel_div SELECT den <= ZA WHEN "00", ZB WHEN "01", xP WHEN OTHERS;

    WITH sel_square SELECT s1 <= XA WHEN "00", XB WHEN "01", T1 WHEN OTHERS;
    WITH sel_square SELECT s2 <= ZA WHEN "00", ZB WHEN "01", T2 WHEN "10", zero WHEN OTHERS;
    
    xor_gates3: FOR i IN 0 TO M-1 GENERATE 
        s3(i) <= s1(i) XOR s2(i); 
    END GENERATE;

    xor_gates4: FOR i IN 0 TO M-1 GENERATE 
        square3(i) <= s4(i) XOR yP(i); 
    END GENERATE;

    WITH sel_XA SELECT next_XA <= square1 WHEN "00", mult_out WHEN "01", xP WHEN "10", div_out WHEN OTHERS;

    register_XA: PROCESS(clk)
    BEGIN
        IF clk'event and clk = '1' THEN
            IF load = '1' THEN 
                XA <= one;
            ELSIF en_XA = '1' THEN 
                XA <= next_XA;
            END IF;
        END IF;
    END PROCESS;

    WITH sel_XB SELECT next_XB <= mult_out WHEN "00", square1 WHEN "01", div_out WHEN OTHERS;

    register_XB: PROCESS(clk)
    BEGIN
        IF clk'event and clk = '1' THEN
            IF load = '1' THEN 
                XB <= xP;
            ELSIF en_XB = '1' THEN 
                XB <= next_XB;
            END IF;
        END IF;
    END PROCESS;

    xor_gates5: FOR i IN 0 TO M-1 GENERATE 
        xPxoryP(i) <= xP(i) XOR yP(i); 
    END GENERATE;
    
    WITH sel_ZA SELECT next_ZA <= square2 WHEN "00", xPxoryP WHEN "01", mult_out WHEN "10", div_out WHEN OTHERS;

    register_ZA: PROCESS(clk)
    BEGIN
        IF clk'event and clk = '1' THEN
            IF load = '1' THEN 
                ZA <= zero;
            ELSIF en_ZA = '1' THEN 
                ZA <= next_ZA;
            END IF;
        END IF;
    END PROCESS;

    register_ZB: PROCESS(clk)
    BEGIN
        IF clk'event and clk = '1' THEN
            IF load = '1' THEN 
                ZB <= one;
            ELSIF en_ZB = '1' THEN 
                ZB <= square2;
            END IF;
        END IF;
    END PROCESS;

    infinity <= '1' WHEN ZB = zero else '0';

    register_T1: PROCESS(clk)
    BEGIN
        IF clk'event and clk = '1' THEN
            IF en_T1 = '1' THEN 
                T1 <= mult_out;
            END IF;
        END IF;
    END PROCESS;

    register_T2: PROCESS(clk)
    BEGIN
        IF clk'event and clk = '1' THEN
            IF en_T2 = '1' THEN 
                T2 <= mult_out;
            END IF;
        END IF;
    END PROCESS;

    xQ <= XA; 
    
    xor_gates6: FOR i IN 0 TO M-1 GENERATE 
        yQ(i) <= ZA(i) XOR yP(i); 
    END GENERATE;
END rtl;

------------------------------------------------------------
-- K163 point multiplication
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_k163_montgomery_point_multiplication_parameters.all;

ENTITY e_k163_montgomery_point_multiplication IS
    PORT (
        clk_i: IN std_logic;
        rst_i: IN std_logic;
        enable_i: IN std_logic;
        xp_i: IN std_logic_vector(M-1 DOWNTO 0); 
        yp_i: IN std_logic_vector(M-1 DOWNTO 0); 
        k: IN std_logic_vector(M-1 DOWNTO 0);
        xq_io: OUT std_logic_vector(M-1 DOWNTO 0);
        yq_io: OUT std_logic_vector(M-1 DOWNTO 0);
        ready_o: OUT std_logic
    );
END e_k163_montgomery_point_multiplication;

ARCHITECTURE rtl OF e_k163_montgomery_point_multiplication IS
    COMPONENT e_k163_montgomery_point_multiplication_data_path IS
        PORT(
            xP, yP: IN std_logic_vector(M-1 DOWNTO 0);
            clk, rst, start_mult, start_div,load, en_XA, en_XB, en_ZA, en_ZB, en_T1, en_T2: IN std_logic;
            sel_a: IN std_logic_vector(2 DOWNTO 0);
            sel_b, sel_c, sel_div, sel_square, sel_XA, sel_XB, sel_ZA: IN std_logic_vector(1 DOWNTO 0);
            xQ, yQ: OUT std_logic_vector(M-1 DOWNTO 0);
            mult_done, div_done, infinity: OUT std_logic
        );
    END COMPONENT;

    SIGNAL start_mult, start_div, load, en_XA, en_XB, en_ZA, en_ZB, en_T1, en_T2, shift, infinity: std_logic;
    SIGNAL sel_a: std_logic_vector(2 DOWNTO 0);
    SIGNAL sel_b, sel_c, sel_div, sel_square, sel_XA, sel_XB, sel_ZA: std_logic_vector(1 DOWNTO 0);
    SIGNAL mult_done, div_done: std_logic;
    SIGNAL internal_k: std_logic_vector(M-1 DOWNTO 0);
    SIGNAL count: natural RANGE 0 TO M;

    type states IS RANGE 0 TO 49;
    SIGNAL current_state: states;
BEGIN
    main_component: e_k163_montgomery_point_multiplication_data_path PORT MAP(
        xP => xp_i, yP => yp_i, clk => clk_i, rst => rst_i, start_mult => start_mult, start_div => start_div,
        load => load, en_XA => en_XA, en_XB => en_XB, en_ZA => en_ZA , en_ZB => en_ZB, 
        en_T1=> en_T1, en_T2 => en_T2, sel_a => sel_A, sel_b => sel_B, sel_c => sel_C, sel_div => sel_div,
        sel_square => sel_square, sel_XA => sel_XA, sel_XB => sel_XB, sel_ZA => sel_ZA, xQ => xq_io, 
        yQ => yq_io, mult_done => mult_done, div_done => div_done, infinity => infinity
    );  

    counter: PROCESS(rst_i, clk_i)
    BEGIN
        IF rst_i = '1' THEN 
            count <= 0;
        ELSIF clk_i' event and clk_i = '1' THEN
            IF load = '1' THEN 
                count <= 0;
            ELSIF shift = '1' THEN 
                count <= count+1; 
            END IF;
        END IF;
    END PROCESS;

    shift_register: PROCESS(clk_i)
    BEGIN
        IF clk_i'event and clk_i = '1' THEN
            IF load = '1' THEN 
                internal_k <= k;
            ELSIF shift = '1' THEN 
                internal_k <= internal_k(M-2 DOWNTO 0)&'0';
            END IF;
        END IF;
    END PROCESS;

    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        case current_state IS
            WHEN 0 TO 1 => 
                sel_A <= "000"; sel_B <= "00"; sel_c <= "00"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '1';
            WHEN 2 => 
                sel_A <= "000"; sel_B <= "00"; sel_c <= "00"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '1'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 3 => 
                sel_A <= "000"; sel_B <= "00"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 4 => 
                sel_A <= "000"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 5 => 
                sel_A <= "000"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '1'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 6 => 
                sel_A <= "001"; sel_B <= "01"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 7 => 
                sel_A <= "001"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 8 => 
                sel_A <= "001"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '1'; shift <= '0'; ready_o <= '0';
            WHEN 9 => 
                sel_A <= "001"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '1'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 10 => 
                sel_A <= "010"; sel_B <= "00"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 11 => 
                sel_A <= "010"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 12 => 
                sel_A <= "010"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '1'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 13 => 
                sel_A <= "011"; sel_B <= "10"; sel_c <= "00"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 14 => 
                sel_A <= "011"; sel_B <= "10"; sel_c <= "00"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 15 => 
                sel_A <= "011"; sel_B <= "10"; sel_c <= "00"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '1'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 16 => 
                sel_A <= "000"; sel_B <= "01"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 17 => 
                sel_A <= "000"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 18 => 
                sel_A <= "000"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '1'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 19 => 
                sel_A <= "000"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "00"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '1';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 20 => 
                sel_A <= "000"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '1';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';

            --END OF FIRST PART

            WHEN 21 => 
                sel_A <= "001"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '1';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 22 => 
                sel_A <= "010"; sel_B <= "01"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 23 => 
                sel_A <= "010"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 24 => 
                sel_A <= "010"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "01"; en_XA <= '1';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 25 => 
                sel_A <= "011"; sel_B <= "10"; sel_c <= "01"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 26 => 
                sel_A <= "011"; sel_B <= "10"; sel_c <= "01"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 27 => 
                sel_A <= "011"; sel_B <= "10"; sel_c <= "01"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "01"; en_XA <= '1';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 28 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 29 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 30 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "10"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '1'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 31 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "01"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "01"; en_XB <= '1'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 32 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '1'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';

            --END OF SECOND PART

            WHEN 33 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "00"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "00"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '1'; ready_o <= '0';
            WHEN 34 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '1';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '1';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 35 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '1'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 36 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 37 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "00"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "11"; en_XA <= '1';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 38 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "01"; start_div <= '1'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 39 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 40 => 
                sel_A <= "001"; sel_B <= "00"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "11"; en_XA <= '0';
                sel_XB <= "10"; en_XB <= '1'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 41 => 
                sel_A <= "100"; sel_B <= "11"; sel_c <= "10"; start_mult <= '1';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 42 => 
                sel_A <= "100"; sel_B <= "11"; sel_c <= "10"; start_mult <= '0';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 43 => 
                sel_A <= "100"; sel_B <= "11"; sel_c <= "10"; start_mult <= '0';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "10"; en_ZA <= '1';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 44 => 
                sel_A <= "100"; sel_B <= "01"; sel_c <= "11"; start_mult <= '1';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 45 => 
                sel_A <= "100"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 46 => 
                sel_A <= "100"; sel_B <= "01"; sel_c <= "11"; start_mult <= '0';
                sel_div <= "01"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "10"; en_ZA <= '1';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 47 => 
                sel_A <= "100"; sel_B <= "01"; sel_c <= "10"; start_mult <= '0';
                sel_div <= "10"; start_div <= '1'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN 48 => 
                sel_A <= "100"; sel_B <= "01"; sel_c <= "10"; start_mult <= '0';
                sel_div <= "10"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "01"; en_ZA <= '0';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
            WHEN OTHERS => 
                sel_A <= "100"; sel_B <= "01"; sel_c <= "10"; start_mult <= '0';
                sel_div <= "10"; start_div <= '0'; sel_square <= "11"; 
                load <= '0'; sel_XA <= "10"; en_XA <= '0';
                sel_XB <= "00"; en_XB <= '0'; sel_ZA <= "11"; en_ZA <= '1';
                en_ZB <= '0'; en_T1 <= '0'; en_T2 <= '0'; shift <= '0'; ready_o <= '0';
        END case;

        IF rst_i = '1' THEN 
            current_state <= 0;
        ELSIF clk_i'event and clk_i = '1' THEN
            case current_state IS
                WHEN 0 => IF enable_i = '0' THEN current_state <= 1; END IF;
                WHEN 1 => IF enable_i = '1' THEN current_state <= 2; END IF;
                WHEN 2 => current_state <= 3;
                WHEN 3 => current_state <= 4;
                WHEN 4 => IF mult_done = '1' THEN current_state <= 5; END IF;
                WHEN 5 => current_state <= 6;
                WHEN 6 => current_state <= 7;
                WHEN 7 => IF mult_done = '1' THEN current_state <= 8; END IF;
                WHEN 8 => IF internal_k(M-1) = '0' THEN current_state <= 9; else current_state <= 21; END IF;
                WHEN 9 => current_state <= 10;
                WHEN 10 => current_state <= 11;
                WHEN 11 => IF mult_done = '1' THEN current_state <= 12; END IF;
                WHEN 12 => current_state <= 13;
                WHEN 13 => current_state <= 14;
                WHEN 14 => IF mult_done = '1' THEN current_state <= 15; END IF;
                WHEN 15 => current_state <= 16;
                WHEN 16 => current_state <= 17;
                WHEN 17 => IF mult_done = '1' THEN current_state <= 18; END IF;
                WHEN 18 => current_state <= 19;
                WHEN 19 => current_state <= 20;      
                WHEN 20 => IF count < M-1 THEN current_state <= 33; 
                ELSIF infinity = '1' THEN current_state <= 34;
                else current_state <= 35; END IF;
                WHEN 21 => current_state <= 22;
                WHEN 22 => current_state <= 23;
                WHEN 23 => IF mult_done = '1' THEN current_state <= 24; END IF;
                WHEN 24 => current_state <= 25;
                WHEN 25 => current_state <= 26;
                WHEN 26 => IF mult_done = '1' THEN current_state <= 27; END IF;
                WHEN 27 => current_state <= 28;
                WHEN 28 => current_state <= 29;
                WHEN 29 => IF mult_done = '1' THEN current_state <= 30; END IF;
                WHEN 30 => current_state <= 31;
                WHEN 31 => current_state <= 32;      
                WHEN 32 => IF count < M-1 THEN current_state <= 33; 
                ELSIF infinity = '1' THEN current_state <= 34;
                else current_state <= 35; END IF;
                WHEN 33 => current_state <= 3;
                WHEN 34 => current_state <= 0;
                WHEN 35 => current_state <= 36;
                WHEN 36 => IF div_done = '1' THEN current_state <= 37; END IF;
                WHEN 37 => current_state <= 38;
                WHEN 38 => current_state <= 39;
                WHEN 39 => IF div_done = '1' THEN current_state <= 40; END IF;
                WHEN 40 => current_state <= 41;
                WHEN 41 => current_state <= 42;
                WHEN 42 => IF mult_done = '1' THEN current_state <= 43; END IF;
                WHEN 43 => current_state <= 44;
                WHEN 44 => current_state <= 45;
                WHEN 45 => IF mult_done = '1' THEN current_state <= 46; END IF;
                WHEN 46 => current_state <= 47;
                WHEN 47 => current_state <= 48;
                WHEN 48 => IF div_done = '1' THEN current_state <= 49; END IF;
                WHEN OTHERS => current_state <= 0;
            END case;
        END IF;
    END PROCESS;
END rtl;