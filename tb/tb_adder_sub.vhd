library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adder_sub is
end entity tb_adder_sub;

architecture testbench of tb_adder_sub is
    constant N_TB : integer := 8;

    signal a_tb   : std_logic_vector(N_TB-1 downto 0) := (others => '0');
    signal b_tb   : std_logic_vector(N_TB-1 downto 0) := (others => '0');
    signal sub_tb : std_logic := '0';
    signal sum_tb : std_logic_vector(N_TB-1 downto 0);
begin

    uut: entity work.adder_sub(rtl)
        generic map ( N => N_TB )
        port map (
            a   => a_tb,
            b   => b_tb,
            sub => sub_tb,
            sum => sum_tb
        );

    stim_proc: process
    begin
        -- Test 1 : Addition 15 + 10 = 25
        sub_tb <= '0';
        a_tb   <= std_logic_vector(to_unsigned(15, N_TB));
        b_tb   <= std_logic_vector(to_unsigned(10, N_TB));
        wait for 10 ns;
        assert sum_tb = std_logic_vector(to_unsigned(25, N_TB))
            report "Test 1 FAILED: 15 + 10 should be 25"
            severity error;

        -- Test 2 : Soustraction 25 - 10 = 15
        sub_tb <= '1';
        a_tb   <= std_logic_vector(to_unsigned(25, N_TB));
        b_tb   <= std_logic_vector(to_unsigned(10, N_TB));
        wait for 10 ns;
        assert sum_tb = std_logic_vector(to_unsigned(15, N_TB))
            report "Test 2 FAILED: 25 - 10 should be 15"
            severity error;

        -- Test 3 : Soustraction 5 - 10 = 251 (complement a 2 sur 8 bits)
        sub_tb <= '1';
        a_tb   <= std_logic_vector(to_unsigned(5, N_TB));
        b_tb   <= std_logic_vector(to_unsigned(10, N_TB));
        wait for 10 ns;
        assert sum_tb = std_logic_vector(to_unsigned(251, N_TB))
            report "Test 3 FAILED: 5 - 10 should wrap to 251 on 8 bits"
            severity error;

        -- Test 4 : Addition avec overflow : 200 + 100 = 44 (mod 256)
        sub_tb <= '0';
        a_tb   <= std_logic_vector(to_unsigned(200, N_TB));
        b_tb   <= std_logic_vector(to_unsigned(100, N_TB));
        wait for 10 ns;
        assert sum_tb = std_logic_vector(to_unsigned(44, N_TB))
            report "Test 4 FAILED: 200 + 100 should wrap to 44 on 8 bits"
            severity error;

        report "All tests passed." severity note;
        wait;
    end process stim_proc;

end architecture testbench;