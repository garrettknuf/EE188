----------------------------------------------------------------------------
--
--  Memory Subsystem
--
--  This component describes the memory for a 32-bit byte-addressable CPU
--  with a 32-bit address bus.  Only a portion of the full address space is
--  filled in.  Addresses outside the filled in range return 'X' when read
--  and generate error messages when written.
--
--  Revision History:
--     28 Apr 25  Glen George       Initial revision.
--
----------------------------------------------------------------------------

--
--  MEMORY32x32
--
--  This is a memory component that supports a byte-addressable 32-bit wide
--  memory with 32-bits of address.  No timing restrictions are implemented,
--  but if the address bus changes while a WE signal is active an error is
--  generated.  Only a portion of the memory is actually usable.  Addresses
--  outside of the four usable ranges return 'X' on read and generate error
--  messages on write.  The size and address of each memory chunk are generic
--  parameters.
--
--  Generics:
--    MEMSIZE - size of the four memory blocks in 32-bit words
--    START_ADDR0 - starting address of first memory block/chunk
--    START_ADDR1 - starting address of second memory block/chunk
--    START_ADDR2 - starting address of third memory block/chunk
--    START_ADDR3 - starting address of fourth memory block/chunk
--
--  Inputs:
--    RE0    - low byte read enable (active low)
--    RE1    - byte 1 read enable (active low)
--    RE2    - byte 2 read enable (active low)
--    RE3    - high byte read enable (active low)
--    WE0    - low byte write enable (active low)
--    WE1    - byte 1 write enable (active low)
--    WE2    - byte 2 write enable (active low)
--    WE3    - high byte write enable (active low)
--    MemAB  - memory address bus (32 bits)
--
--  Inputs/Outputs:
--    MemDB  - memory data bus (32 bits)
--

library ieee;
use ieee.std_logic_1164.all;
-- use ieee.std_logic_arith.all;
-- use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity  MEMORY32x32  is

    generic (
        MEMSIZE     : integer := 256;   -- default size is 256 words
        START_ADDR0 : integer;          -- starting address of first block
        START_ADDR1 : integer;          -- starting address of second block
        START_ADDR2 : integer;          -- starting address of third block
        START_ADDR3 : integer;          -- starting address of fourth block
        MEM_FILEPATH0 : string;         -- filepath to first block initial values
        MEM_FILEPATH1 : string;         -- filepath to second block initial values
        MEM_FILEPATH2 : string;         -- filepath to third block initial values
        MEM_FILEPATH3 : string          -- filepath to fourth block initial values
    );

    port (
        RE0    : in     std_logic;      -- low byte read enable (active low)
        RE1    : in     std_logic;      -- byte 1 read enable (active low)
        RE2    : in     std_logic;      -- byte 2 read enable (active low)
        RE3    : in     std_logic;      -- high byte read enable (active low)
        WE0    : in     std_logic;      -- low byte write enable (active low)
        WE1    : in     std_logic;      -- byte 1 write enable (active low)
        WE2    : in     std_logic;      -- byte 2 write enable (active low)
        WE3    : in     std_logic;      -- high byte write enable (active low)
        MemAB  : in     std_logic_vector(31 downto 0);  -- memory address bus
        MemDB  : inout  std_logic_vector(31 downto 0);  -- memory data bus
        END_SIM: in     std_logic       -- end of simulation
    );

end  MEMORY32x32;


architecture  behavioral  of  MEMORY32x32  is

    -- define the type for the RAM chunks
    type  RAMtype  is array (0 to MEMSIZE - 1) of std_logic_vector(31 downto 0);

    -- now define the RAMs (initialized to X)
    signal  RAMbits0  :  RAMtype  := (others => (others => 'X'));
    signal  RAMbits1  :  RAMtype  := (others => (others => 'X'));
    signal  RAMbits2  :  RAMtype  := (others => (others => 'X'));
    signal  RAMbits3  :  RAMtype  := (others => (others => 'X'));

    -- general read and write signals
    signal  RE  :  std_logic;
    signal  WE  :  std_logic;

    file    MEM_FILE0 : text;
    file    MEM_FILE1 : text;
    file    MEM_FILE2 : text;
    file    MEM_FILE3 : text;

begin


    -- compute the general read and write signals (active low signals)
    RE  <=  RE0  and  RE1  and  RE2  and  RE3;
    WE  <=  WE0  and  WE1  and  WE2  and  WE3;

    process
    begin
        -- Read ROM from a file
        file_open(MEM_FILE0, MEM_FILEPATH0, read_mode);
        file_open(MEM_FILE1, MEM_FILEPATH1, read_mode);
        wait;
    end process;

    dump_mem : process

        --
        --
        -- DumpMemToFile
        procedure DumpMemToFile(filename : in string;
                                rambits : in RAMtype) is
            file dump_file : text open write_mode is filename;
            variable dump_line_buf : line;
            variable dump_word_str : string(1 to 16);
            variable addr : integer := 0;
        begin
            while addr < MEMSIZE loop
                dump_word_str(1 to 8) := to_string(rambits(addr)(31 downto 24));
                dump_word_str(9 to 16) := to_string(rambits(addr)(23 downto 16));
                write(dump_line_buf, dump_word_str(1 to 16));
                writeline(dump_file, dump_line_buf);
                dump_word_str(1 to 8) := to_string(rambits(addr)(15 downto 8));
                dump_word_str(9 to 16) := to_string(rambits(addr)(7 downto 0));
                write(dump_line_buf, dump_word_str(1 to 16));
                writeline(dump_file, dump_line_buf);
                addr := addr + 1;
            end loop;
        end procedure;

    begin

        wait until END_SIM = '1';
        
        DumpMemToFile("../asm_tests/mem_dump/dump0.txt", RAMbits0);
        DumpMemToFile("../asm_tests/mem_dump/dump1.txt", RAMbits1);
        DumpMemToFile("../asm_tests/mem_dump/dump2.txt", RAMbits2);
        DumpMemToFile("../asm_tests/mem_dump/dump3.txt", RAMbits3);

    end process;


    process

        --
        -- LoadMemFromFile
        --
        -- This procedure reads a file that contains a 16-bit binary string on
        -- each line and loads it in the specified ram chunk.
        --
        -- @arg mem_file [in] - data structure to store file in
        -- @arg ram_chunk [in] - chunk of RAM to set
        procedure LoadMemFromFile(file mem_file : text;
                                  signal ram_chunk : inout RAMType) is
            variable line_buf1 : line;
            variable line_buf2 : line;
            variable str_buf1 : string(1 to 16);
            variable str_buf2 : string(1 to 16);
            variable ram_index : integer := 0;  -- loop index
        begin

            while not endfile(mem_file) loop
                -- Read two 16-bit binary strings from file
                readline(mem_file, line_buf1);
                readline(mem_file, line_buf2);
                read(line_buf1, str_buf1);
                read(line_buf2, str_buf2);

                -- Convert binary strings to SLV
                for i in 1 to 16 loop

                    -- Convert first binary string
                    if str_buf1(i) = '1' then
                        ram_chunk(ram_index)(32-i) <= '1';
                    elsif str_buf1(i) = '0' then
                        ram_chunk(ram_index)(32-i) <= '0';
                    else
                        ram_chunk(ram_index)(32-i) <= 'X';
                    end if;

                    -- Convert second binary string
                    if str_buf2(i) = '1' then
                        ram_chunk(ram_index)(16-i) <= '1';
                    elsif str_buf2(i) = '0' then
                        ram_chunk(ram_index)(16-i) <= '0';
                    else
                        ram_chunk(ram_index)(16-i) <= 'X';
                    end if;

                end loop;

                -- Move to next address in memory
                ram_index := ram_index + 1;

            end loop;

        end procedure;

        variable files_loaded : std_logic := '0';

        -- data read from memory
        variable  MemData  :  std_logic_vector(31 downto 0);

    begin

        if files_loaded = '0' then
            LoadMemFromFile(MEM_FILE0, RAMbits0);
            LoadMemFromFile(MEM_FILE1, RAMbits1);
            files_loaded := '1';
        end if;

        -- wait for an input to change
        wait on  RE, RE0, RE1, RE2, RE3, WE, WE0, WE1, WE2, WE3, MemAB;

        -- first check if reading
        if  (RE = '0')  then
            -- reading, put the data out (check the address)
            if  (to_integer(unsigned(MemAB)) >= START_ADDR0) and
                 (to_integer(unsigned(MemAB)) - START_ADDR0 < 4 * MEMSIZE)  then
                MemDB <= RAMbits0((to_integer(unsigned(MemAB))/4 - START_ADDR0));
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR1) and
                    (to_integer(unsigned(MemAB)) - START_ADDR1 < 4 * MEMSIZE)  then
                MemDB <= RAMbits1((to_integer(unsigned(MemAB))/4 - START_ADDR1));
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR2) and
                    (to_integer(unsigned(MemAB)) - START_ADDR2 < 4 * MEMSIZE)  then
                MemDB <= RAMbits2((to_integer(unsigned(MemAB))/4 - START_ADDR2));
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR3) and
                    (to_integer(unsigned(MemAB)) - START_ADDR3 < 4 * MEMSIZE)  then
                MemDB <= RAMbits3((to_integer(unsigned(MemAB))/4 - START_ADDR3));
            else
                -- outside of any allowable address range - set output to X
                MemDB <= (others => 'X');
            end if;

            -- only set the bytes that are being read
            if  RE0 /= '0'  then
                MemDB(7 downto 0) <= (others => 'Z');
            end if;
            if  RE1 /= '0'  then
                MemDB(15 downto 8) <= (others => 'Z');
            end if;
            if  RE2 /= '0'  then
                MemDB(23 downto 16) <= (others => 'Z');
            end if;
            if  RE3 /= '0'  then
                MemDB(31 downto 24) <= (others => 'Z');
            end if;

        else

            -- not reading, send data bus to hi-Z
            MemDB <= (others => 'Z');
        end if;

        -- now check if writing
        if  (WE'event and (WE = '0'))  then
            -- rising edge of write - write the data (check which address range)
            -- first get current value of the byte
            if  (to_integer(unsigned(MemAB)) >= START_ADDR0) and
                 (to_integer(unsigned(MemAB)) - START_ADDR0 < 4 * MEMSIZE)  then
                MemData := RAMbits0((to_integer(unsigned(MemAB))/4 - START_ADDR0));
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR1) and
                    (to_integer(unsigned(MemAB)) - START_ADDR1 < 4 * MEMSIZE)  then
                MemData := RAMbits1((to_integer(unsigned(MemAB))/4 - START_ADDR1));
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR2) and
                    (to_integer(unsigned(MemAB)) - START_ADDR2 < 4 * MEMSIZE)  then
                MemData := RAMbits2((to_integer(unsigned(MemAB))/4 - START_ADDR2));
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR3) and
                    (to_integer(unsigned(MemAB)) - START_ADDR3 < 4 * MEMSIZE)  then
                MemData := RAMbits3((to_integer(unsigned(MemAB))/4 - START_ADDR3));
            else
                MemData := (others => 'X');
            end if;

            -- now update the data based on the write enable signals
            -- set any byte being written to its new value
            if  WE0 = '0'  then
                MemData(7 downto 0) := MemDB(7 downto 0);
            end if;
            if  WE1 = '0'  then
                MemData(15 downto 8) := MemDB(15 downto 8);
            end if;
            if  WE2 = '0'  then
                MemData(23 downto 16) := MemDB(23 downto 16);
            end if;
            if  WE3 = '0'  then
                MemData(31 downto 24) := MemDB(31 downto 24);
            end if;

            -- finally write the updated value to memory
            if  (to_integer(unsigned(MemAB)) >= START_ADDR0) and
                 (to_integer(unsigned(MemAB)) - START_ADDR0 < 4 * MEMSIZE)  then
                RAMbits0((to_integer(unsigned(MemAB))/4 - START_ADDR0)) <= MemData;
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR1) and
                    (to_integer(unsigned(MemAB)) - START_ADDR1 < 4 * MEMSIZE)  then
                RAMbits1((to_integer(unsigned(MemAB))/4 - START_ADDR1)) <= MemData;
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR2) and
                    (to_integer(unsigned(MemAB)) - START_ADDR2 < 4 * MEMSIZE)  then
                RAMbits2((to_integer(unsigned(MemAB))/4 - START_ADDR2)) <= MemData;
            elsif  (to_integer(unsigned(MemAB)) >= START_ADDR3) and
                    (to_integer(unsigned(MemAB)) - START_ADDR3 < 4 * MEMSIZE)  then
                RAMbits3((to_integer(unsigned(MemAB))/4 - START_ADDR3)) <= MemData;
            else
                -- outside of any allowable address range - generate an error
                assert (false)
                    report  "Attempt to write to a non-existant address" & integer'image(to_integer(unsigned(MemAB)))
                    severity  ERROR;
            end if;

            -- wait for the update to happen
            wait for 0 ns;

        end if;

        -- finally check if WE low with the address changing
        if  (MemAB'event and (WE = '0'))  then
            -- output error message
            REPORT "Glitch on Data Address bus"
            SEVERITY  ERROR;
        end if;

    end process;


end  behavioral;