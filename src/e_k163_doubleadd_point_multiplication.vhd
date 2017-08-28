----------------------------------------------------------------------------------------------------
--  ENTITY - Elliptic Curve Point Multiplication IN K163
--  Implementation with Double-And-Add algorithm
--
--  Autor: Lennart Bublies (inf100434)
--  Date: 29.06.2017
----------------------------------------------------------------------------------------------------
 
------------------------------------------------------------
-- K163 point multiplication package
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;

PACKAGE e_k163_point_multiplication_package IS
  --CONSTANT M: natural := 8;
  CONSTANT M: natural := 9;
  --CONSTANT M: natural := 163;
  CONSTANT ZERO: std_logic_vector(M-1 DOWNTO 0) := (OTHERS => '0');
END e_k163_point_multiplication_package;

------------------------------------------------------------
-- K163 point multiplication
------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_unsigned.all;
USE work.e_k163_point_multiplication_package.all;

ENTITY e_k163_point_multiplication IS
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
END e_k163_point_multiplication;

ARCHITECTURE rtl of e_k163_point_multiplication IS
    -- Import entity e_k163_point_doubling 
    COMPONENT e_k163_point_doubling  IS
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

    -- Internal signals
	SIGNAL start_doubling, doubling_done, start_addition, addition_done: std_logic;

    -- Define all available states
    subtype states IS natural RANGE 0 TO 2;
    SIGNAL current_state: states;
BEGIN
    -- Instantiate point doubling entity
    doubling: e_k163_point_doubling PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => start_doubling,  
            x1_i => , 
            y1_i => , 
            x2_io => , 
            y2_o => , 
            ready_o => doubling_done
        );

    -- Instantiate point addition entity
	addition: e_k163_point_addition PORT MAP(
            clk_i => clk_i, 
            rst_i => rst_i,
            enable_i => start_addition,  
            x1_i => , 
            y1_i => , 
            x2_i => ,  
            y2_i => , 
            x3_io => , 
            y3_o => , 
            ready_o => addition_done
        );

	-- TODO ...
	
    -- State machine
    control_unit: PROCESS(clk_i, rst_i, current_state)
    BEGIN
        -- Handle current state
		--  ...
        CASE current_state IS
            WHEN 0 TO 1 => ready_o <= '1';
            WHEN 2 => ready_o <= '0';
			-- TODO ...
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
                    current_state <= 0;
				-- TODO ...
            END CASE;
        END IF;
    END PROCESS;
END rtl;