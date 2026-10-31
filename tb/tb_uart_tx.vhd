library ieee;
use ieee.std_logic_1164.all;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture testbench of tb_uart_tx is
    constant CLK_PERIOD      : time := 10 ns;
    constant CLKS_PER_BIT_TB : positive := 4;

    -- Trame de 0xA6 :
    -- start, b0 à b7, stop.
    constant EXPECTED_FRAME : std_logic_vector(0 to 9)
        := "0011001011";

    signal clk_tb   : std_logic := '0';
    signal rst_tb   : std_logic := '1';
    signal start_tb : std_logic := '0';

    signal data_in_tb : std_logic_vector(7 downto 0) := x"A6";

    signal tx_tb   : std_logic;
    signal busy_tb : std_logic;
    signal done_tb : std_logic;
begin
    uut: entity work.uart_tx(rtl)
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT_TB
        )
        port map (
            clk     => clk_tb,
            rst     => rst_tb,
            start   => start_tb,
            data_in => data_in_tb,
            tx      => tx_tb,
            busy    => busy_tb,
            done    => done_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    stim_proc: process
        variable check_count : natural := 0;

        procedure check_outputs (
            constant expected_tx   : in std_logic;
            constant expected_busy : in std_logic;
            constant expected_done : in std_logic;
            constant context_message : in string
        ) is
        begin
            assert tx_tb = expected_tx
                report context_message
                    & ": tx expected=" & std_logic'image(expected_tx)
                    & ", obtained=" & std_logic'image(tx_tb)
                severity error;

            assert busy_tb = expected_busy
                report context_message & ": busy mismatch"
                severity error;

            assert done_tb = expected_done
                report context_message & ": done mismatch"
                severity error;

            check_count := check_count + 3;
        end procedure check_outputs;
    begin
        -- 1. Reset : ligne au repos, émetteur disponible.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs('1', '0', '0', "Initial reset");

        -- 2. Demander l'envoi de 0xA6.
        wait until falling_edge(clk_tb);
        rst_tb   <= '0';
        start_tb <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        -- Ce front est l'origine temporelle de la trame.
        check_outputs('0', '1', '0', "Transmission accepted");

        -- Modifier l'entrée après acceptation :
        -- le module doit continuer à transmettre la copie de 0xA6.
        data_in_tb <= x"53";

        -- 3. Vérifier les 40 périodes de la trame.
        for elapsed in 1 to 10 * CLKS_PER_BIT_TB loop
            wait until falling_edge(clk_tb);

            -- Injecter une demande pendant busy.
            -- Elle doit être ignorée, sans mise en attente.
            if elapsed = 8 then
                start_tb <= '1';
            else
                start_tb <= '0';
            end if;

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            if elapsed < 10 * CLKS_PER_BIT_TB then
                check_outputs(
                    EXPECTED_FRAME(elapsed / CLKS_PER_BIT_TB),
                    '1',
                    '0',
                    "Transmission cycle " & integer'image(elapsed)
                );
            else
                -- Fin de la durée complète du bit de stop.
                check_outputs(
                    '1', '0', '1',
                    "Transmission complete"
                );
            end if;
        end loop;

        -- 4. done doit disparaître et aucune demande ignorée
        -- ne doit déclencher une nouvelle transmission.
        for cycle in 1 to 4 loop
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_outputs(
                '1', '0', '0',
                "Idle after transmission " & integer'image(cycle)
            );
        end loop;

                -- Commencer une nouvelle transmission avec 0x00.
        wait until falling_edge(clk_tb);
        data_in_tb <= x"00";
        start_tb   <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs('0', '1', '0', "Frame before reset accepted");

        -- Avancer dans la transmission.
        -- Avec 0x00, le start et tous les bits de données valent 0.
        for cycle in 1 to 7 loop
            wait until falling_edge(clk_tb);
            start_tb <= '0';

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_outputs(
                '0', '1', '0',
                "Before reset cycle " & integer'image(cycle)
            );
        end loop;

        -- Activer le reset entre deux fronts.
        -- Ajouter une demande pour vérifier la priorité du reset.
        wait until falling_edge(clk_tb);
        rst_tb     <= '1';
        start_tb   <= '1';
        data_in_tb <= x"FF";
        wait for 1 ns;

        -- Aucun effet immédiat : le reset est synchrone.
        check_outputs('0', '1', '0', "Before reset clock edge");

        -- Au front montant, la transmission est annulée.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs('1', '0', '0', "Reset during transmission");

        -- Le reset maintenu doit ignorer start.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs('1', '0', '0', "Held reset with start active");

        -- Désactiver reset et start.
        wait until falling_edge(clk_tb);
        rst_tb   <= '0';
        start_tb <= '0';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs('1', '0', '0', "Idle after reset");

        -- La trame interrompue ne doit pas reprendre.
        for cycle in 1 to 2 loop
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_outputs(
                '1', '0', '0',
                "No automatic restart " & integer'image(cycle)
            );
        end loop;

        report "UART_TX: all "
            & integer'image(check_count)
            & " checks passed."
            severity note;

        std.env.finish;
    end process stim_proc;
end architecture testbench;