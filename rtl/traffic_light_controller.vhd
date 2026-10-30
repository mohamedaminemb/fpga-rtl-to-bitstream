library ieee;
use ieee.std_logic_1164.all;

entity traffic_light_controller is
    generic (
        RED_CYCLES    : positive := 3;
        GREEN_CYCLES  : positive := 4;
        YELLOW_CYCLES : positive := 2
    );
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        red_light    : out std_logic;
        green_light  : out std_logic;
        yellow_light : out std_logic
    );
end entity traffic_light_controller;

architecture rtl of traffic_light_controller is
    type state_t is (S_RED, S_GREEN, S_YELLOW);
    signal state_reg : state_t;

    -- Calculer la plus grande durée pour dimensionner le compteur.
    function max_duration (
        red_time    : positive;
        green_time  : positive;
        yellow_time : positive
    ) return positive is
        variable result : positive := red_time;
    begin
        if green_time > result then
            result := green_time;
        end if;

        if yellow_time > result then
            result := yellow_time;
        end if;

        return result;
    end function max_duration;

    constant MAX_CYCLES : positive :=
        max_duration(RED_CYCLES, GREEN_CYCLES, YELLOW_CYCLES);

    signal count_reg : natural range 0 to MAX_CYCLES - 1;
begin
    -- Sorties Moore : elles dépendent uniquement de l'état.
    red_light    <= '1' when state_reg = S_RED else '0';
    green_light  <= '1' when state_reg = S_GREEN else '0';
    yellow_light <= '1' when state_reg = S_YELLOW else '0';

    fsm_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg <= S_RED;
                count_reg <= 0;
            else
                case state_reg is
                    when S_RED =>
                        if count_reg = RED_CYCLES - 1 then
                            state_reg <= S_GREEN;
                            count_reg <= 0;
                        else
                            count_reg <= count_reg + 1;
                        end if;

                    when S_GREEN =>
                        if count_reg = GREEN_CYCLES - 1 then
                            state_reg <= S_YELLOW;
                            count_reg <= 0;
                        else
                            count_reg <= count_reg + 1;
                        end if;

                    when S_YELLOW =>
                        if count_reg = YELLOW_CYCLES - 1 then
                            state_reg <= S_RED;
                            count_reg <= 0;
                        else
                            count_reg <= count_reg + 1;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;
end architecture rtl;