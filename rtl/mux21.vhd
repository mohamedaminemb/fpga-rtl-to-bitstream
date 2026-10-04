-- mux21.vhd
library ieee;
use ieee.std_logic_1164.all;

--design entity for 2:1 multiplexer
entity mux21 is
  port (
    a : in std_logic;
    b : in std_logic;
    sel : in std_logic;
    y : out std_logic
  );
end entity mux21;

-- Behavioral architecture
architecture rtl of mux21 is 
begin 
    y <= b when sel = '1' else a;
end architecture rtl;
