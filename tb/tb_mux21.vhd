library ieee;
use ieee.std_logic_1164.all;

entity tb_mux21 is
end entity tb_mux21;

architecture testbench of tb_mux21 is 


    signal a_tb : std_logic := '0';
    signal b_tb : std_logic := '0';
    signal sel_tb : std_logic := '0';
    signal y_tb : std_logic;

    begin
        uut: entity work.mux21(rtl)
         port map (
            a => a_tb,
            b => b_tb,
            sel => sel_tb,
            y => y_tb
        );
    stim_proc: process
    procedure check_case (
        constant a_value : in std_logic;
        constant b_value : in std_logic;
        constant sel_value : in std_logic;
        constant expected : in std_logic
    ) is
    begin
        a_tb <= a_value;
        b_tb <= b_value;
        sel_tb <= sel_value;
        wait for 10 ns;
        assert y_tb = expected
        report "MUX incorrect a=" & std_logic'image(a_value) &
                ", b=" & std_logic'image(b_value) &
                ", sel=" & std_logic'image(sel_value) &
                ", attendu=" & std_logic'image(expected) &
                ", obtenu=" & std_logic'image(y_tb)
        severity error;

    end procedure check_case;

     begin
        --          a    b   sel   y attendu
        check_case('0', '0', '0', '0');
        check_case('0', '0', '1', '0');
        check_case('0', '1', '0', '0');
        check_case('0', '1', '1', '1');
        check_case('1', '0', '0', '1');
        check_case('1', '0', '1', '0');
        check_case('1', '1', '0', '1');
        check_case('1', '1', '1', '1');
        

        report "MUX: all 8 binary cases passed." severity note;
        std.env.finish;
    end process stim_proc;
end architecture testbench;