------------------------------------------------------------------------------
--
--  Test Bench for SH-2 CPU.
--
--  Tests: None. Just checking for compilation errors.
--
--  Revision History:
--     17 April 2025    Garrett Knuf    Initial revision.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.GenericConstants.all;
use work.CUConstants.all;


library osvvm;
use osvvm.AlertLogPkg.all;

entity tb_sh2_cpu is
end tb_sh2_cpu;

architecture TB_ARCHITECTURE of tb_sh2_cpu is

    -- Component declaration of the tested unit
    component SH2_CPU

        port (
            CLK     : in    std_logic;
            RST     : in    std_logic;
            DB      : inout std_logic_vector(15 downto 0);
            AB      : out   std_logic_vector(31 downto 0);
            RD      : out   std_logic;
            WR      : out   std_logic
        );

    end component;

    -- Stimulus signals
    signal DB   : std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
    signal RST  : std_logic;
    signal CLK  : std_logic;

    -- Observed signals
    signal AB  : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal RD  : std_logic;
    signal WR  : std_logic;

    signal ROM_Data : std_logic_vector(DATA_BUS_SIZE - 1 downto 0);

    constant ZERO_WORD : std_logic_vector(DATA_BUS_SIZE-1 downto 0) := "0000000000000000";

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : SH2_CPU
        port map(
            CLK     => CLK,
            RST     => RST,
            DB      => DB,
            AB      => AB,
            RD      => RD,
            WR      => WR
        );

    -- Data bus control
    databus: process (DB, RD, WR, ROM_Data, AB)
    begin
        DB <= (others =>  'Z')  when WR = '1' else
              ROM_Data          when RD = '1' else
              (others => 'X');

    end process;

    -- Address bus control




    -- Main test loop
    main: process

        -- Set up ROM data structure
        type rom_type is array(0 to 255) of std_logic_vector(15 downto 0);
        variable rom : rom_type := (others => (others => '0'));

        -- Set up loading ROM from a file
        file romfile : text open read_mode is "../testbench/rom_data.txt";
        variable line_buf : line;
        variable str_buf : string(1 to 16);
        variable i : integer := 0;
        file file_ROM : text;

        --
        -- dump_rom_to_file
        --
        -- This procedure dumps the contents of the rom array to rom_dump.txt.
        -- It prints a 16-bit binary string on each line for each word in
        -- ascending order of addresses.
        --
        procedure dump_rom_to_file is
            file dump_file : text open write_mode is "rom_dump.txt";
            variable dump_line_buf : line;
            variable dump_word_str : string(1 to 16);
        begin
            for dump_i in rom'range loop
                for dump_j in 0 to 15 loop
                    if rom(dump_i)(dump_j) = '1' then
                        dump_word_str(15 - dump_j + 1) := '1';
                    elsif rom(dump_i)(dump_j) = '0' then
                        dump_word_str(15 - dump_j + 1) := '0';
                    else
                        dump_word_str(15 - dump_j + 1) := 'X';
                    end if;                    
                end loop;

                write(dump_line_buf, dump_word_str(1 to 16));
                writeline(dump_file, dump_line_buf);
            end loop;
        end procedure;

    begin

        -- Read ROM from a file
        file_open(file_ROM, "../testbench/rom_data.txt", read_mode);

        while not endfile(romfile) loop
            -- Read binary string
            readline(romfile, line_buf);
            read(line_buf, str_buf);

            -- Convert binary string to slv and set in ROM
            for j in 1 to 16 loop
                if str_buf(j) = '1' then
                    rom(i)(16-j) := '1';
                elsif str_buf(j) = '0' then
                    rom(i)(16-j) := '0';
                else
                    rom(i)(16-j) := 'X';
                end if;
            end loop;

            -- Move to next word in ROM
            i := i + 1;
        end loop;

        -- Active low reset
        RST <= '0';
        wait for 20 ns;
        RST <= '1';
        -- ROM_Data <= rom(to_integer(shift_right(unsigned(AB), 1)));

        -- wait for 20 ns;

        -- ROM_Data <= rom(to_integer(shift_right(unsigned(AB), 1)));

        -- wait for 100 ns;

        while (ROM_Data /= ZERO_WORD and RD = '1') loop
            report integer'image(to_integer(shift_right(unsigned(AB), 1)));
            ROM_Data <= rom(to_integer(shift_right(unsigned(AB), 1)));
            wait for 10 ns;
        end loop;

        dump_rom_to_file;

        -- End of testbench reached
        END_SIM <= '1';
        Log("Testbench executed");

        wait;
    end process;

    -- Clock generation
    clock: process
    begin
        if END_SIM = '0' then
            CLK <= '0';
            wait for 10 ns;
        else
            wait;
        end if;

        if END_SIM = '0' then
            CLK <= '1';
            wait for 10 ns;
        else
            wait;
        end if;
    end process;

end TB_ARCHITECTURE;