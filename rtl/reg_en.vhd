library ieee;
use ieee.std_logic_1164.all;

entity reg_en is
    generic (
        WIDTH : positive := 8
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        en  : in  std_logic;
        d   : in  std_logic_vector(WIDTH-1 downto 0);
        q   : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity reg_en;

architecture rtl of reg_en is
begin
    register_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                q <= (others => '0');
            elsif en = '1' then
                q <= d;
            end if;
        end if;
    end process register_proc;
end architecture rtl;