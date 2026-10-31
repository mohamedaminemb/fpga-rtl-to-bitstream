library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fifo_sync is
end entity tb_fifo_sync;

architecture testbench of tb_fifo_sync is
    constant CLK_PERIOD : time := 10 ns;
    constant WIDTH_TB   : positive := 8;
    constant DEPTH_TB   : positive := 4;

    signal clk_tb      : std_logic := '0';
    signal rst_tb      : std_logic := '1';
    signal wr_en_tb    : std_logic := '0';
    signal rd_en_tb    : std_logic := '0';

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

    stim_proc: process
        variable check_count : natural := 0;

        procedure check_outputs (
            constant expected_data  : in natural;
            constant expected_empty : in std_logic;
            constant expected_full  : in std_logic
        ) is
        begin
            assert data_out_tb =
                std_logic_vector(to_unsigned(expected_data, WIDTH_TB))
                report "Data mismatch: expected "
                    & integer'image(expected_data)
                    & ", obtained "
                    & integer'image(to_integer(unsigned(data_out_tb)))
                severity error;

            assert empty_tb = expected_empty
                report "Empty flag mismatch"
                severity error;

            assert full_tb = expected_full
                report "Full flag mismatch"
                severity error;

            check_count := check_count + 3;
        end procedure check_outputs;

        procedure check_cycle (
            constant write_request  : in std_logic;
            constant read_request   : in std_logic;
            constant input_data     : in natural;
            constant expected_data  : in natural;
            constant expected_empty : in std_logic;
            constant expected_full  : in std_logic
        ) is
        begin
            wait until falling_edge(clk_tb);

            wr_en_tb   <= write_request;
            rd_en_tb   <= read_request;
            data_in_tb <=
                std_logic_vector(to_unsigned(input_data, WIDTH_TB));

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_outputs(
                expected_data,
                expected_empty,
                expected_full
            );
        end procedure check_cycle;
    begin
        -- Reset initial : sortie nulle, FIFO vide.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs(0, '1', '0');

        rst_tb <= '0';

        -- Écrire 12 : la sortie de lecture reste à 0.
        check_cycle('1', '0', 12, 0, '0', '0');

        -- Écrire 25 : contenu [12, 25].
        check_cycle('1', '0', 25, 0, '0', '0');

        -- Lire 12 : contenu [25].
        check_cycle('0', '1', 0, 12, '0', '0');

        -- Écrire 7 : contenu [25, 7], sortie toujours à 12.
        check_cycle('1', '0', 7, 12, '0', '0');

        -- Lire 25 : contenu [7].
        check_cycle('0', '1', 0, 25, '0', '0');

        -- Lire 7 : FIFO désormais vide.
        check_cycle('0', '1', 0, 7, '1', '0');

        -- Lecture refusée : sortie conservée à 7.
        check_cycle('0', '1', 0, 7, '1', '0');
        
        -- Remplir la FIFO : [10, 20, 30, 40].
        -- La sortie conserve la dernière donnée lue : 7.
        check_cycle('1', '0', 10, 7, '0', '0');
        check_cycle('1', '0', 20, 7, '0', '0');
        check_cycle('1', '0', 30, 7, '0', '0');
        check_cycle('1', '0', 40, 7, '0', '1');

        -- FIFO pleine : l'écriture de 99 doit être refusée.
        check_cycle('1', '0', 99, 7, '0', '1');

        -- Pleine + deux demandes :
        -- lecture de 10 acceptée, écriture de 88 refusée.
        -- Contenu après : [20, 30, 40].
        check_cycle('1', '1', 88, 10, '0', '0');

        -- Lire 20 : contenu [30, 40].
        check_cycle('0', '1', 0, 20, '0', '0');

        -- Ni pleine ni vide : les deux opérations sont acceptées.
        -- Lire 30 et écrire 50 : contenu [40, 50].
        check_cycle('1', '1', 50, 30, '0', '0');

        -- Vider et vérifier l'ordre des données.
        check_cycle('0', '1', 0, 40, '0', '0');
        check_cycle('0', '1', 0, 50, '1', '0');

        -- Vide + deux demandes :
        -- écriture de 60 acceptée, lecture refusée.
        -- La sortie conserve 50 ; contenu après : [60].
        check_cycle('1', '1', 60, 50, '0', '0');

        -- Lire la donnée au cycle suivant.
        check_cycle('0', '1', 0, 60, '1', '0');

        -- Aucune demande : conserver la sortie et les indicateurs.
        check_cycle('0', '0', 0, 60, '1', '0');

                -- Remplir la FIFO. La dernière donnée lue reste 60.
        check_cycle('1', '0', 70,  60, '0', '0');
        check_cycle('1', '0', 80,  60, '0', '0');
        check_cycle('1', '0', 90,  60, '0', '0');
        check_cycle('1', '0', 100, 60, '0', '1');

        -- Activer le reset entre deux fronts.
        -- Demander aussi une lecture et une écriture.
        wait until falling_edge(clk_tb);
        rst_tb     <= '1';
        wr_en_tb   <= '1';
        rd_en_tb   <= '1';
        data_in_tb <= std_logic_vector(to_unsigned(200, WIDTH_TB));

        wait for 1 ns;

        -- Reset synchrone : aucun changement avant le front montant.
        check_outputs(60, '0', '1');

        -- Au front montant, le reset doit l'emporter.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs(0, '1', '0');

        -- Maintenir le reset : les demandes restent ignorées.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_outputs(0, '1', '0');

        -- Sortir du reset avec une demande de lecture seule.
        wait until falling_edge(clk_tb);
        rst_tb   <= '0';
        wr_en_tb <= '0';
        rd_en_tb <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        -- Aucune ancienne donnée ne doit être accessible.
        check_outputs(0, '1', '0');

        -- Vérifier une nouvelle écriture et sa lecture après reset.
        check_cycle('1', '0', 110, 0,   '0', '0');
        check_cycle('0', '1', 0,   110, '1', '0');

        report "FIFO_SYNC: all "
            & integer'image(check_count)
            & " checks passed."
            severity note;

        std.env.finish;
    end process stim_proc;
end architecture testbench;