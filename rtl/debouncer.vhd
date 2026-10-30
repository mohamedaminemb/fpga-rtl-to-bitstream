library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
    generic (
        STABLE_CYCLES : positive := 3
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        sync_in   : in  std_logic;
        clean_out : out std_logic
    );
end entity debouncer;

architecture rtl of debouncer is
    signal count_reg : natural range 0 to STABLE_CYCLES - 1;
    signal clean_reg : std_logic;
begin
    clean_out <= clean_reg;

    debounce_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count_reg <= 0;
                clean_reg <= '0';

            elsif sync_in = clean_reg then
                count_reg <= 0;

            else
                if count_reg = STABLE_CYCLES - 1 then
                    clean_reg <= sync_in;
                    count_reg <= 0;
                else
                    count_reg <= count_reg + 1;
                end if;
            end if;
        end if;
    end process debounce_proc;
end architecture rtl;