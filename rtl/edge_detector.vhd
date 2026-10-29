library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        sig_in     : in  std_logic;
        rise_pulse : out std_logic
    );
end entity edge_detector;

architecture rtl of edge_detector is
    signal previous : std_logic;
begin
    edge_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                previous   <= '0';
                rise_pulse <= '0';
            else
                rise_pulse <= (not previous) and sig_in;
                previous   <= sig_in;
            end if;
        end if;
    end process edge_proc;
end architecture rtl;