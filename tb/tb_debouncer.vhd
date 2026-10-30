library ieee;
use ieee.std_logic_1164.all;

entity tb_debouncer is
end entity tb_debouncer;

architecture testbench of tb_debouncer is
    constant CLK_PERIOD      : time := 10 ns;
    constant STABLE_CYCLES_TB : positive := 3;

    signal clk_tb       : std_logic := '0';
    signal rst_tb       : std_logic := '1';
    signal sync_in_tb   : std_logic := '0';
    signal clean_out_tb : std_logic;
begin
    uut: entity work.debouncer(rtl)
        generic map (
            STABLE_CYCLES => STABLE_CYCLES_TB
        )
        port map (
            clk       => clk_tb,
            rst       => rst_tb,
            sync_in   => sync_in_tb,
            clean_out => clean_out_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    stim_proc: process
        -- Appliquer une entrée avant le prochain front montant,
        -- puis comparer la sortie à la valeur attendue.
        procedure check_sample (
            constant input_value    : in std_logic;
            constant expected_value : in std_logic
        ) is
        begin
            wait until falling_edge(clk_tb);
            sync_in_tb <= input_value;

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            assert clean_out_tb = expected_value
                report "Debouncer mismatch: input="
                    & std_logic'image(input_value)
                    & ", expected="
                    & std_logic'image(expected_value)
                    & ", obtained="
                    & std_logic'image(clean_out_tb)
                severity error;
        end procedure check_sample;
    begin
        -- 1 vérification : reset initial.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert clean_out_tb = '0'
            report "Initial reset failed"
            severity error;

        -- Désactiver le reset après la vérification.
        rst_tb <= '0';

        -- 4 vérifications : rejeter une impulsion trop courte.
        report "Testing short pulse rejection" severity note;

        check_sample('1', '0');
        check_sample('1', '0');
        check_sample('0', '0');
        check_sample('0', '0');

        -- 7 vérifications : montée avec rebond.
        report "Testing rising transition with bounce" severity note;

        check_sample('1', '0');
        check_sample('0', '0');
        check_sample('1', '0');
        check_sample('1', '0');
        check_sample('1', '1');
        check_sample('0', '1');
        check_sample('1', '1');

        -- 7 vérifications : descente avec rebond.
        report "Testing falling transition with bounce" severity note;

        check_sample('0', '1');
        check_sample('0', '1');
        check_sample('1', '1');
        check_sample('0', '1');
        check_sample('0', '1');
        check_sample('0', '0');
        check_sample('0', '0');

        -- 2 vérifications : commencer une montée sans l'accepter.
        report "Testing reset during pending transition" severity note;

        check_sample('1', '0');
        check_sample('1', '0');

        -- 1 vérification : appliquer le reset.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert clean_out_tb = '0'
            report "Reset during pending transition failed"
            severity error;

        -- Désactiver le reset en conservant l'entrée haute.
        rst_tb <= '0';

        -- 3 vérifications : une nouvelle attente complète
        check_sample('1', '0');
        check_sample('1', '0');
        check_sample('1', '1');

        report "DEBOUNCER: all 25 checks passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;