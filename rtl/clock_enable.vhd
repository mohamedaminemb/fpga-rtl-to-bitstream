library ieee;
use ieee.std_logic_1164.all;

entity clock_enable is
    generic (
        DIVISOR : positive := 4
    );
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        tick : out std_logic
    );
end entity clock_enable;

architecture rtl of clock_enable is
    signal count_reg : natural range 0 to DIVISOR - 1;
begin
    tick_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count_reg <= 0;
                tick      <= '0';
            else
                if count_reg = DIVISOR - 1 then
                    count_reg <= 0;
                    tick      <= '1';
                else
                    count_reg <= count_reg + 1;
                    tick      <= '0';
                end if;
            end if;
        end if;
    end process tick_proc;
end architecture rtl;