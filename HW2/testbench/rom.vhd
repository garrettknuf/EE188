library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;  -- For reading the text file

entity ROM is
    port (
        CLK     : in  std_logic;
        AB      : in  std_logic_vector(31 downto 0);
        RD      : in  std_logic;
        DB      : inout std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of ROM is
    type rom_type is array (0 to 255) of std_logic_vector(31 downto 0);
    signal rom : rom_type := (others => (others => '0'));

    signal rom_data : std_logic_vector(31 downto 0);

    function load_rom_from_file(filename : string) return rom_type is
        file romfile : text open read_mode is filename;
        variable line_buf : line;
        variable data_str : string(1 to 32);
        variable rom_tmp : rom_type := (others => (others => '0'));
        variable i : integer := 0;
    begin
        while not endfile(romfile) loop
            readline(romfile, line_buf);
            read(line_buf, data_str);
            rom_tmp(i) := to_stdlogicvector(data_str);
            i := i + 1;
        end loop;
        return rom_tmp;
    end function;

    function to_stdlogicvector(s : string) return std_logic_vector is
        variable res : std_logic_vector(s'length - 1 downto 0);
    begin
        for i in s'range loop
            if s(i) = '1' then
                res(i - s'low) := '1';
            else
                res(i - s'low) := '0';
            end if;
        end loop;
        return res;
    end function;

begin

    -- Load ROM contents once at elaboration/simulation start
    rom <= load_rom_from_file("rom_data.txt");

    process(CLK)
    begin
        if rising_edge(CLK) then
            rom_data <= rom(to_integer(unsigned(AB)));
        end if;
    end process;

    -- Tri-state data bus
    DB <= rom_data when RD = '1' else (others => 'Z');

end architecture;
