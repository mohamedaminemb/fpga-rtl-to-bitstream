library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
    generic (
        CLKS_PER_BIT : positive := 8
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rx          : in  std_logic;
        data_out    : out std_logic_vector(7 downto 0);
        valid       : out std_logic;
        frame_error : out std_logic
    );
end entity uart_rx;

architecture rtl of uart_rx is
    type state_t is (
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT,
        WAIT_IDLE
    );

    constant HALF_BIT_CYCLES : positive := CLKS_PER_BIT / 2;

    signal state_reg : state_t;

    signal rx_stage1 : std_logic;
    signal rx_sync   : std_logic;

    signal data_reg : std_logic_vector(7 downto 0);

    signal bit_index  : natural range 0 to 7;
    signal baud_count : natural range 0 to CLKS_PER_BIT - 1;
begin
    -- Limites de cette première implémentation.
    assert CLKS_PER_BIT >= 4 and CLKS_PER_BIT mod 2 = 0
        report "uart_rx requires an even CLKS_PER_BIT >= 4"
        severity failure;

    -- Synchronisation de l'entrée série.
    sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rx_stage1 <= '1';
                rx_sync   <= '1';
            else
                rx_stage1 <= rx;
                rx_sync   <= rx_stage1;
            end if;
        end if;
    end process sync_proc;

    -- Machine à états de réception.
    rx_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg  <= IDLE;
                baud_count <= 0;
                bit_index  <= 0;
                data_reg   <= (others => '0');

                data_out    <= (others => '0');
                valid       <= '0';
                frame_error <= '0';
            else
                -- Indicateurs actifs pendant un seul cycle.
                valid       <= '0';
                frame_error <= '0';

                case state_reg is
                    when IDLE =>
                        baud_count <= 0;
                        bit_index  <= 0;

                        if rx_sync = '0' then
                            state_reg <= START_BIT;
                            baud_count <= 1;
                        end if;

                    when START_BIT =>
                        if baud_count = HALF_BIT_CYCLES - 1 then
                            baud_count <= 0;

                            if rx_sync = '0' then
                                state_reg <= DATA_BITS;
                                bit_index <= 0;
                            else
                                -- Faux start : retour au repos.
                                state_reg <= IDLE;
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when DATA_BITS =>
                        if baud_count = CLKS_PER_BIT - 1 then
                            baud_count <= 0;

                            -- Placer le bit reçu à sa position.
                            data_reg(bit_index) <= rx_sync;

                            if bit_index = 7 then
                                state_reg <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when STOP_BIT =>
                        if baud_count = CLKS_PER_BIT - 1 then
                            baud_count <= 0;

                            if rx_sync = '1' then
                                data_out  <= data_reg;
                                valid     <= '1';
                                state_reg <= IDLE;
                            else
                                frame_error <= '1';
                                state_reg   <= WAIT_IDLE;
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when WAIT_IDLE =>
                        baud_count <= 0;
                        bit_index  <= 0;

                        if rx_sync = '1' then
                            state_reg <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process rx_proc;
end architecture rtl;