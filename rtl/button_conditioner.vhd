library ieee;
use ieee.std_logic_1164.all;

entity button_conditioner is
    generic (
        STABLE_CYCLES : positive := 3
    );
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        button_in    : in  std_logic;
        button_clean : out std_logic;
        press_pulse  : out std_logic
    );
end entity button_conditioner;

architecture rtl of button_conditioner is
    signal synced_sig : std_logic;
    signal clean_sig  : std_logic;
begin
    -- Rendre l'état filtré disponible à l'extérieur.
    button_clean <= clean_sig;

    -- 1. Synchroniser l'entrée extérieure.
    u_sync: entity work.sync_2ff(rtl)
        port map (
            clk      => clk,
            rst      => rst,
            async_in => button_in,
            sync_out => synced_sig
        );

    -- 2. Filtrer les changements trop courts.
    u_debounce: entity work.debouncer(rtl)
        generic map (
            STABLE_CYCLES => STABLE_CYCLES
        )
        port map (
            clk       => clk,
            rst       => rst,
            sync_in   => synced_sig,
            clean_out => clean_sig
        );

    -- 3. Produire une impulsion à chaque montée filtrée.
    u_edge: entity work.edge_detector(rtl)
        port map (
            clk        => clk,
            rst        => rst,
            sig_in     => clean_sig,
            rise_pulse => press_pulse
        );
end architecture rtl;