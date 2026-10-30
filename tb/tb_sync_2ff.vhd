library ieee;
use ieee.std_logic_1164.all;

entity tb_sync_2ff is
end entity tb_sync_2ff;

architecture testbench of tb_sync_2ff is
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb      : std_logic := '0';
    signal rst_tb      : std_logic := '1';
    signal async_in_tb : std_logic := '0';
    signal sync_out_tb : std_logic;
begin
    uut: entity work.sync_2ff(rtl)
        port map (
            clk      => clk_tb,
            rst      => rst_tb,
            async_in => async_in_tb,
            sync_out => sync_out_tb
        );

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

        assert sync_out_tb = '0'
            report "Initial reset failed"
            severity error;

        -- Désactiver le reset et appliquer une entrée haute.
        wait until falling_edge(clk_tb);
        rst_tb      <= '0';
        async_in_tb <= '1';

        -- 2. Aucun changement avant le prochain front montant.
        wait for 1 ns;

        assert sync_out_tb = '0'
            report "Output changed before rising clock edge"
            severity error;

        -- 3. Premier front : seule la première bascule reçoit 1.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '0'
            report "Rising propagation failed: output rose too early"
            severity error;

        -- 4. Deuxième front : la sortie reçoit 1.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '1'
            report "Rising propagation failed: expected 1 at second edge"
            severity error;

        -- 5. Maintien de la sortie haute.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '1'
            report "High level was not maintained"
            severity error;

        -- Appliquer une entrée basse entre deux fronts.
        wait until falling_edge(clk_tb);
        async_in_tb <= '0';

        -- 6. La sortie ne doit pas changer entre les fronts.
        wait for 1 ns;

        assert sync_out_tb = '1'
            report "Output fell before rising clock edge"
            severity error;

        -- 7. Premier front après la descente : sortie encore haute.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '1'
            report "Falling propagation failed: output fell too early"
            severity error;

        -- 8. Deuxième front après la descente : sortie basse.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '0'
            report "Falling propagation failed: expected 0 at second edge"
            severity error;

        -- Préparer une sortie haute avant de tester le reset.
        wait until falling_edge(clk_tb);
        async_in_tb <= '1';

        wait until rising_edge(clk_tb);
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        -- 9. Vérifier la préparation du scénario.
        assert sync_out_tb = '1'
            report "Reset setup failed: output should be high"
            severity error;

        -- Activer le reset entre deux fronts.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';
        wait for 1 ns;

        -- 10. Le reset synchrone ne doit pas encore agir.
        assert sync_out_tb = '1'
            report "Synchronous reset acted before rising clock edge"
            severity error;

        -- 11. Au front montant, le reset efface la sortie.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '0'
            report "Reset failed to clear output"
            severity error;

        -- Désactiver le reset avec l'entrée toujours haute.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        -- 12. La première bascule a aussi été remise à zéro :
        -- la sortie doit rester basse au premier front hors reset.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '0'
            report "Restart failed: output rose too early"
            severity error;

        -- 13. Au deuxième front, l'entrée haute atteint la sortie.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert sync_out_tb = '1'
            report "Restart failed: high input did not reach output"
            severity error;

        report "SYNC_2FF: all 13 checks passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;