library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_uart_echo_vunit is
    generic (
        runner_cfg   : string;
        FIFO_DEPTH_TB : positive := 4
    );
end entity tb_uart_echo_vunit;

architecture testbench of tb_uart_echo_vunit is
    constant CLK_PERIOD      : time := 10 ns;
    constant CLKS_PER_BIT_TB : positive := 8;
    constant BIT_PERIOD      : time := CLK_PERIOD * CLKS_PER_BIT_TB;

type byte_array_t is array (natural range <>)
    of std_logic_vector(7 downto 0);

constant TEST_BYTES : byte_array_t(0 to 3) := (
    x"A6",
    x"00",
    x"FF",
    x"3C"
);

signal expected_count : positive := 1;

    signal clk_tb      : std_logic := '0';
    signal rst_tb      : std_logic := '1';
    signal rx_tb       : std_logic := '1';
    signal tx_tb       : std_logic;
    signal overflow_tb : std_logic;

    signal echo_received : boolean := false;
    signal check_echo : boolean := false;
begin
    uut: entity work.uart_echo(rtl)
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT_TB,
            FIFO_DEPTH   => FIFO_DEPTH_TB
        )
        port map (
            clk      => clk_tb,
            rst      => rst_tb,
            rx       => rx_tb,
            tx       => tx_tb,
            overflow => overflow_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

 
main: process
    procedure send_byte (
        constant value : in std_logic_vector(7 downto 0)
    ) is
    begin
        rx_tb <= '0';
        wait for BIT_PERIOD;

        for i in 0 to 7 loop
            rx_tb <= value(i);
            wait for BIT_PERIOD;
        end loop;

        rx_tb <= '1';
        wait for BIT_PERIOD;
    end procedure send_byte;

    procedure run_echo_test (
        constant byte_count : in positive
    ) is
    begin
        expected_count <= byte_count;
        check_echo <= true;
        rst_tb <= '1';
        rx_tb  <= '1';

        wait for 3 * CLK_PERIOD;
        wait until falling_edge(clk_tb);
        rst_tb <= '0';

        wait for CLK_PERIOD;

        check_equal(
            tx_tb, '1',
            "TX should be idle after reset"
        );

        check_equal(
            overflow_tb, '0',
            "Overflow should be clear after reset"
        );

        for index in 0 to byte_count - 1 loop
            send_byte(TEST_BYTES(index));
        end loop;

        if not echo_received then
            wait until echo_received for 40 * BIT_PERIOD;
        end if;

        check(
            echo_received,
            "Timeout: expected echoes were not received"
        );

        check_equal(
            overflow_tb, '0',
            "Unexpected FIFO overflow"
        );
    end procedure run_echo_test;
begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
        if run("single_byte") then
            run_echo_test(1);

        elsif run("consecutive_bytes") then
            run_echo_test(TEST_BYTES'length);
        elsif run("overflow_sticky") then
            check_echo <= false;

            check(
                FIFO_DEPTH_TB = 1,
                "This scenario is configured for FIFO_DEPTH_TB = 1"
            );
            rst_tb <= '1';
            rx_tb  <= '1';

            wait for 3 * CLK_PERIOD;
            wait until falling_edge(clk_tb);
            rst_tb <= '0';

            wait for CLK_PERIOD;

            check_equal(
                overflow_tb, '0',
                "Overflow should be clear after reset"
            );

            for index in 1 to 128 loop
                send_byte(x"55");

                exit when overflow_tb = '1';
            end loop;
            wait for 2 * CLK_PERIOD;

            check_equal(
                overflow_tb, '1',
                "Continuous traffic should trigger overflow"
            );

            rx_tb <= '1';
            wait for 30 * BIT_PERIOD;

            check_equal(
                overflow_tb, '1',
                "Overflow should remain set after traffic stops"
            );

            check_equal(
                tx_tb, '1',
                "TX should return to idle after draining"
            );

        elsif run("reset_recovery") then
            check_echo <= false;

            check(
                FIFO_DEPTH_TB = 1,
                "This scenario requires FIFO_DEPTH_TB = 1"
            );

            -- Reset initial.
            rst_tb <= '1';
            rx_tb  <= '1';

            wait for 3 * CLK_PERIOD;
            wait until falling_edge(clk_tb);
            rst_tb <= '0';

            wait for CLK_PERIOD;

            check_equal(
                overflow_tb, '0',
                "Overflow should initially be clear"
            );

            -- Provoquer un débordement.
            for index in 1 to 128 loop
                send_byte(x"55");

                exit when overflow_tb = '1';
            end loop;

            wait for 2 * CLK_PERIOD;

            check_equal(
                overflow_tb, '1',
                "Overflow should be set before recovery"
            );

            -- Arrêter le trafic et laisser finir les émissions.
            rx_tb <= '1';
            wait for 30 * BIT_PERIOD;

            -- Appliquer le reset entre deux fronts montants.
            wait until falling_edge(clk_tb);
            rst_tb <= '1';

            wait for 1 ns;

            check_equal(
                overflow_tb, '1',
                "Synchronous reset should not clear overflow before the edge"
            );

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_equal(
                overflow_tb, '0',
                "Reset should clear overflow at the rising edge"
            );

            check_equal(
                tx_tb, '1',
                "Reset should return TX to idle"
            );

            run_echo_test(1);
        end if;
    end loop;

    test_runner_cleanup(runner);
    wait;
end process main;

monitor_proc: process
begin
    wait until check_echo and rst_tb = '0';

    for index in 0 to expected_count - 1 loop
        wait until falling_edge(tx_tb);
        wait for BIT_PERIOD / 2;

        check_equal(
            tx_tb, '0',
            "Invalid start for byte " & integer'image(index)
        );
        for bit_index in 0 to 7 loop
            wait for BIT_PERIOD;

            check_equal(
                tx_tb,
                TEST_BYTES(index)(bit_index),
                "Echo mismatch: byte "
                    & integer'image(index)
                    & ", bit "
                    & integer'image(bit_index)
            );
        end loop;
        wait for BIT_PERIOD;
        check_equal(
            tx_tb, '1',
            "Invalid stop for byte " & integer'image(index)
        );
        wait for BIT_PERIOD / 2;
    end loop;
    wait until falling_edge(tx_tb) for 10 * BIT_PERIOD;

    check_equal(
        tx_tb, '1',
        "Unexpected extra UART frame"
    );

    echo_received <= true;
    wait;
end process monitor_proc;
    test_runner_watchdog(runner, 200 us);
end architecture testbench;