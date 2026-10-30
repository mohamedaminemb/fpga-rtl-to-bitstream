library ieee;
use ieee.std_logic_1164.all;

entity tb_sequence_detector is
end entity tb_sequence_detector;

architecture testbench of tb_sequence_detector is
    constant CLK_PERIOD : time := 10 ns;

    signal clk_tb      : std_logic := '0';
    signal rst_tb      : std_logic := '1';
    signal bit_in_tb   : std_logic := '0';
    signal detected_tb : std_logic;
begin
    uut: entity work.sequence_detector(rtl)
        port map (
            clk      => clk_tb,
            rst      => rst_tb,
            bit_in   => bit_in_tb,
            detected => detected_tb
        );

    clock_proc: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;

        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process clock_proc;

    stim_proc: process
        variable check_count : natural := 0;

        -- Comparer la sortie et compter les vérifications.
        procedure check_output (
            constant expected : in std_logic;
            constant context_message : in string
        ) is
        begin
            assert detected_tb = expected
                report context_message
                    & ": expected=" & std_logic'image(expected)
                    & ", obtained=" & std_logic'image(detected_tb)
                severity error;

            check_count := check_count + 1;
        end procedure check_output;

        -- Appliquer un bit et vérifier la sortie après le front.
        procedure check_bit (
            constant input_value    : in std_logic;
            constant expected_value : in std_logic
        ) is
        begin
            wait until falling_edge(clk_tb);
            bit_in_tb <= input_value;

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_output(
                expected_value,
                "Bit check " & integer'image(check_count + 1)
            );
        end procedure check_bit;

        -- Appliquer une suite de bits avec ses résultats attendus.
        procedure check_stream (
            constant input_bits     : in std_logic_vector;
            constant expected_bits  : in std_logic_vector;
            constant scenario_name  : in string
        ) is
            alias inputs : std_logic_vector(1 to input_bits'length)
                is input_bits;
            alias expected : std_logic_vector(1 to expected_bits'length)
                is expected_bits;
        begin
            assert input_bits'length = expected_bits'length
                report "Testbench error: stream lengths differ"
                severity failure;

            report "Testing: " & scenario_name severity note;

            for i in inputs'range loop
                check_bit(inputs(i), expected(i));
            end loop;
        end procedure check_stream;

        -- Appliquer un reset et vérifier la sortie au front.
        procedure apply_reset is
        begin
            wait until falling_edge(clk_tb);
            rst_tb    <= '1';
            bit_in_tb <= '0';

            wait until rising_edge(clk_tb);
            wait for 1 ns;

            check_output('0', "Reset check");

            wait until falling_edge(clk_tb);
            rst_tb <= '0';
        end procedure apply_reset;
    begin
        -- 1. Aucun motif dans une suite de zéros.
        apply_reset;
        check_stream(
            "0000",
            "0000",
            "No detection on zeros"
        );

        -- 2. Détection simple et disparition de l'impulsion.
        apply_reset;
        check_stream(
            "10110",
            "00010",
            "Single detection and pulse clearing"
        );

        -- 3. Deux détections avec chevauchement.
        apply_reset;
        check_stream(
            "10110110",
            "00010010",
            "Overlapping detections"
        );

        -- 4. Retour de S101 vers S10 :
        apply_reset;
        check_stream(
            "101011",
            "000001",
            "Useful suffix after incomplete match"
        );

        -- 5. Début incorrect et uns successifs.
        apply_reset;
        check_stream(
            "10011011",
            "00000001",
            "Invalid prefix and repeated ones"
        );

        -- 6. Reset au milieu d'une reconnaissance.
        apply_reset;

        check_stream(
            "101",
            "000",
            "Partial sequence before reset"
        );

        -- La FSM est dans S101. Le reset doit l'oublier.
        apply_reset;
        check_stream(
            "1011",
            "0001",
            "Fresh detection after interrupted sequence"
        );

        -- Vérifier la disparition de la dernière impulsion.
        check_bit('0', '0');

        report "SEQUENCE_DETECTOR: all "
            & integer'image(check_count)
            & " checks passed."
            severity note;

        std.env.finish;
    end process stim_proc;
end architecture testbench;