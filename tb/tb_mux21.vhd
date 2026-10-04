library ieee;
use ieee.std_logic_1164.all;

entity tb_mux21 is
end entity tb_mux21;

architecture testbench of tb_mux21 is 

    component mux21 is
        port (
            a : in std_logic;
            b : in std_logic;
            sel : in std_logic;
            y : out std_logic
        );
    end component;

    signal a_tb : std_logic := '0';
    signal b_tb : std_logic := '0';
    signal sel_tb : std_logic := '0';
    signal y_tb : std_logic;

    begin
        uut: mux21 port map (
            a => a_tb,
            b => b_tb,
            sel => sel_tb,
            y => y_tb
        );
    stim_proc: process
    begin
        sel_tb <= '0';
        a_tb <= '0';
        b_tb <= '1';
        wait for 10 ns;

        a_tb <= '1';
        wait for 10 ns;

        sel_tb <= '1';
        a_tb <= '0';
        b_tb <= '1';
        wait for 10 ns;

        b_tb <= '0';
        wait for 10 ns;

    
        wait;
    end process stim_proc;
end architecture testbench;