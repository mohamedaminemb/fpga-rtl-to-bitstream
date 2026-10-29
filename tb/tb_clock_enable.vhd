library ieee;
use ieee.std_logic_1164.all;

entity tb_clock_enable is
end entity tb_clock_enable;

architecture testbench of tb_clock_enable is
    constant CLK_PERIOD : time := 10 ns;
    constant DIVISOR_TB : positive := 4;

    signal clk_tb  : std_logic := '0';
    signal rst_tb  : std_logic := '1';
    signal tick_tb : std_logic;
begin
    uut: entity work.clock_enable(rtl)
        generic map (
            DIVISOR => DIVISOR_TB
        )
        port map (
            clk  => clk_tb,
            rst  => rst_tb,
            tick => tick_tb
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
        -- 1. Vérifier le reset initial.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert tick_tb = '0'
            report "Reset failed: tick should be 0"
            severity error;

        -- 2. Désactiver le reset et vérifier le premier cycle.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert tick_tb = '0'
            report "First cycle failed: tick should be 0"
            severity error;

        -- 3. Vérifier les cycles 2 à 8.
        -- Une impulsion est attendue aux cycles 4 et 8.
        for cycle in 2 to 8 loop
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            if cycle mod DIVISOR_TB = 0 then
                assert tick_tb = '1'
                    report "Missing tick at cycle "
                        & integer'image(cycle)
                    severity error;
            else
                assert tick_tb = '0'
                    report "Unexpected tick at cycle "
                        & integer'image(cycle)
                    severity error;
            end if;
        end loop;

        -- 4. Avancer de deux cycles dans la nouvelle période.
        for cycle in 1 to 2 loop
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            assert tick_tb = '0'
                report "Unexpected tick before restart test at cycle "
                    & integer'image(cycle)
                severity error;
        end loop;

        -- 5. Appliquer le reset au milieu de la période.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert tick_tb = '0'
            report "Restart reset failed: tick should be 0"
            severity error;

        -- 6. Désactiver le reset.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        -- 7. Vérifier une période complète après le reset.
        for cycle in 1 to DIVISOR_TB loop
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            if cycle = DIVISOR_TB then
                assert tick_tb = '1'
                    report "Missing tick after restart"
                    severity error;
            else
                assert tick_tb = '0'
                    report "Tick arrived too early after restart at cycle "
                        & integer'image(cycle)
                    severity error;
            end if;
        end loop;

        report "CLOCK_ENABLE: all 16 checks passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;