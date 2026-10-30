library ieee;
use ieee.std_logic_1164.all;

entity tb_traffic_light_controller is
end entity tb_traffic_light_controller;

architecture testbench of tb_traffic_light_controller is
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';

    signal red_tb    : std_logic;
    signal green_tb  : std_logic;
    signal yellow_tb : std_logic;

    signal red_fast_tb    : std_logic;
    signal green_fast_tb  : std_logic;
    signal yellow_fast_tb : std_logic;

    -- Ordre des bits : rouge, vert, orange.
    subtype lights_t is std_logic_vector(2 downto 0);
    type light_sequence_t is array (natural range <>) of lights_t;

    -- Valeurs après les fronts hors reset.
    constant NORMAL_SEQUENCE : light_sequence_t(0 to 8) := (
        "100", "100",
        "010", "010", "010", "010",
        "001", "001",
        "100"
    );

    constant FAST_SEQUENCE : light_sequence_t(0 to 2) := (
        "010", "001", "100"
    );
begin
    uut_normal: entity work.traffic_light_controller(rtl)
        generic map (
            RED_CYCLES    => 3,
            GREEN_CYCLES  => 4,
            YELLOW_CYCLES => 2
        )
        port map (
            clk          => clk_tb,
            rst          => rst_tb,
            red_light    => red_tb,
            green_light  => green_tb,
            yellow_light => yellow_tb
        );

    uut_fast: entity work.traffic_light_controller(rtl)
        generic map (
            RED_CYCLES    => 1,
            GREEN_CYCLES  => 1,
            YELLOW_CYCLES => 1
        )
        port map (
            clk          => clk_tb,
            rst          => rst_tb,
            red_light    => red_fast_tb,
            green_light  => green_fast_tb,
            yellow_light => yellow_fast_tb
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

        procedure check_lights (
            constant expected_normal : in lights_t;
            constant expected_fast   : in lights_t;
            constant context_message : in string
        ) is
        begin
            assert (red_tb & green_tb & yellow_tb) = expected_normal
                report context_message & ": normal configuration failed"
                severity error;

            assert (red_fast_tb & green_fast_tb & yellow_fast_tb)
                = expected_fast
                report context_message & ": one-cycle configuration failed"
                severity error;

            check_count := check_count + 2;
        end procedure check_lights;

        procedure check_cycle (
            constant cycle_number : in positive
        ) is
        begin
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_lights(
                NORMAL_SEQUENCE((cycle_number - 1) mod 9),
                FAST_SEQUENCE((cycle_number - 1) mod 3),
                "Cycle " & integer'image(cycle_number)
            );
        end procedure check_cycle;
    begin
        -- Reset initial : les deux configurations sont rouges.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_lights("100", "100", "Initial reset");

        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        -- Plusieurs rotations.
        -- Au cycle 21, la configuration normale entre dans GREEN.
        for cycle in 1 to 21 loop
            check_cycle(cycle);
        end loop;

        -- Activer le reset entre deux fronts.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';
        wait for 1 ns;

        -- Le reset synchrone ne doit pas encore agir.
        check_lights("010", "100", "Before reset clock edge");

        -- Au front montant, retour au rouge.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_lights("100", "100", "Reset during operation");

        -- Maintenir le reset pendant un autre front.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        check_lights("100", "100", "Held reset");

        -- Redémarrer : la durée du rouge doit repartir de zéro.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        for cycle in 1 to 9 loop
            check_cycle(cycle);
        end loop;

        report "TRAFFIC_LIGHT_CONTROLLER: all "
            & integer'image(check_count)
            & " checks passed."
            severity note;

        std.env.finish;
    end process stim_proc;
end architecture testbench;