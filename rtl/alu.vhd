library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (
        WIDTH : positive := 8
    );
    port (
        a      : in  std_logic_vector(WIDTH-1 downto 0);
        b      : in  std_logic_vector(WIDTH-1 downto 0);
        op     : in  std_logic_vector(2 downto 0);
        result : out std_logic_vector(WIDTH-1 downto 0);
        zero   : out std_logic
    );
end entity alu;

architecture rtl of alu is
    signal result_int : std_logic_vector(WIDTH-1 downto 0);
begin
    operation_proc: process(all)
    begin
        case op is
            when "000" =>
                result_int <= std_logic_vector(unsigned(a) + unsigned(b));

            when "001" =>
                result_int <= std_logic_vector(unsigned(a) - unsigned(b));

            when "010" =>
                result_int <= a and b;

            when "011" =>
                result_int <= a or b;

            when "100" =>
                result_int <= a xor b;

            when "101" =>
                result_int <=
                    std_logic_vector(shift_left(unsigned(a), 1));

            when "110" =>
                result_int <=
                    std_logic_vector(shift_right(unsigned(a), 1));

            when "111" =>
                result_int <= a;

            when others =>
                result_int <= (others => '0');
        end case;
    end process operation_proc;

    result <= result_int;

    zero <= '1'
        when unsigned(result_int) = 0
        else '0';
end architecture rtl;