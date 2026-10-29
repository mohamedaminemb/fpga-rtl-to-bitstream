library ieee;
use ieee.std_logic_1164.all;

entity tb_edge_detector is
end entity tb_edge_detector;

architecture testbench of tb_edge_detector is
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb        : std_logic := '0';
    signal rst_tb        : std_logic := '1';
    signal sig_in_tb     : std_logic := '0';
    signal rise_pulse_tb : std_logic;
begin
    uut: entity work.edge_detector(rtl)
        port map (
            clk        => clk_tb,
            rst        => rst_tb,
            sig_in     => sig_in_tb,
            rise_pulse => rise_pulse_tb
        );

    -- Horloge de période 10 ns.
    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    stim_proc: process
    begin
        -- 1. Reset initial.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '0'
            report "Initial reset failed"
            severity error;

        -- 2. Entrée inactive après désactivation du reset.
        wait until falling_edge(clk_tb);
        rst_tb    <= '0';
        sig_in_tb <= '0';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '0'
            report "Idle failed: no rising edge expected"
            severity error;

        -- 3. Première montée de l'entrée.
        wait until falling_edge(clk_tb);
        sig_in_tb <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '1'
            report "First rising edge was not detected"
            severity error;

        -- 4. Une entrée maintenue haute ne doit pas
        -- produire une deuxième impulsion.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '0'
            report "Pulse should last only one cycle"
            severity error;

        -- 5. Une descente ne produit pas d'impulsion.
        wait until falling_edge(clk_tb);
        sig_in_tb <= '0';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '0'
            report "Falling edge must not produce a rising pulse"
            severity error;

        -- 6. Deuxième montée après la descente.
        wait until falling_edge(clk_tb);
        sig_in_tb <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '1'
            report "Second rising edge was not detected"
            severity error;

        -- 7. Activer le reset pendant une impulsion.
        -- Avant le front montant, la sortie reste à 1.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';
        wait for 1 ns;

        assert rise_pulse_tb = '1'
            report "Reset acted before rising clock edge"
            severity error;

        -- 8. Au front montant, le reset efface l'impulsion.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '0'
            report "Reset failed to clear pulse"
            severity error;

        -- 9. Désactiver le reset avec l'entrée encore haute.
        -- previous ayant été remis à 0, une impulsion est attendue.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '1'
            report "High input after reset was not detected"
            severity error;

        -- 10. L'entrée reste haute : l'impulsion doit disparaître.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert rise_pulse_tb = '0'
            report "Pulse should clear while input stays high"
            severity error;

        report "EDGE_DETECTOR: all 10 checks passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;