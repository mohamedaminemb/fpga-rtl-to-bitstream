library ieee;
use ieee.std_logic_1164.all;

entity fifo_sync is
    generic (
        WIDTH : positive := 8;
        DEPTH : positive := 4
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        wr_en    : in  std_logic;
        rd_en    : in  std_logic;
        data_in  : in  std_logic_vector(WIDTH-1 downto 0);
        data_out : out std_logic_vector(WIDTH-1 downto 0);
        full     : out std_logic;
        empty    : out std_logic
    );
end entity fifo_sync;

architecture rtl of fifo_sync is
    type memory_t is array (0 to DEPTH-1)
        of std_logic_vector(WIDTH-1 downto 0);

    signal memory : memory_t;

    signal wr_ptr    : natural range 0 to DEPTH-1;
    signal rd_ptr    : natural range 0 to DEPTH-1;
    signal count_reg : natural range 0 to DEPTH;

    signal write_ok : std_logic;
    signal read_ok  : std_logic;
begin
    empty <= '1' when count_reg = 0 else '0';
    full  <= '1' when count_reg = DEPTH else '0';

    -- Acceptation selon l'occupation avant le front montant.
    write_ok <= '1'
        when wr_en = '1' and count_reg < DEPTH
        else '0';

    read_ok <= '1'
        when rd_en = '1' and count_reg > 0
        else '0';

    fifo_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wr_ptr    <= 0;
                rd_ptr    <= 0;
                count_reg <= 0;
                data_out  <= (others => '0');
            else
                -- Écriture.
                if write_ok = '1' then
                    memory(wr_ptr) <= data_in;

                    if wr_ptr = DEPTH - 1 then
                        wr_ptr <= 0;
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;
                end if;

                -- Lecture enregistrée.
                if read_ok = '1' then
                    data_out <= memory(rd_ptr);

                    if rd_ptr = DEPTH - 1 then
                        rd_ptr <= 0;
                    else
                        rd_ptr <= rd_ptr + 1;
                    end if;
                end if;

                -- Mise à jour de l'occupation.
                if write_ok = '1' and read_ok = '0' then
                    count_reg <= count_reg + 1;
                elsif read_ok = '1' and write_ok = '0' then
                    count_reg <= count_reg - 1;
                end if;
            end if;
        end if;
    end process fifo_proc;
end architecture rtl;