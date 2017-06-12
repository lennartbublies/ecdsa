-------------------------------------------------------------------------------
-- Modul:        receive_data_TB 
-- Beschreibung: Testbench fuer 
--               
-- Autor:        Leander Schulz
-- Datum:        09.08.2016
-- Geändert:     09.08.2016
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY receive_data_TB IS
END ENTITY receive_data_TB;

ARCHITECTURE rd_TB_arch OF receive_data_TB IS
    COMPONENT receive_data IS
    GENERIC( baud_rate : IN NATURAL RANGE 1200 TO 115200
        );
    PORT(   
            clk      : IN std_logic;
            rx       : IN std_logic;  
            rst      : IN std_logic;
            out_data : OUT std_logic_vector (7 DOWNTO 0)
        );
    END COMPONENT receive_data;
    FOR ALL : receive_data USE ENTITY work.receive_data(rd_arch);
    
-- TB internal signals
    SIGNAL clk    : std_logic;
    SIGNAL s_rx   : std_logic;
    SIGNAL s_data : std_logic_vector(7 DOWNTO 0);
    --SIGNAL s_data : std_logic_vector(0 TO 7);
    
-- baud table:
-- 9600 baud ^= 104166ns ^= 5208 cycles
-- 115200 baud ^= 8680ns ^= 434 cycles
BEGIN
    
    clk_gen : PROCESS
    BEGIN
        clk <= '0'; 
        WAIT FOR 10 ns; 
        clk <= '1'; 
        WAIT FOR 10 ns;
    END PROCESS clk_gen;
    
    rx_gen : PROCESS
    BEGIN 
    
        -- "01010101"
        s_rx <= '1';
        WAIT FOR 10000 ns;
        s_rx <= '0';        -- Start Bit
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- Bit 2
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- Bit 3
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- Bit 4
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- Bit 5
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- idle
        WAIT FOR 30000 ns;
        
        -- "01101001":
        s_rx <= '0';        -- Start Bit
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- LSB (Bit 0)
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- Bit 1
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- Bit 2
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- Bit 3
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- Bit 4
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- Bit 5
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- Bit 6
        WAIT FOR 8680 ns;
        s_rx <= '0';        -- MSB (Bit 7)
                            -- no parity bit
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- stop Bit
        WAIT FOR 8680 ns;
        s_rx <= '1';        -- idle
        
        WAIT;
    END PROCESS rx_gen;
    
    rd_inst : receive_data 
    GENERIC MAP ( baud_rate => 115200 )
    PORT MAP ( clk       => clk,
               rx        => s_rx,
               rst       => '1',
               out_data  => s_data
    );
    
END ARCHITECTURE rd_TB_arch;