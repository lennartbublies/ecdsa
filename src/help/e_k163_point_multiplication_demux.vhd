----------------------------------------------------------------------------------------------------
--  ENTITY - Multiplexer for point multiplication package
--  
--  Ports:
--   clk_i    - Clock
--   rst_i    - Reset flag
--   enable_i - Enable computation
--   data_i   - Input data to multiplex
--   en_xp_i  - Input type (x part of point)
--   en_yp_i  - Input type (y part of point)
--   en_k_i   - Input type (multiplier k)
--   out_o    - Output value
--   xy_o     -
--   ready_o  - Ready flag <not yet used>
--
--  Based on:
--   http://arithmetic-circuits.org/finite-field/vhdl_Models/chapter10_codes/VHDL/K-163/K163_point_multiplication.vhd
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------
 
------------------------------------------------------------
-- K163 point multiplication multiplexer
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_k163_point_multiplication_package.all;

ENTITY e_k163_point_multiplication_demux IS
    PORT (
        -- Clock, reset, enable
        clk_i: IN std_logic; 
        rst_i: IN std_logic; 
        enable_i: IN std_logic;
        
        -- Input data
        data_i: IN std_logic_vector(M-1 DOWNTO 0);
        
        -- Set type of input data (xp_i, yp_i or k value)
        en_xp_i: IN std_logic; 
        en_yp_i: IN std_logic; 
        en_k_i: IN std_logic;

        -- Calculated output data
        out_o: INOUT std_logic_vector(M-1 DOWNTO 0);
        xy_o: IN std_logic;

        ready_o: OUT std_logic
    );
END e_k163_point_multiplication_demux;

ARCHITECTURE rtl of e_k163_point_multiplication_demux IS
    -- Import entity e_k163_point_multiplication
    COMPONENT e_k163_point_multiplication IS
        PORT(
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

    -- Temporary signals for point P, Q and k
    SIGNAL xp, yp, k, xq_io, yq_io: std_logic_vector (M-1 DOWNTO 0);
BEGIN
    -- Instantiate point multiplication entity
    point_multiplier: e_k163_point_multiplication PORT MAP(
        xp_i => xp, 
        yp_i => yp, 
        k => k,
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable_i,
        xq_io => xq_io, 
        yq_io => yq_io, 
        ready_o => ready_o 
    );

    -- Multiplex input to xp_i, yp_i or k
    registers: PROCESS(clk_i)
    BEGIN
        IF clk_i' event and clk_i = '1' THEN 
            IF en_xp_i = '1' THEN 
                xp <= data_i; 
            END IF;
            IF en_yp_i = '1' THEN 
                yp <= data_i; 
            END IF;
            IF en_k_i = '1'  THEN 
               k <= data_i; 
            END IF;
        END IF;
    END PROCESS;

    --Multiplex out of point multiplication entity
    out_o <= xq_io WHEN xy_o = '0' ELSE yq_io;
END rtl;