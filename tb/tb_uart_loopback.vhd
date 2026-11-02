library ieee;
use ieee.std_logic_1164.all;

entity tb_uart_loopback is
end entity tb_uart_loopback;

architecture testbench of tb_uart_loopback is
    constant CLK_PERIOD      : time := 10 ns;
    constant CLKS_PER_BIT_TB : positive := 8;
    signal expected_byte : std_logic_vector(7 downto 0) := x"A6";

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';

    signal start_tb   : std_logic := '0';
    signal data_in_tb : std_logic_vector(7 downto 0) := (others => '0');

    signal serial_line : std_logic;
    signal tx_busy_tb  : std_logic;
    signal tx_done_tb  : std_logic;

    signal data_out_tb    : std_logic_vector(7 downto 0);
    signal rx_valid_tb    : std_logic;
    signal frame_error_tb : std_logic;

    signal received_count : natural := 0;
    signal completed_count : natural := 0;
begin
    u_tx: entity work.uart_tx(rtl)
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT_TB
        )
        port map (
            clk     => clk_tb,
            rst     => rst_tb,
            start   => start_tb,
            data_in => data_in_tb,
            tx      => serial_line,
            busy    => tx_busy_tb,
            done    => tx_done_tb
        );

    u_rx: entity work.uart_rx(rtl)
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT_TB
        )
        port map (
            clk         => clk_tb,
            rst         => rst_tb,
            rx          => serial_line,
            data_out    => data_out_tb,
            valid       => rx_valid_tb,
            frame_error => frame_error_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    monitor_proc: process
        variable previous_valid : std_logic := '0';
        variable previous_done  : std_logic := '0';
    begin
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        if rst_tb = '1' then
            received_count  <= 0;
            completed_count <= 0;
            previous_valid  := '0';
            previous_done   := '0';
        else
            if frame_error_tb = '1' then
                report "Unexpected frame error during loopback"
                    severity failure;
            end if;
            if rx_valid_tb = '1' then
                assert data_out_tb = EXPECTED_BYTE
                    report "Loopback data mismatch"
                    severity error;

                assert frame_error_tb = '0'
                    report "Frame error during valid reception"
                    severity error;

                assert previous_valid = '0'
                    report "RX valid lasted more than one cycle"
                    severity error;

                received_count <= received_count + 1;
            end if;

            if tx_done_tb = '1' then
                assert previous_done = '0'
                    report "TX done lasted more than one cycle"
                    severity error;

                completed_count <= completed_count + 1;
            end if;

            previous_valid := rx_valid_tb;
            previous_done  := tx_done_tb;
        end if;
    end process monitor_proc;

    stim_proc: process
        -- Générateur pseudo-aléatoire reproductible.
        variable rng : std_logic_vector(15 downto 0) := x"ACE1";
    begin
        -- Vérifier le reset.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert serial_line = '1'
            report "Reset: serial line should be high"
            severity error;

        assert tx_busy_tb = '0'
            report "Reset: TX should not be busy"
            severity error;

        assert tx_done_tb = '0'
            report "Reset: TX done should be low"
            severity error;

        assert rx_valid_tb = '0'
            report "Reset: RX valid should be low"
            severity error;

        assert frame_error_tb = '0'
            report "Reset: frame error should be low"
            severity error;

        assert data_out_tb = x"00"
            report "Reset: received data should be zero"
            severity error;

        -- Envoyer et vérifier 256 octets successifs.
        for frame in 1 to 256 loop
            -- Faire évoluer le générateur LFSR.
            rng := rng(14 downto 0)
                & (rng(15) xor rng(13) xor rng(12) xor rng(10));

            -- Préparer le nouvel octet et demander son émission.
            wait until falling_edge(clk_tb);
            rst_tb       <= '0';
            expected_byte <= rng(7 downto 0);
            data_in_tb   <= rng(7 downto 0);
            start_tb     <= '1';

            -- La demande traverse un front montant.
            wait until falling_edge(clk_tb);
            start_tb <= '0';

            -- Attente bornée : trame de 80 cycles,
            -- plus une marge pour les contrôles.
            wait for 100 * CLK_PERIOD;

            assert received_count = frame
                report "RX count mismatch after frame "
                    & integer'image(frame)
                severity error;

            assert completed_count = frame
                report "TX count mismatch after frame "
                    & integer'image(frame)
                severity error;

            assert tx_busy_tb = '0'
                report "TX remained busy after frame "
                    & integer'image(frame)
                severity error;

            assert data_out_tb = expected_byte
                report "Final data mismatch after frame "
                    & integer'image(frame)
                severity error;

            assert frame_error_tb = '0'
                report "Frame error after frame "
                    & integer'image(frame)
                severity error;
        end loop;

        report "UART_LOOPBACK: all 256 pseudo-random bytes passed."
            severity note;

        std.env.finish;
    end process stim_proc;
end architecture testbench;