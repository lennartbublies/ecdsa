----------------------------------------------------------------------------------------------------
--  TOP LEVEL ENTITY - ECDSA
--  FPDA implementation of ECDSA algorithm  
--
--  Ports:
--   
--  Autor: Lennart Bublies (inf100434)
--  Date: 02.07.2017
----------------------------------------------------------------------------------------------------

------------------------------------------------------------
-- GF(2^M) ecdsa package
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.ALL;

PACKAGE e_k163_ecdsa_package IS
  CONSTANT M: natural := 9;
  --CONSTANT M: natural := 9;
  --CONSTANT M: natural := 163;
END e_k163_ecdsa_package;

------------------------------------------------------------
-- GF(2^M) ecdsa top level entity
------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.ALL;
USE work.e_k163_ecdsa_package.all;

ENTITY e_ecdsa IS
    PORT (
        -- Clock and reset
        clk_i: IN std_logic; 
        rst_i: IN std_logic;

        -- Enable computation
        enable_i: IN std_logic;
        
        -- Switch between SIGN and VALIDATE
        mode_i: IN std_logic;

        -- Hash
        hash_i: IN std_logic_vector(M-1 DOWNTO 0);

        -- Signature
        r_i: IN std_logic_vector(M-1 DOWNTO 0);
        s_i: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Ready flag
        ready_o: OUT std_logic;
        
        -- Signature valid
        valid_o: OUT std_logic;
        
        -- Signature
        sign_r_o: OUT std_logic_vector(M-1 DOWNTO 0);
        sign_s_o: OUT std_logic_vector(M-1 DOWNTO 0)
    );
END e_ecdsa;

ARCHITECTURE rtl OF e_ecdsa IS 

    -- Components -----------------------------------------

    -- Import entity e_k163_doubleadd_point_multiplication
    COMPONENT e_k163_doubleadd_point_multiplication IS
        PORT (
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
    END COMPONENT;

    -- Import entity e_k163_point_addition
    COMPONENT e_k163_point_addition IS
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
    
    -- Internal signals -----------------------------------------

    -- Elliptic curve parameter of sect163k1 and generated private and public key
    --  See http://www.secg.org/SEC2-Ver-1.0.pdf for more information
    SIGNAL xG : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- X of generator point G = (x, y)
    SIGNAL yG : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- Y of generator point G = (x, y)
    SIGNAL dA : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- Private key dA = k
    SIGNAL xQA : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- X component of public key qA = dA.G = (xQA, yQA)
    SIGNAL yQA : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- Y component of public key qA = dA.G = (xQA, yQA)
    SIGNAL N : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');   -- Order of generator point G
 
    -- Parameter to sign a message, ONLY FOR TESTING!
    SIGNAL k : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');   -- k for point generator, should be cryptograic secure randum number!
    SIGNAL xQB : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- X component of public key qB = dB.G = (xQB, yQB)
    SIGNAL yQB : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- Y component of public key qB = dB.G = (xQB, yQB)

    -- MODE SIGN
    SIGNAL xR : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- X component of point R
    SIGNAL yR : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');  -- Y component of point R
    SIGNAL xrda, e_xrda, s : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- Temporary results for signature computation
    SIGNAL enable_sign_r, done_sign_r: std_logic := '0';          -- Enable/Disable signature computation
    SIGNAL enable_sign_darx, done_sign_darx: std_logic := '0'; 
    SIGNAL enable_sign_z2k, done_sign_z2k: std_logic := '0';
    
    -- MODE VERIFY
    SIGNAL w : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL U1, U2 : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0'); -- Temporary results for signature computation
    SIGNAL enable_verify_invs, done_verify_invs : std_logic := '0'; 
    SIGNAL enable_verify_u12, done_verify_u1, done_verify_u2 : std_logic := '0'; 
    SIGNAL enable_verify_u1gu2qb, done_verify_u1g, done_verify_u2qb : std_logic := '0';
    SIGNAL enable_verify_P, done_verify_P : std_logic := '0';
    SIGNAL xGU1, yGU1 : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL xQBU2, yQBU2 : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL xP, yP : std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL valid : std_logic := '0';
    
    -- Constantsenable_verify_u12
    CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS=>'0');
    
    -- States for state machine
    subtype states IS natural RANGE 0 TO 17;
    SIGNAL current_state: states;
BEGIN
    -- Set parameter of sect163k1
--    xG  <= "010" & x"FE13C0537BBC11ACAA07D793DE4E6D5E5C94EEE8";
--    yG  <= "010" & x"89070FB05D38FF58321F2E800536D538CCDAA3D9";
--    N   <= "100" & x"000000000000000000020108A2E0CC0D99f8A5EE";
--    dA  <= "101" & x"4E78BA70719678AFC09BA25E822B81FCF23B87CA";
--    xQA <= "110" & x"80B2E0F985A6533D584FED618B7A061E79B9B917";
--    yQA <= "011" & x"9D123A952BA8E94F234884E9DBA5CEC4E38C94BA";
--  --xQB <= "000" & x"D4845314B7851DA63B9569E812A6602A22493216";
--  --yQB <= "000" & x"0D5B712A2981DD2FB1AFA15FE4079C79A3724BB0";
--    xQB <= "000" & x"D5B7391E8940565BD98587DF0BF8461E326B05D1";
--    yQB <= "000" & x"FF47471D622B5D82C98D58629679CAFFB2336514";
--    k   <= "000" & x"CD06203260EEE9549351BD29733E7D1E2ED49D88";

    xG  <= "011101110";
    yG  <= "010101111";
    N   <= "000000000";
    dA  <= "000111110";
    xQA <= "011000101";
    yQA <= "111011010";
    xQB <= "011000101";
    yQB <= "111011010";
    k   <= "001101001";
    
    -- SIGN -----------------------------------------------------------------
    
    -- Instantiate multiplier to compute R = k.G = (xR, yR)
    sign_pmul_r: e_k163_doubleadd_point_multiplication PORT MAP (
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_sign_r, 
        xp_i => xG, 
        yp_i => yG, 
        k => k,
        xq_io => xR, 
        yq_io => yR, 
        ready_o => done_sign_r 
    );
      
    -- Instantiate multiplier entity to compute dA * xR
    sign_mul_darx: e_gf2m_interleaved_multiplier PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_sign_darx, 
        a_i => dA,
        b_i => xR,
        z_o => xrda,
        ready_o => done_sign_darx
    );

    -- compute e + (dA * xR) 
    sign_add_edarx: FOR i IN 0 TO M-1 GENERATE
        e_xrda(i) <= xrda(i) xor hash_i(i);
    END GENERATE;

    -- Instantiate divider entity to compute (e + dA*xR)/k
    sign_divide_edarx_k: e_gf2m_divider PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_sign_z2k,
        g_i => e_xrda, 
        h_i => k,  
        z_o => s, 
        ready_o => done_sign_z2k
    );
    
    sign_r_o <= xR;
    sign_s_o <= s;
    
    -- VALIDATE -----------------------------------------------------------------

    -- Instantiate inversion entity to compute w = 1/s
    verify_invs: e_gf2m_eea_inversion PORT MAP (
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_verify_invs,
        a_i => s_i,
        z_o => w,
        ready_o => done_verify_invs
    );

    -- Instantiate multiplier entity to compute u1 = ew
    verify_mul_u1: e_gf2m_interleaved_multiplier PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_verify_u12, 
        a_i => hash_i,
        b_i => w,
        z_o => U1,
        ready_o => done_verify_u1
    );

    -- Instantiate multiplier entity to compute u2 = rw
    verify_mul_u2: e_gf2m_interleaved_multiplier PORT MAP( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_verify_u12, 
        a_i => r_i,
        b_i => w,
        z_o => U2,
        ready_o => done_verify_u2
    );
    
    -- Instantiate multiplier to compute tmp6 = u1.G
    sign_pmul_u1gu2q: e_k163_doubleadd_point_multiplication PORT MAP (
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_verify_u1gu2qb, 
        xp_i => xG, 
        yp_i => yG, 
        k => U1,
        xq_io => xGU1, 
        yq_io => yGU1, 
        ready_o => done_verify_u1g
    );
    
    -- Instantiate multiplier to compute tmp7 = u2.QB
    sign_pmul_u1gu2qb: e_k163_doubleadd_point_multiplication PORT MAP (
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_verify_u1gu2qb, 
        xp_i => xQB, 
        yp_i => yQB, 
        k => U2,
        xq_io => xQBU2, 
        yq_io => yQBU2, 
        ready_o => done_verify_u2qb
    );

    -- Instantiate point addition entity
    adder: e_k163_point_addition PORT MAP ( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_verify_P,
        x1_i => xGU1, 
        y1_i => yGU1, 
        x2_i => xQBU2, 
        y2_i => yQBU2,
        x3_io => xP, 
        y3_o => yP,
        ready_o => done_verify_P
    );
        
    -- State machine process
    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        -- Handle current state
        --  0,1   : Default state
        --  2,3   : SIGN   -> compute R = k.G = (xR, yR)
        --  4,5   : SIGN   -> compute xrda = dA*xR, e_xrda = e+xrda
        --  6,7   : SIGN   -> compute S = e_xrda/k
        --    ---> SIGN DONE
        --  8,9   : VERIFY -> compute 1/S
        --  10,11 : VERIFY -> compute u1 = ew und u2 = rw
        CASE current_state IS
            WHEN 0 TO 1   => enable_sign_r <= '0'; ready_o <= '1'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0'; 
            WHEN 2        => enable_sign_r <= '1'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 3        => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 4        => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '1'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 5        => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 6        => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '1'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 7 TO 8   => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 9        => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '1'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 10       => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 11       => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '1'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 12       => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 13       => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '1'; enable_verify_P <= '0';
            WHEN 14       => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
            WHEN 15       => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '1';
            WHEN 16 TO 17 => enable_sign_r <= '0'; ready_o <= '0'; enable_sign_darx <= '0'; enable_sign_z2k <= '0'; enable_verify_invs <= '0'; enable_verify_u12 <= '0'; enable_verify_u1gu2qb <= '0'; enable_verify_P <= '0';
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
                -- SIGN
                WHEN 1 => 
                    IF (enable_i = '1' and mode_i = '0') THEN 
                        current_state <= 2; 
                    ELSIF (enable_i = '1' and mode_i = '1') THEN
                        current_state <= 9;
                    END IF;
                WHEN 2 =>
                    current_state <= 3;
                WHEN 3 => 
                    IF (done_sign_r = '1') THEN
                        -- Validate R: restart if R = 0
                        --IF (xR = ZERO) THEN            -- NECESSARY IF K IS RANDOM VALUE!
                        --    current_state <= 2;
                        --ELSE
                            current_state <= 4;
                        --END IF;
					END IF;
                WHEN 4 =>
                    current_state <= 5;
                WHEN 5 => 
                    IF (done_sign_darx = '1') THEN
                        current_state <= 6;
                    END IF;
                WHEN 6 =>
                    current_state <= 7;
                WHEN 7 => 
                    IF (done_sign_z2k = '1') THEN
                        current_state <= 8;
					END IF;
                WHEN 8 => 
                    -- Validate S: restart if S = 0
                    --IF (s = ZERO) THEN
                    --    current_state <= 2;
                    --ELSE
                        current_state <= 0;
                    --END IF;
                -- VALIDATE
                WHEN 9 =>
                    current_state <= 10;
                WHEN 10 =>
                    IF (done_verify_invs = '1') THEN
                        current_state <= 11;
                    END IF;
                WHEN 11 =>
                    current_state <= 12;
                WHEN 12 =>
                    IF (done_verify_u1 = '1' and done_verify_u2 = '1') THEN
                        current_state <= 13;
                    END IF;
                WHEN 13 =>
                    current_state <= 14;   
                WHEN 14 =>
                    IF (done_verify_u1g = '1' and done_verify_u2qb = '1') THEN
                        current_state <= 15;
                    END IF;
                WHEN 15 =>
                    current_state <= 16;    
                WHEN 16 =>
                    IF (done_verify_P = '1') THEN
                        current_state <= 17;
                    END IF;
                WHEN 17 =>
                    IF (xP = r_i) THEN
                        valid <= '1';
                    ELSE    
                        valid <= '0';
                    END IF;
                    current_state <= 0;
            END CASE;
        END IF;
    END PROCESS;
    
    valid_o <= valid;
END;
