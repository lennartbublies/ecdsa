----------------------------------------------------------------------------------------------------
--  TOP LEVEL ENTITY - ECDSA
--  FPDA implementation of ECDSA algorithm  
--
--  Ports:
--   
--  Autor: Lennart Bublies (inf100434)
--  Date: 02.07.2017
----------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
use work.e_k163_point_multiplication_package.all;

ENTITY tld_ecdsa IS
    PORT (
        -- Clock and reset
        clk_i: IN std_logic; 
        rst_i: IN std_logic
    );
END tld_ecdsa;

ARCHITECTURE rtl OF tld_ecdsa IS 
    -- Import entity e_k163_point_multiplication
    --COMPONENT e_k163_point_multiplication IS
    --    PORT (
    --        clk_i: IN std_logic; 
    --        rst_i: IN std_logic; 
    --        enable_i: IN std_logic;
    --        xp_i: IN std_logic_vector(M-1 DOWNTO 0); 
    --        yp_i: IN std_logic_vector(M-1 DOWNTO 0); 
    --        k: IN std_logic_vector(M-1 DOWNTO 0);
    --        xq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
    --        yq_io: INOUT std_logic_vector(M-1 DOWNTO 0);
    --        ready_o: OUT std_logic
    --    );
    --END COMPONENT;

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
    
    SIGNAL px, py, qx, qy, rx, ry: std_logic_vector(M-1 DOWNTO 0); 
    SIGNAL enable, ready: std_logic;
BEGIN
    -- Instantiate seccond point multiplier entity
    -- multiplier: e_k163_point_multiplication PORT MAP(
    --     clk_i => clk_i, 
    --     rst_i => rst_i, 
    --     enable_i => enable, 
    --     xp_i => , 
    --     yp_i => , 
    --     k => ,
    --     xq_io => , 
    --     yq_io => , 
    --     ready_o => ready 
    -- );

    -- Instantiate point addition entity
    adder: e_k163_point_addition PORT MAP ( 
        clk_i => clk_i, 
        rst_i => rst_i, 
        enable_i => enable,
        x1_i => px, 
        y1_i => py, 
        x2_i => qx, 
        y2_i => qy,
        x3_io => rx, 
        y3_o => ry,
        ready_o => ready
    );
END;