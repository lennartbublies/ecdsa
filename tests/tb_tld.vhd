-------------------------------------------------------------------------------
-- Module:       tb_tld
-- Purpose:      Testbench for Top Level Domain of ECDSA
--               
-- Author:       Leander Schulz
-- Date:         01.11.2017
-- Last change:  01.11.2017
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY tb_tld IS
END ENTITY tb_tld;

ARCHITECTURE tb_arch OF tb_tld IS
    -- import tld of ecdsa
    COMPONENT tld_ecdsa IS
        PORT (
            -- Clock and reset
            clk_i: IN std_logic; 
            rst_i: IN std_logic;         
            -- Uart read/write
            uart_rx_i : IN std_logic;
            uart_wx_i : OUT std_logic;
            rst_led   : OUT std_logic
        );
    END COMPONENT tld_ecdsa;
    
    --internal signals
    SIGNAL s_clk    : std_logic;
    SIGNAL s_rst    : std_logic := '0';
    SIGNAL S_rx     : std_logic;
    SIGNAL S_tx     : std_logic;
    
    SIGNAL s_r      : std_logic_vector (167 DOWNTO 0);
    SIGNAL s_s      : std_logic_vector (167 DOWNTO 0);
    SIGNAL s_m      : std_logic_vector (167 DOWNTO 0);
    SIGNAL s_mode   : std_logic;
    

BEGIN
    -- create ecdsa instance
    tld_inst : tld_ecdsa
        PORT MAP (
            clk_i       => s_clk, 
            rst_i       => s_rst,
            uart_rx_i   => s_rx,
            uart_wx_i   => s_tx
        );

    -- generate clock signal
    p_clk : PROCESS BEGIN
        s_clk <= '0';
        WAIT FOR 10 ns;
        s_clk <= '1';
        WAIT FOR 10 ns;
    END PROCESS p_clk;
    
    
    -- begin testbench tests
    testing : PROCESS IS 
        PROCEDURE p_send (
            SIGNAL s_mode : IN  std_logic;
            SIGNAL s_r    : IN  std_logic_vector(167 DOWNTO 0);
            SIGNAL s_s    : IN  std_logic_vector(167 DOWNTO 0);
            SIGNAL s_m    : IN  std_logic_vector(167 DOWNTO 0);
            SIGNAL s_rx   : OUT std_logic
        ) IS
        BEGIN
            -- send mode
            ASSERT FALSE REPORT "Send Mode" SEVERITY NOTE;
            s_rx <= '0';        -- Start Bit
            WAIT FOR 2000 ns;
            FOR i IN 0 TO 7 LOOP
                s_rx <= s_mode;
                WAIT FOR 2000 ns;
            END LOOP;
            s_rx <= '1';        -- stop bit and idle
            WAIT FOR 5000 ns;
            IF s_mode = '1' THEN
                -- send r
                ASSERT FALSE REPORT "Send Point R" SEVERITY NOTE;
                FOR i IN 20 DOWNTO 0 LOOP
                    s_rx <= '0';        -- Start Bit
                    WAIT FOR 2000 ns;
                    FOR j IN 0 TO 7 LOOP
                        s_rx <= s_r(i*8+j); -- send bits 0-7
                        WAIT FOR 2000 ns;
                    END LOOP;
                    s_rx <= '1';        -- stop bit and idle
                    WAIT FOR 5000 ns;            
                
                END LOOP;
                -- send s
                ASSERT FALSE REPORT "Send Point S" SEVERITY NOTE;
                FOR i IN 20 DOWNTO 0 LOOP
                    s_rx <= '0';        -- Start Bit
                    WAIT FOR 2000 ns;
                    FOR j IN 0 TO 7 LOOP
                        s_rx <= s_s(i*8+j); -- send bits 0-7
                        WAIT FOR 2000 ns;
                    END LOOP;
                    s_rx <= '1';        -- stop bit and idle
                    WAIT FOR 5000 ns;            
                
                END LOOP;
            END IF;
            -- send m
            ASSERT FALSE REPORT "Send Message" SEVERITY NOTE;
            FOR i IN 20 DOWNTO 0 LOOP
                s_rx <= '0';        -- Start Bit
                WAIT FOR 2000 ns;
                FOR j IN 0 TO 7 LOOP
                    ASSERT (i*8+j)<168 SEVERITY WARNING;
                    s_rx <= s_r(i*8+j); -- send bits 0-7
                    WAIT FOR 2000 ns;
                END LOOP;
                s_rx <= '1';        -- stop bit and idle
                WAIT FOR 5000 ns;            
            END LOOP;
        END p_send;
    
    BEGIN
        -- Initialise Hardware
        s_rx <= '1';
        WAIT FOR 100 ns;
        s_rst <= '1';
        WAIT FOR 20 ns;
        s_rst <= '0';
        WAIT FOR 80 ns;
        
        -- Test Case 1 - Sign
        s_r <= x"020B448AD8BE882CD980816C7EEA289FD3B2D517DB";
        s_s <= x"0345C0589DC9024D96376734C1BC98F328E94EF487";
        s_m <= x"054E78BA70719678AFC09BA25E822B81FCF23B87CA";
        s_mode <= '0';
        p_send(s_mode,s_r,s_s,s_m,s_rx);
        -- TODO: check tx for valid result
        WAIT FOR 3500 us;
        
        -- Test Case 1 - Verify
        s_mode <= '1';
        p_send(s_mode,s_r,s_s,s_m,s_rx);
        WAIT FOR 3500 us;
        
        -- Test Case 2 - Sign
        s_r <= x"020B448AD8BE882CD980816C7EEA289FD3B2D517DB";
        s_s <= x"0345C0589DC9024D96376734C1BC98F328E94EF487";
        s_m <= x"054E78BA70719678AFC09BA25E822B81FCF23B87CA";
        s_mode <= '0';
        p_send(s_mode,s_r,s_s,s_m,s_rx);
        -- TODO: check tx for valid result
        WAIT FOR 3500 us;
        
        -- Test Case 2 - Verify
        s_mode <= '1';
        p_send(s_mode,s_r,s_s,s_m,s_rx);
    
        WAIT;
    END PROCESS testing;
   



END ARCHITECTURE tb_arch;
