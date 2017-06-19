----------------------------------------------------------------------------
-- Extended Euclidean Inversion (EEA_inversion.vhd)
--
-- Computes the 1/x mod f in GF(2**m)
-- Implements a sequential cincuit 
-- 
----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
package eea_inversion_package is
  constant M: integer := 8;
  constant logM: integer := 3;
  constant F: std_logic_vector(M-1 downto 0):= "00011011"; --for M=8 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"001B"; --for M=16 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"0101001B"; --for M=32 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"010100000101001B"; --for M=64 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"0000000000000000010100000101001B"; --for M=128 bits
  --constant F: std_logic_vector(M-1 downto 0):= "000"&x"00000000000000000000000000000000000000C9"; --for M=163
  --constant F: std_logic_vector(M-1 downto 0):= (0=> '1', 74 => '1', others => '0'); --for M=233
end eea_inversion_package;


-----------------------------------
-- eea_inversion data_path
-----------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.eea_inversion_package.all;

entity eea_inversion_data_path is
port (
  r, s: in std_logic_vector(M downto 0);
  u, v: in std_logic_vector(M downto 0);
  d: in STD_LOGIC_VECTOR (logM downto 0);
  new_r, new_s: out std_logic_vector(M downto 0);
  new_u, new_v: out std_logic_vector(M downto 0);
  new_d: out STD_LOGIC_VECTOR (logM downto 0)
);
end eea_inversion_data_path;

architecture rtl of eea_inversion_data_path is
  constant zero: std_logic_vector(logM downto 0):= (others => '0');

begin

  process(r,s,u,v,d)
  begin
    if R(m) = '0' then
      new_R <= R(M-1 downto 0) & '0';
      new_U <= U(M-1 downto 0) & '0';
      new_S <= S;
      new_V <= V;
      new_d <= d + 1;
    else
     if d = ZERO then
       if S(m) = '1' then
         new_R <= (S(M-1 downto 0) xor R(M-1 downto 0)) & '0';
         new_U <= (V(M-1 downto 0) xor U(M-1 downto 0)) & '0';
       else
         new_R <= S(M-1 downto 0) & '0';
         new_U <= V(M-1 downto 0) & '0';
       end if;
       new_S <= R;
       new_V <= U;
       new_d <= (0=> '1', others => '0');
     else --d /= ZERO
       new_R <= R;
       new_U <= '0' & U(M downto 1);
       if S(m) = '1' then
         new_S <= (S(M-1 downto 0) xor R(M-1 downto 0)) & '0';
         new_V <= (V xor U);
       else
         new_S <= S(M-1 downto 0) & '0';
         new_V <= V;
       end if;
       new_d <= d - 1;
     end if;
    end if;
  end process;

end rtl;

-----------------------------------
-- euclidean inversion (eea_inversion)
-----------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.eea_inversion_package.all;

entity eea_inversion is
port (
  A: in std_logic_vector (M-1 downto 0);
  clk, reset, start: in std_logic; 
  Z: out std_logic_vector (M-1 downto 0);
  done: out std_logic
);
end eea_inversion;

architecture rtl of eea_inversion is

  COMPONENT eea_inversion_data_path
  PORT(
    r, s : IN std_logic_vector(M downto 0);
    u, v : IN std_logic_vector(M downto 0);
    d : IN std_logic_vector(logM downto 0);
    new_r, new_s : OUT std_logic_vector(M downto 0);
    new_u, new_v : OUT std_logic_vector(M downto 0);
    new_d : OUT std_logic_vector(logM downto 0)
    );
  END COMPONENT;

  signal count: natural range 0 to 2*M;
  type states is range 0 to 3;
  signal current_state: states;
  
  signal first_step, capture: std_logic; 
  signal r, s, new_r, new_s : std_logic_vector(M downto 0);
  signal u, v, new_u, new_v: std_logic_vector(M downto 0);
  signal d, new_d: std_logic_vector(logM downto 0);
begin

  data_path_block: eea_inversion_data_path PORT MAP(
      r => r, s => s,
      u => u, v => v, d => d, 
      new_r => new_r, new_s => new_s,
      new_u => new_u, new_v => new_v, new_d => new_d );
  
  z <= u(M-1 downto 0);

  process(clk, reset)
  begin
    if reset = '1' or first_step = '1' then 
       r <= ('0' & A); s <= ('1' & F);
       u <= (0 => '1', others => '0'); v <= (others => '0');
       d <= (others => '0');
    elsif clk'event and clk = '1' then
      if capture = '1' then
        r <= new_r; s <= new_s;
        u <= new_u; v <= new_v;
        d <= new_d; 
      end if;
    end if;
  end process;
  
  counter: process(reset, clk)
  begin
    if reset = '1' then count <= 0;
    elsif clk' event and clk = '1' then
      if first_step = '1' then 
        count <= 0;
      elsif capture = '1' then
        count <= count+1; 
    end if;
    end if;
  end process counter;

  control_unit: process(clk, reset, current_state, count)
  begin
    case current_state is
      when 0 to 1 => first_step <= '0'; done <= '1'; capture <= '0';
      when 2 => first_step <= '1'; done <= '0'; capture <= '0';
      when 3 => first_step <= '0'; done <= '0'; capture <= '1';
    end case;
  
    if reset = '1' then current_state <= 0;
    elsif clk'event and clk = '1' then
      case current_state is
      when 0 => if start = '0' then current_state <= 1; end if;
      when 1 => if start = '1' then current_state <= 2; end if;
      when 2 => current_state <= 3;
      when 3 => if count = 2*M-1 then current_state <= 0; end if;
      end case;
    end if;
  end process control_unit;

end rtl;