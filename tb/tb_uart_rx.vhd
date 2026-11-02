library ieee;
use ieee.std_logic_1164.all;

entity tb_uart_rx is
end entity tb_uart_rx;

architecture testbench of tb_uart_rx is
    constant CLK_PERIOD      : time := 10 ns;
    constant CLKS_PER_BIT_TB : positive := 8;
    constant BIT_PERIOD     : time := CLK_PERIOD * CLKS_PER_BIT_TB;

    constant EXPECTED_BYTE : std_logic_vector(7 downto 0) := x"A6";
    constant ERROR_BYTE : std_logic_vector(7 downto 0) := x"53";

    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';
    signal rx_tb  : std_logic := '1';

    signal data_out_tb    : std_logic_vector(7 downto 0);
    signal valid_tb       : std_logic;
    signal frame_error_tb : std_logic;

    signal received_count : natural := 0;
    signal error_count : natural := 0;
begin
    uut: entity work.uart_rx(rtl)
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT_TB
        )
        port map (
            clk         => clk_tb,
            rst         => rst_tb,
            rx          => rx_tb,
            data_out    => data_out_tb,
            valid       => valid_tb,
            frame_error => frame_error_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    -- Observer valid pendant que le stimulus envoie la trame.
    monitor_proc: process
        variable previous_valid : std_logic := '0';
    begin
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        if rst_tb = '1' then
            received_count <= 0;
            error_count <= 0;
            previous_valid := '0';
        else
            if valid_tb = '1' then
                assert data_out_tb = EXPECTED_BYTE
                    report "Received byte mismatch: expected 0xA6"
                    severity error;

                assert frame_error_tb = '0'
                    report "Unexpected frame error with valid byte"
                    severity error;

                assert previous_valid = '0'
                    report "Valid pulse lasted more than one cycle"
                    severity error;

                received_count <= received_count + 1;
            end if;

            if frame_error_tb = '1' then
                  error_count <= error_count + 1;
            end if;

            previous_valid := valid_tb;
        end if;
    end process monitor_proc;

    stim_proc: process
        -- Générer un bit sur la ligne extérieure.
        procedure send_bit (
            constant value : in std_logic
        ) is
        begin
            rx_tb <= value;
            wait for BIT_PERIOD;
        end procedure send_bit;
    begin
        -- Vérifier le reset.
        wait until rising_edge(clk_tb);
        wait for 1 ns;

        assert data_out_tb = x"00"
            report "Reset failed: data_out should be zero"
            severity error;

        assert valid_tb = '0'
            report "Reset failed: valid should be zero"
            severity error;

        assert frame_error_tb = '0'
            report "Reset failed: frame_error should be zero"
            severity error;

        wait until falling_edge(clk_tb);
        rst_tb <= '0';
        wait for 7 ns;

        -- Bit de start.
        send_bit('0');

        -- Huit bits de données, LSB en premier.
        for bit_index in 0 to 7 loop
            send_bit(EXPECTED_BYTE(bit_index));
        end loop;

        -- Bit de stop.
        send_bit('1');

        -- Maintenir la ligne au repos et laisser finir les contrôles.
        wait for 3 * CLK_PERIOD;

        assert received_count = 1
            report "Expected exactly one received byte"
            severity error;

        assert data_out_tb = EXPECTED_BYTE
            report "Received byte was not preserved"
            severity error;

        assert valid_tb = '0'
            report "Valid did not return to zero"
            severity error;

        assert frame_error_tb = '0'
            report "Unexpected frame error after reception"
            severity error;
        
                -- Faux start : niveau bas pendant seulement une période
        -- d'horloge, au lieu d'une durée complète de bit.
        rx_tb <= '0';
        wait for CLK_PERIOD;

        rx_tb <= '1';
        wait for 2 * BIT_PERIOD;

        -- Aucun nouvel octet ne doit être annoncé.
        assert received_count = 1
            report "False start produced an unexpected valid byte"
            severity error;

        -- Un faux start doit être ignoré, sans erreur de stop.
        assert error_count = 0
            report "False start produced an unexpected frame error"
            severity error;

        -- La dernière donnée valide doit être conservée.
        assert data_out_tb = EXPECTED_BYTE
            report "False start modified the last valid byte"
            severity error;
        
                -- Trame incorrecte : start normal.
        send_bit('0');

        -- Huit bits de données : 0x53, LSB en premier.
        for bit_index in 0 to 7 loop
            send_bit(ERROR_BYTE(bit_index));
        end loop;

        -- Erreur volontaire : stop à 0 au lieu de 1.
        send_bit('0');

        -- Revenir au repos et laisser le RX se stabiliser.
        rx_tb <= '1';
        wait for 2 * BIT_PERIOD;

        assert error_count = 1
            report "Expected exactly one frame error"
            severity error;

        assert received_count = 1
            report "Invalid frame was incorrectly accepted"
            severity error;

        assert data_out_tb = EXPECTED_BYTE
            report "Invalid frame replaced the last valid byte"
            severity error;

        assert valid_tb = '0'
            report "Valid should be inactive after invalid frame"
            severity error;

        assert frame_error_tb = '0'
            report "Frame error did not return to zero"
            severity error;

                -- Nouvelle trame correcte après l'erreur, sans reset.
        send_bit('0');

        for bit_index in 0 to 7 loop
            send_bit(EXPECTED_BYTE(bit_index));
        end loop;

        send_bit('1');

        wait for 3 * CLK_PERIOD;

        -- Une deuxième réception valide doit avoir eu lieu.
        assert received_count = 2
            report "Receiver did not recover after frame error"
            severity error;

        -- La nouvelle trame ne doit pas produire d'erreur.
        assert error_count = 1
            report "Unexpected additional frame error"
            severity error;

        assert data_out_tb = EXPECTED_BYTE
            report "Recovered frame contains incorrect data"
            severity error;

        assert valid_tb = '0'
            report "Valid did not return to zero after recovery"
            severity error;

        assert frame_error_tb = '0'
            report "Frame error remained active after recovery"
            severity error;

        report "UART_RX: all 26 checks passed."
             severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;