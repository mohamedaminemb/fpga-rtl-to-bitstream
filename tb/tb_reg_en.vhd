library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_reg_en is
end entity tb_reg_en;

architecture testbench of tb_reg_en is
    constant WIDTH_TB   : positive := 8;
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';
    signal en_tb  : std_logic := '0';

    signal d_tb : std_logic_vector(WIDTH_TB-1 downto 0)
        := (others => '0');
    signal q_tb : std_logic_vector(WIDTH_TB-1 downto 0);
begin
    uut: entity work.reg_en(rtl)
        generic map (
            WIDTH => WIDTH_TB
        )
        port map (
            clk => clk_tb,
            rst => rst_tb,
            en  => en_tb,
            d   => d_tb,
            q   => q_tb
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
        -- Test 1 : reset au premier front montant.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(0, WIDTH_TB))
            report "Test 1 FAILED: reset should clear q"
            severity error;

        -- Test 2 : charger 12 avec enable actif.
        wait until falling_edge(clk_tb);
        rst_tb <= '0';
        en_tb  <= '1';
        d_tb   <= std_logic_vector(to_unsigned(12, WIDTH_TB));

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(12, WIDTH_TB))
            report "Test 2 FAILED: q should load 12"
            severity error;

        -- Test 3 : changer d entre les fronts.
        -- Enable reste actif, mais q doit conserver 12.
        d_tb <= std_logic_vector(to_unsigned(25, WIDTH_TB));
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(12, WIDTH_TB))
            report "Test 3 FAILED: q changed between rising edges"
            severity error;

        -- Test 4 : charger 25 au front montant suivant.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(25, WIDTH_TB))
            report "Test 4 FAILED: q should load 25"
            severity error;

        -- Test 5 : enable inactif, conserver 25.
        wait until falling_edge(clk_tb);
        en_tb <= '0';
        d_tb  <= std_logic_vector(to_unsigned(99, WIDTH_TB));

        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(25, WIDTH_TB))
            report "Test 5 FAILED: q should hold 25 when disabled"
            severity error;

        -- Test 6 : reset synchrone.
        -- Son activation entre les fronts ne doit pas effacer q.
        wait until falling_edge(clk_tb);
        rst_tb <= '1';
        en_tb  <= '1';
        d_tb   <= std_logic_vector(to_unsigned(77, WIDTH_TB));
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(25, WIDTH_TB))
            report "Test 6 FAILED: reset acted before rising edge"
            severity error;

        -- Test 7 : au front montant, reset prioritaire sur enable.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert q_tb = std_logic_vector(to_unsigned(0, WIDTH_TB))
            report "Test 7 FAILED: reset should override enable"
            severity error;

        report "REG_EN: all 7 checks passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;