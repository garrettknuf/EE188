------------------------------------------------------------------------------
--
--  Test Bench for SH-2 CPU.
--
--  This VHDL testbench instantiates the SH2_CPU core along with a 32-bit 
--  addressable 32-bit word memory subsystem (MEMORY32x32). This test applies
--  a reset, generates a clock signal, and loads initial memory 
--  contents from external files via generics, and lets the CPU run, interfacing
--  with memory. The memory files read in should have lines that begin with
--  16-bit binary strings, and they will be stored in memory at sequentially
--  increasing addresses.  After simulation, the memory should dump its contents
--  that can be post-processed to check if testing succeeded.
--
--  The testbench terminates the simulation after a fixed duration.
--
-- Generics:
--   mem0_filepath  -   Path for memory block 0 init file (program memory)
--   mem1_filepath  -   Path for memory block 1 init file (data memory)
--
--  Revision History:
--     17 April 2025    Garrett Knuf    Initial revision.
--     29 April 2025    Garrett Knuf    Add file read-in generics.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.GenericConstants.all;
use work.CUConstants.all;

-- Testbench for SH2_CPU does not contain any ports
-- Generics should be declared as a flag while running (GHLD -r command)
entity tb_sh2_cpu is
    generic (
        mem0_filepath : string := "no_file_provided"; -- file to read memory from
        mem1_filepath : string := "no_file_provided"  -- file to read memory from
    );
end tb_sh2_cpu;

architecture TB_ARCHITECTURE of tb_sh2_cpu is

    -- Component declaration of the tested unit
    component SH2_CPU

        port (
            Reset   :  in     std_logic;                       -- reset signal (active low)
            NMI     :  in     std_logic;                       -- non-maskable interrupt signal (falling edge)
            INT     :  in     std_logic;                       -- maskable interrupt signal (active low)
            clock   :  in     std_logic;                       -- system clock
            AB      :  out    std_logic_vector(31 downto 0);   -- memory address bus
            RE0     :  out    std_logic;                       -- first byte active low read enable
            RE1     :  out    std_logic;                       -- second byte active low read enable
            RE2     :  out    std_logic;                       -- third byte active low read enable
            RE3     :  out    std_logic;                       -- fourth byte active low read enable
            WE0     :  out    std_logic;                       -- first byte active low write enable
            WE1     :  out    std_logic;                       -- second byte active low write enable
            WE2     :  out    std_logic;                       -- third byte active low write enable
            WE3     :  out    std_logic;                       -- fourth byte active low write enable
            DB      :  inout  std_logic_vector(31 downto 0)    -- memory data bus
        );

    end component;

    -- Component declaration of memory subsystem
    component MEMORY32x32
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
            END_SIM : in    std_logic       -- end of simulation
        );
    end component;

    -- Stimulus signals
    signal Reset    : std_logic;
    signal NMI      : std_logic;
    signal INT      : std_logic;
    signal clock    : std_logic;

    -- Observed signals
    signal AB  : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal RE0 : std_logic;
    signal RE1 : std_logic;
    signal RE2 : std_logic;
    signal RE3 : std_logic;
    signal WE0 : std_logic;
    signal WE1 : std_logic;
    signal WE2 : std_logic;
    signal WE3 : std_logic;

    -- Bi-directional signals
    signal DB   : std_logic_vector(31 downto 0);

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

    -- Read/Write enable signals (active-low)
    signal RE : std_logic_vector(3 downto 0);
    signal wE : std_logic_vector(3 downto 0);

begin

    -- Set RW enable signals
    RE <= RE3 & RE2 & RE1 & RE0;
    WE <= WE3 & WE2 & WE1 & WE0;

    -- Unit Under Test port map
    UUT : SH2_CPU
        port map (
            Reset => Reset,
            NMI => NMI,
            INT => INT,
            clock => clock,
            AB => AB,
            RE0 => RE0,
            RE1 => RE1,
            RE2 => RE2,
            RE3 => RE3,
            WE0 => WE0,
            WE1 => WE1,
            WE2 => WE2,
            WE3 => WE3,
            DB => DB
        );

    MUT : MEMORY32x32
        generic map(
            MEMSIZE         => 256,
            START_ADDR0     => 0,
            START_ADDR1     => 256,
            START_ADDR2     => 512,
            START_ADDR3     => 1073741568, -- set to end of 4Gb memory space
                                           -- ((2^32) / 4) - 256 
            MEM_FILEPATH0  => mem0_filepath,
            MEM_FILEPATH1  => mem1_filepath,
            MEM_FILEPATH2  => "memfile2.txt",
            MEM_FILEPATH3  => "memfile3.txt"
        )
        port map (
            RE0 => RE0,
            RE1 => RE1,
            RE2 => RE2,
            RE3 => RE3,
            WE0 => WE0,
            WE1 => WE1,
            WE2 => WE2,
            WE3 => WE3,
            MemAB => AB,
            MemDB => DB,
            END_SIM => END_SIM
        );


    -- Main test loop
    main: process

    begin

        -- Active low reset
        reset <= '0';
        wait for 20 ns;
        reset <= '1';

        -- Run for duration
        wait for 5000 ns;

        -- End of testbench reached
        END_SIM <= '1';

        wait;
    end process;

    -- Clock generation
    process
    begin
        if END_SIM = '0' then
            clock <= '0';
            wait for 10 ns;
        else
            wait;
        end if;

        if END_SIM = '0' then
            clock <= '1';
            wait for 10 ns;
        else
            wait;
        end if;
    end process;


end TB_ARCHITECTURE;