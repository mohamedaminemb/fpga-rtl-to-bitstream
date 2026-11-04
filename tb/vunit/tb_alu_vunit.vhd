library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_alu_vunit is
    generic (
        runner_cfg : string;
        WIDTH_TB   : positive := 4
    );
end entity tb_alu_vunit;

architecture testbench of tb_alu_vunit is
    constant MODULUS   : positive := 2 ** WIDTH_TB;
    constant MAX_VALUE : natural := MODULUS - 1;

    signal a_tb : std_logic_vector(WIDTH_TB-1 downto 0)
        := (others => '0');

    signal b_tb : std_logic_vector(WIDTH_TB-1 downto 0)
        := (others => '0');

    signal op_tb : std_logic_vector(2 downto 0)
        := "000";

    signal result_tb : std_logic_vector(WIDTH_TB-1 downto 0);
    signal zero_tb   : std_logic;
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

    main: process
        procedure check_operation (
            constant opcode         : in natural;
            constant a_value        : in natural;
            constant b_value        : in natural;
            constant expected_value : in natural
        ) is
            variable expected_zero : std_logic;
        begin
            a_tb <= std_logic_vector(
                to_unsigned(a_value, WIDTH_TB)
            );

            b_tb <= std_logic_vector(
                to_unsigned(b_value, WIDTH_TB)
            );

            op_tb <= std_logic_vector(
                to_unsigned(opcode, 3)
            );

            if expected_value = 0 then
                expected_zero := '1';
            else
                expected_zero := '0';
            end if;

            wait for 10 ns;

            check_equal(
                result_tb,
                std_logic_vector(
                    to_unsigned(expected_value, WIDTH_TB)
                ),
                "ALU result mismatch"
            );

            check_equal(
                zero_tb,
                expected_zero,
                "ALU zero flag mismatch"
            );
        end procedure check_operation;
    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            if run("addition") then
                -- 1 + 0 = 1.
                check_operation(0, 1, 0, 1);

            elsif run("subtraction_wrap") then
                -- 0 - 1 modulo 2^WIDTH.
                check_operation(1, 0, 1, MAX_VALUE);

            elsif run("addition_wrap") then
                -- Valeur maximale + 1 = 0.
                check_operation(0, MAX_VALUE, 1, 0);

            elsif run("logical_and") then
                -- Tous les bits à 1 ET tous les bits à 0.
                check_operation(2, MAX_VALUE, 0, 0);

            elsif run("logical_or") then
                -- Tous les bits à 0 OU tous les bits à 1.
                check_operation(3, 0, MAX_VALUE, MAX_VALUE);

            elsif run("logical_xor") then
                -- Deux valeurs identiques donnent zéro.
                check_operation(4, MAX_VALUE, MAX_VALUE, 0);

            elsif run("shift_left") then
                -- Décalage gauche avec perte du bit sortant.
                check_operation(
                    5,
                    MAX_VALUE,
                    0,
                    (MAX_VALUE * 2) mod MODULUS
                );

            elsif run("shift_right") then
                -- Décalage logique droite.
                check_operation(
                    6,
                    MAX_VALUE,
                    0,
                    MAX_VALUE / 2
                );

            elsif run("pass_a") then
                -- Copier a, indépendamment de b.
                check_operation(7, MAX_VALUE, 0, MAX_VALUE);
            end if;
        end loop;

        test_runner_cleanup(runner);
        wait;
    end process main;

    test_runner_watchdog(runner, 1 us);
end architecture testbench;