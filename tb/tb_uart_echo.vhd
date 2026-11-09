library ieee;
use ieee.std_logic_1164.all;

entity tb_uart_echo is
end entity tb_uart_echo;

architecture testbench of tb_uart_echo is
    constant CLK_PERIOD      : time := 10 ns;
    constant CLKS_PER_BIT_TB : positive := 8;
    constant BIT_PERIOD      : time := CLK_PERIOD * CLKS_PER_BIT_TB;

type byte_array_t is array (natural range <>)
    of std_logic_vector(7 downto 0);

constant TEST_BYTES : byte_array_t(0 to 3) := (
    x"00",
    x"FF",
    x"A6",
    x"3C"
);

    signal clk_tb      : std_logic := '0';
    signal rst_tb      : std_logic := '1';
    signal rx_tb       : std_logic := '1';
    signal tx_tb       : std_logic;
    signal overflow_tb : std_logic;

    signal echo_received : boolean := false;
begin
    uut: entity work.uart_echo(rtl)
        generic map (
            CLKS_PER_BIT => CLKS_PER_BIT_TB,
            FIFO_DEPTH   => 4
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

    stim_proc: process
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
begin
    wait for 3 * CLK_PERIOD;

    wait until falling_edge(clk_tb);
    rst_tb <= '0';

    wait for CLK_PERIOD;

    assert tx_tb = '1'
        report "TX should be idle after reset"
        severity error;

    assert overflow_tb = '0'
        report "Overflow should be clear after reset"
        severity error;

    for index in TEST_BYTES'range loop
    send_byte(TEST_BYTES(index));
    end loop;
    wait until echo_received for 40 * BIT_PERIOD;

    assert echo_received
        report "Timeout: expected echo was not received"
        severity error;

    assert overflow_tb = '0'
        report "Unexpected FIFO overflow"
        severity error;

    report "UART_ECHO: all 4 consecutive bytes passed." severity note;
    std.env.finish;
    wait;
end process stim_proc;

monitor_proc: process
begin
    wait until rst_tb = '0';

    for index in TEST_BYTES'range loop
        wait until falling_edge(tx_tb);

        wait for BIT_PERIOD / 2;

        assert tx_tb = '0'
            report "Invalid start for byte " & integer'image(index)
            severity error;

        for bit_index in 0 to 7 loop
            wait for BIT_PERIOD;

            assert tx_tb = TEST_BYTES(index)(bit_index)
                report "Echo mismatch: byte "
                    & integer'image(index)
                    & ", bit "
                    & integer'image(bit_index)
                severity error;
        end loop;

        wait for BIT_PERIOD;

        assert tx_tb = '1'
            report "Invalid stop for byte " & integer'image(index)
            severity error;

        wait for BIT_PERIOD / 2;
    end loop;

wait until falling_edge(tx_tb) for 10 * BIT_PERIOD;

assert tx_tb = '1'
    report "Unexpected extra UART frame after the expected bytes"
    severity error;

echo_received <= true;
wait;
end process monitor_proc;
end architecture testbench;