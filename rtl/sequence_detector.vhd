library ieee;
use ieee.std_logic_1164.all;

entity sequence_detector is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        bit_in   : in  std_logic;
        detected : out std_logic
    );
end entity sequence_detector;

architecture rtl of sequence_detector is
    type state_t is (S0, S1, S10, S101);
    signal state_reg : state_t;
begin
    fsm_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg <= S0;
                detected  <= '0';
            else
                -- Par défaut : aucune détection ce cycle.
                detected <= '0';

                case state_reg is
                    when S0 =>
                        if bit_in = '1' then
                            state_reg <= S1;
                        else
                            state_reg <= S0;
                        end if;

                    when S1 =>
                        if bit_in = '0' then
                            state_reg <= S10;
                        else
                            state_reg <= S1;
                        end if;

                    when S10 =>
                        if bit_in = '1' then
                            state_reg <= S101;
                        else
                            state_reg <= S0;
                        end if;

                    when S101 =>
                        if bit_in = '1' then
                            state_reg <= S1;
                            detected  <= '1';
                        else
                            state_reg <= S10;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;
end architecture rtl;