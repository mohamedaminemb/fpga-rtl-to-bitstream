library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu is
    generic (
        WIDTH_TB : positive := 4
    );
end entity tb_alu;

architecture testbench of tb_alu is
    constant MODULUS : positive := 2 ** WIDTH_TB;

    signal a_tb : std_logic_vector(WIDTH_TB-1 downto 0) := (others => '0');
    signal b_tb : std_logic_vector(WIDTH_TB-1 downto 0) := (others => '0');

    signal op_tb : std_logic_vector(2 downto 0) := "000";

    signal result_tb : std_logic_vector(WIDTH_TB-1 downto 0);
    signal zero_tb   : std_logic;

    -- Modèle de référence calculé avec des entiers.
    function reference_result (
        a_value : natural;
        b_value : natural;
        opcode  : natural
    ) return natural is
        variable expected : natural := 0;
        variable a_bit    : natural;
        variable b_bit    : natural;
    begin
        case opcode is
            when 0 =>
                return (a_value + b_value) mod MODULUS;

            when 1 =>
                return (a_value - b_value) mod MODULUS;

            when 2 | 3 | 4 =>
                -- Extraire les bits par division entière.
                for i in 0 to WIDTH_TB - 1 loop
                    a_bit := (a_value / (2 ** i)) mod 2;
                    b_bit := (b_value / (2 ** i)) mod 2;

                    if opcode = 2 then
                        if a_bit = 1 and b_bit = 1 then
                            expected := expected + (2 ** i);
                        end if;

                    elsif opcode = 3 then
                        if a_bit = 1 or b_bit = 1 then
                            expected := expected + (2 ** i);
                        end if;

                    else
                        if a_bit /= b_bit then
                            expected := expected + (2 ** i);
                        end if;
                    end if;
                end loop;

                return expected;

            when 5 =>
                -- Décalage gauche : multiplication par deux,
                -- limitée à la largeur de sortie.
                return (a_value * 2) mod MODULUS;

            when 6 =>
                -- Décalage droite : division entière par deux.
                return a_value / 2;

            when 7 =>
                return a_value;

            when others =>
                return 0;
        end case;
    end function reference_result;
begin
    uut: entity work.alu(rtl)
        generic map (
            WIDTH => WIDTH_TB
        )
        port map (
            a      => a_tb,
            b      => b_tb,
            op     => op_tb,
            result => result_tb,
            zero   => zero_tb
        );

    stim_proc: process
        variable expected      : natural;
        variable expected_zero : std_logic;
        variable case_count    : natural := 0;
        variable check_count   : natural := 0;
    begin
        for opcode in 0 to 7 loop
            for a_value in 0 to MODULUS - 1 loop
                for b_value in 0 to MODULUS - 1 loop
                    a_tb <= std_logic_vector(
                        to_unsigned(a_value, WIDTH_TB)
                    );

                    b_tb <= std_logic_vector(
                        to_unsigned(b_value, WIDTH_TB)
                    );

                    op_tb <= std_logic_vector(
                        to_unsigned(opcode, 3)
                    );

                    expected := reference_result(
                        a_value, b_value, opcode
                    );

                    if expected = 0 then
                        expected_zero := '1';
                    else
                        expected_zero := '0';
                    end if;

                    wait for 10 ns;

                    assert result_tb = std_logic_vector(
                        to_unsigned(expected, WIDTH_TB)
                    )
                        report "ALU result mismatch: op="
                            & integer'image(opcode)
                            & ", a=" & integer'image(a_value)
                            & ", b=" & integer'image(b_value)
                            & ", expected=" & integer'image(expected)
                            & ", obtained="
                            & integer'image(
                                to_integer(unsigned(result_tb))
                            )
                        severity error;

                    assert zero_tb = expected_zero
                        report "ALU zero flag mismatch: op="
                            & integer'image(opcode)
                            & ", a=" & integer'image(a_value)
                            & ", b=" & integer'image(b_value)
                        severity error;

                    case_count  := case_count + 1;
                    check_count := check_count + 2;
                end loop;
            end loop;
        end loop;

        report "ALU: "
            & integer'image(case_count)
            & " cases and "
            & integer'image(check_count)
            & " checks passed for WIDTH="
            & integer'image(WIDTH_TB)
            severity note;

        std.env.finish;
    end process stim_proc;
end architecture testbench;