library ieee;
use ieee.std_logic_1164.all;

entity tb_button_conditioner is
end entity tb_button_conditioner;

architecture testbench of tb_button_conditioner is
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb          : std_logic := '0';
    signal rst_tb          : std_logic := '1';
    signal button_in_tb    : std_logic := '0';
    signal button_clean_tb : std_logic;
    signal press_pulse_tb  : std_logic;
begin
    uut: entity work.button_conditioner(rtl)
        generic map (
            STABLE_CYCLES => 3
        )
        port map (
            clk          => clk_tb,
            rst          => rst_tb,
            button_in    => button_in_tb,
            button_clean => button_clean_tb,
            press_pulse  => press_pulse_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    stim_proc: process
        procedure check_cycle (
            constant input_value    : in std_logic;
            constant expected_clean : in std_logic;
            constant expected_pulse : in std_logic
        ) is
        begin
            wait until falling_edge(clk_tb);
            button_in_tb <= input_value;

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            assert button_clean_tb = expected_clean
                report "Filtered state mismatch: expected "
                    & std_logic'image(expected_clean)
                    & ", obtained "
                    & std_logic'image(button_clean_tb)
                severity error;

            assert press_pulse_tb = expected_pulse
                report "Press pulse mismatch: expected "
                    & std_logic'image(expected_pulse)
                    & ", obtained "
                    & std_logic'image(press_pulse_tb)
                severity error;
        end procedure check_cycle;
    begin
        -- Reset initial : vérifier les deux sorties.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert button_clean_tb = '0'
            report "Reset failed: filtered state should be 0"
            severity error;

        assert press_pulse_tb = '0'
            report "Reset failed: press pulse should be 0"
            severity error;

        rst_tb <= '0';

        -- Appui propre maintenu pendant sept cycles.
        --          entrée, état filtré, impulsion
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '1', '0');
        check_cycle('1', '1', '1');
        check_cycle('1', '1', '0');

                -- Maintien : état filtré haut, aucune nouvelle impulsion.
        for cycle in 1 to 5 loop
            check_cycle('1', '1', '0');
        end loop;

        -- Relâchement propre.
        check_cycle('0', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '0', '0');
        check_cycle('0', '0', '0');
        check_cycle('0', '0', '0');

        -- Deuxième appui propre : une nouvelle impulsion.
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '1', '0');
        check_cycle('1', '1', '1');
        check_cycle('1', '1', '0');

                -- Relâchement avec rebond : 0, 1, puis 0 stable.
        -- Le premier zéro ne doit pas être accepté.
        check_cycle('0', '1', '0');
        check_cycle('1', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '1', '0');
        check_cycle('0', '0', '0');
        check_cycle('0', '0', '0');

        -- Appui avec rebond : 1, 0, puis 1 stable.
        -- Une seule impulsion doit être produite.
        check_cycle('1', '0', '0');
        check_cycle('0', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '0', '0');
        check_cycle('1', '1', '0');
        check_cycle('1', '1', '1');
        check_cycle('1', '1', '0');

        report "BUTTON_CONDITIONER: all 88 checks passed."
            severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;