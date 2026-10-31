library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : positive := 4
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        data_in : in  std_logic_vector(7 downto 0);
        tx      : out std_logic;
        busy    : out std_logic;
        done    : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is
    type state_t is (
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    );

    signal state_reg : state_t;

    signal data_reg : std_logic_vector(7 downto 0);

    signal bit_index : natural range 0 to 7;

    signal baud_count : natural range 0 to CLKS_PER_BIT - 1;
begin
    tx_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg  <= IDLE;
                data_reg   <= (others => '0');
                bit_index  <= 0;
                baud_count <= 0;

                tx   <= '1';
                busy <= '0';
                done <= '0';
            else
                -- done est une impulsion d'un seul cycle.
                done <= '0';

                case state_reg is
                    when IDLE =>
                        tx         <= '1';
                        busy       <= '0';
                        baud_count <= 0;
                        bit_index  <= 0;

                        if start = '1' then
                            data_reg  <= data_in;
                            state_reg <= START_BIT;

                            tx   <= '0';
                            busy <= '1';
                        end if;

                    when START_BIT =>
                        if baud_count = CLKS_PER_BIT - 1 then
                            baud_count <= 0;
                            bit_index  <= 0;
                            state_reg  <= DATA_BITS;

                            tx <= data_reg(0);
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when DATA_BITS =>
                        if baud_count = CLKS_PER_BIT - 1 then
                            baud_count <= 0;

                            if bit_index = 7 then
                                state_reg <= STOP_BIT;
                                tx        <= '1';
                            else
                                bit_index <= bit_index + 1;
                                tx <= data_reg(bit_index + 1);
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when STOP_BIT =>
                        if baud_count = CLKS_PER_BIT - 1 then
                            baud_count <= 0;
                            state_reg  <= IDLE;

                            tx   <= '1';
                            busy <= '0';
                            done <= '1';
                        else
                            baud_count <= baud_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process tx_proc;
end architecture rtl;