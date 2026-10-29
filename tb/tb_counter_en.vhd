library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_counter_en is
end entity tb_counter_en;

architecture testbench of tb_counter_en is
    constant WIDTH_TB   : positive := 3;
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';
    signal en_tb  : std_logic := '0';
    signal q_tb   : std_logic_vector(WIDTH_TB-1 downto 0);
begin
    uut: entity work.counter_en(rtl)
        generic map (
            WIDTH => WIDTH_TB
        )
        port map (
            clk => clk_tb,
            rst => rst_tb,
            en  => en_tb,
            q   => q_tb
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

        assert q_tb = "000"
            report "Initial reset failed"
            severity error;

        -- 2. Première incrémentation : 0 -> 1.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';
        en_tb  <= '1';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = "001"
            report "First increment failed"
            severity error;

        -- 3. Maintien pendant deux fronts montants.
        wait until falling_edge(clk_tb);
        en_tb <= '0';

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = "001"
            report "Hold failed at first edge"
            severity error;

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = "001"
            report "Hold failed at second edge"
            severity error;

        -- 4. Reprise du comptage : 2, 3, 4, 5, 6, 7.
        wait until falling_edge(clk_tb);
        en_tb <= '1';

        for expected in 2 to 7 loop
            wait until rising_edge(clk_tb);
            wait for 1 ns;

            assert q_tb =
                std_logic_vector(to_unsigned(expected, WIDTH_TB))
                report "Counting failed: expected "
                    & integer'image(expected)
                severity error;
        end loop;

        -- 5. Débordement : 7 -> 0.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = "000"
            report "Wrap-around failed: expected 0 after 7"
            severity error;

        -- 6. Préparer une valeur non nulle pour tester le reset.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = "001"
            report "Setup failed: expected 1 before reset test"
            severity error;

        -- 7. Le reset ne doit pas agir avant le front montant.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';
        en_tb  <= '1';
        wait for 1 ns;

        assert q_tb = "001"
            report "Synchronous reset failed: q changed before rising edge"
            severity error;

        -- 8. Au front montant, le reset est prioritaire.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = "000"
            report "Reset priority failed: expected 0"
            severity error;

        report "COUNTER_EN: all 14 checks passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;