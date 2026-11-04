library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_fifo_sync_vunit is
    generic (
        runner_cfg : string;
        WIDTH_TB   : positive := 8;
        DEPTH_TB   : positive := 4
    );
end entity tb_fifo_sync_vunit;

architecture testbench of tb_fifo_sync_vunit is
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';

    signal wr_en_tb : std_logic := '0';
    signal rd_en_tb : std_logic := '0';

    signal data_in_tb : std_logic_vector(WIDTH_TB-1 downto 0)
        := (others => '0');

    signal data_out_tb : std_logic_vector(WIDTH_TB-1 downto 0);
    signal full_tb    : std_logic;
    signal empty_tb   : std_logic;
begin
    uut: entity work.fifo_sync(rtl)
        generic map (
            WIDTH => WIDTH_TB,
            DEPTH => DEPTH_TB
        )
        port map (
            clk      => clk_tb,
            rst      => rst_tb,
            wr_en    => wr_en_tb,
            rd_en    => rd_en_tb,
            data_in  => data_in_tb,
            data_out => data_out_tb,
            full     => full_tb,
            empty    => empty_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    main: process
        -- Préparer un état initial connu.
        procedure reset_fifo is
        begin
            wait until falling_edge(clk_tb);

            rst_tb     <= '1';
            wr_en_tb   <= '0';
            rd_en_tb   <= '0';
            data_in_tb <= (others => '0');

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            wait until falling_edge(clk_tb);
            rst_tb <= '0';
        end procedure reset_fifo;

        -- Appliquer une opération pendant un cycle.
        procedure apply_cycle (
            constant write_enable : in std_logic;
            constant read_enable  : in std_logic;
            constant input_value  : in natural := 0
        ) is
        begin
            wait until falling_edge(clk_tb);

            wr_en_tb <= write_enable;
            rd_en_tb <= read_enable;

            data_in_tb <= std_logic_vector(
                to_unsigned(input_value, WIDTH_TB)
            );

            wait until rising_edge(clk_tb);
            wait for 1 ns;
        end procedure apply_cycle;

        -- Vérifier les deux drapeaux.
        procedure expect_flags (
            constant expected_empty : in std_logic;
            constant expected_full  : in std_logic
        ) is
        begin
            check_equal(
                empty_tb,
                expected_empty,
                "Unexpected empty flag"
            );

            check_equal(
                full_tb,
                expected_full,
                "Unexpected full flag"
            );
        end procedure expect_flags;

        -- Vérifier la sortie de données.
        procedure expect_data (
            constant expected_value : in natural
        ) is
        begin
            check_equal(
                data_out_tb,
                std_logic_vector(
                    to_unsigned(expected_value, WIDTH_TB)
                ),
                "Unexpected FIFO output value"
            );
        end procedure expect_data;

        -- Lire une donnée et vérifier sa valeur.
        procedure read_expect (
            constant expected_value : in natural
        ) is
        begin
            apply_cycle('0', '1');
            expect_data(expected_value);
        end procedure read_expect;

        -- Remplir une FIFO initialement vide avec 1 à DEPTH_TB.
        procedure fill_fifo is
        begin
            for value in 1 to DEPTH_TB loop
                apply_cycle('1', '0', value);

                if value = DEPTH_TB then
                    expect_flags('0', '1');
                else
                    expect_flags('0', '0');
                end if;
            end loop;
        end procedure fill_fifo;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            reset_fifo;

            if run("reset_empty") then
                expect_flags('1', '0');
                expect_data(0);

            elsif run("fill_reject_write_and_drain") then
                -- Remplir la FIFO.
                fill_fifo;

                -- Une écriture supplémentaire doit être refusée.
                apply_cycle('1', '0', 99);
                expect_flags('0', '1');

                -- Vérifier que les données originales sont intactes.
                for value in 1 to DEPTH_TB loop
                    read_expect(value);

                    if value = DEPTH_TB then
                        expect_flags('1', '0');
                    else
                        expect_flags('0', '0');
                    end if;
                end loop;

                -- Une lecture à vide doit être refusée.
                apply_cycle('0', '1');

                expect_flags('1', '0');
                expect_data(DEPTH_TB);

            elsif run("simultaneous_when_full") then
                fill_fifo;

                -- Pleine avant le front :
                -- lecture acceptée, écriture refusée.
                apply_cycle('1', '1', 99);

                expect_data(1);

                if DEPTH_TB = 1 then
                    expect_flags('1', '0');
                else
                    expect_flags('0', '0');
                end if;

                -- Pour DEPTH=1, cette boucle ne s'exécute pas.
                for value in 2 to DEPTH_TB loop
                    read_expect(value);

                    if value = DEPTH_TB then
                        expect_flags('1', '0');
                    else
                        expect_flags('0', '0');
                    end if;
                end loop;

                expect_flags('1', '0');

            elsif run("simultaneous_when_empty") then
                expect_flags('1', '0');
                expect_data(0);

                -- Vide avant le front :
                -- écriture acceptée, lecture refusée.
                apply_cycle('1', '1', 30);

                -- La lecture refusée ne change pas la sortie.
                expect_data(0);

                if DEPTH_TB = 1 then
                    expect_flags('0', '1');
                else
                    expect_flags('0', '0');
                end if;

                -- La donnée écrite doit être disponible ensuite.
                read_expect(30);
                expect_flags('1', '0');

            elsif run("simultaneous_when_partial") then
                check(
                    DEPTH_TB >= 2,
                    "This scenario requires DEPTH_TB >= 2"
                );

                apply_cycle('1', '0', 10);
                expect_flags('0', '0');

                -- Les deux opérations doivent être acceptées.
                apply_cycle('1', '1', 20);

                expect_data(10);
                expect_flags('0', '0');

                -- Vérifier la donnée écrite simultanément.
                read_expect(20);
                expect_flags('1', '0');

            elsif run("wraparound_with_remaining_data") then
                check(
                    DEPTH_TB >= 2,
                    "This scenario requires DEPTH_TB >= 2"
                );

                -- Exemple DEPTH=3 :
                -- [1, 2, 3]
                fill_fifo;

                -- Lire tout sauf la dernière donnée.
                -- Exemple DEPTH=3 : il reste [3].
                for value in 1 to DEPTH_TB - 1 loop
                    read_expect(value);
                    expect_flags('0', '0');
                end loop;

                -- Réutiliser les emplacements libérés.
                -- Exemple DEPTH=3 : écrire 4 puis 5.
                -- Le contenu devient [3, 4, 5].
                for offset in 1 to DEPTH_TB - 1 loop
                    apply_cycle(
                        '1',
                        '0',
                        DEPTH_TB + offset
                    );

                    if offset = DEPTH_TB - 1 then
                        expect_flags('0', '1');
                    else
                        expect_flags('0', '0');
                    end if;
                end loop;

                -- Vérifier l'ordre après le retour des pointeurs.
                -- Exemple DEPTH=3 : lire 3, 4, 5.
                for value in DEPTH_TB to 2 * DEPTH_TB - 1 loop
                    read_expect(value);

                    if value = 2 * DEPTH_TB - 1 then
                        expect_flags('1', '0');
                    else
                        expect_flags('0', '0');
                    end if;
                end loop;
            end if;
        end loop;

        test_runner_cleanup(runner);
        wait;
    end process main;

    test_runner_watchdog(runner, 10 us);
end architecture testbench;