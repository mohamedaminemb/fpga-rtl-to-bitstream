library ieee;
use ieee.std_logic_1164.all;

entity uart_echo is
    generic (
        CLKS_PER_BIT : positive := 8;
        FIFO_DEPTH   : positive := 4
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        rx       : in  std_logic;
        tx       : out std_logic;
        overflow : out std_logic
    );
end entity uart_echo;

architecture rtl of uart_echo is
    signal rx_data   : std_logic_vector(7 downto 0);
    signal fifo_data : std_logic_vector(7 downto 0);

    signal rx_valid   : std_logic;
    signal fifo_empty : std_logic;
    signal fifo_full  : std_logic;
    signal fifo_wr_en : std_logic;
    signal fifo_rd_en : std_logic;
    signal tx_start : std_logic;
    signal tx_busy  : std_logic;
    type state_t is (IDLE, LOAD, SEND, WAIT_TX);
    signal state_reg : state_t;
    signal overflow_reg : std_logic;
begin
overflow <= overflow_reg;
fifo_wr_en <= rx_valid and not fifo_full;
fifo_rd_en <= '1' when state_reg = LOAD and rst = '0' else '0';
tx_start <= '1' when state_reg = SEND and rst = '0' else '0';

fifo_inst: entity work.fifo_sync(rtl)
    generic map (
        WIDTH => 8,
        DEPTH => FIFO_DEPTH
    )
    port map (
        clk      => clk,
        rst      => rst,
        wr_en    => fifo_wr_en,
        rd_en    => fifo_rd_en,
        data_in  => rx_data,
        data_out => fifo_data,
        full     => fifo_full,
        empty    => fifo_empty
    );

rx_inst: entity work.uart_rx(rtl)
    generic map (
        CLKS_PER_BIT => CLKS_PER_BIT
    )
    port map (
        clk         => clk,
        rst         => rst,
        rx          => rx,
        data_out    => rx_data,
        valid       => rx_valid,
        frame_error => open
    );

tx_inst: entity work.uart_tx(rtl)
    generic map (
        CLKS_PER_BIT => CLKS_PER_BIT
    )
    port map (
        clk       => clk,
        rst       => rst,
        data_in   => fifo_data,
        start     => tx_start,
        busy      => tx_busy,
        tx        => tx,
        done      => open
    );

control_proc: process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            state_reg <= IDLE;
        else
            case state_reg is
                when IDLE =>
                    if fifo_empty = '0' and tx_busy = '0' then
                        state_reg <= LOAD;
                    end if;

                when LOAD =>
                    state_reg <= SEND;

                when SEND =>
                    state_reg <= WAIT_TX;

                when WAIT_TX =>
                    if tx_busy = '0' then
                        state_reg <= IDLE;
                    end if;
            end case;
        end if;
    end if;
end process control_proc;

overflow_proc: process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            overflow_reg <= '0';
        elsif rx_valid = '1' and fifo_full = '1' then
            overflow_reg <= '1';
        end if;
    end if;
end process overflow_proc;

end architecture rtl;