library ieee;
use ieee.std_logic_1164.all;

entity sync_2ff is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        async_in : in  std_logic;
        sync_out : out std_logic
    );
end entity sync_2ff;

architecture rtl of sync_2ff is
    signal stage1 : std_logic;
begin
    sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                stage1   <= '0';
                sync_out <= '0';
            else
                stage1   <= async_in;
                sync_out <= stage1;
            end if;
        end if;
    end process sync_proc;
end architecture rtl;