library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_sub is
    generic(
        N : integer := 8
    );
    port(
        a   : in  std_logic_vector(N-1 downto 0);
        b   : in  std_logic_vector(N-1 downto 0);
        sub : in  std_logic; -- 0: add, 1: sub
        sum : out std_logic_vector(N-1 downto 0)
    );
end entity adder_sub;

architecture rtl of adder_sub is
    signal a_uns   : unsigned(N-1 downto 0);
    signal b_uns   : unsigned(N-1 downto 0);
    signal res_uns : unsigned(N-1 downto 0);
begin
    a_uns <= unsigned(a);
    b_uns <= unsigned(b);

    res_uns <= a_uns - b_uns when sub = '1' else a_uns + b_uns;

    sum <= std_logic_vector(res_uns);

end architecture rtl;