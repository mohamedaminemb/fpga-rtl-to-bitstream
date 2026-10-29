library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_en is
    generic (
        WIDTH : positive := 8
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        en  : in  std_logic;
        q   : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity counter_en;

architecture rtl of counter_en is
    signal count_reg : unsigned(WIDTH-1 downto 0);
begin
    q <= std_logic_vector(count_reg);
    counter_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count_reg <= (others => '0');
            elsif en = '1' then
                count_reg <= count_reg + 1;
            end if;
        end if;
    end process counter_proc;
end architecture rtl;