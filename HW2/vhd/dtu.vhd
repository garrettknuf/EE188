----------------------------------------------------------------------------
--
--  Data Transfer Unit
--
--  This is an implementation of a data transfer unit for the SH-2 CPU.
--  It handles memory read and write operations for aligned and unaligned
--  accesses with support for different data width (byte, word, long) and
--  data sign modes (signed, unsigned).
--
--  The DTU decodes the access size and uses the address bus to generate
--  the appropriate byte-wise read enable (RE) and write enable (WE) signals
--  and aligns data on the 32-bit bidirectional data bus (DB). For reads, it
--  also performs sign extension for signed byte/word accesses.
--
--  Memory is accessed on the falling edge of the system clock (CLK) to avoid
--  violating setup/hold time contstraints.
--
--  The DTU uses big-endian byte ordering, active-low read and write enable
--  signals, and tri-states the databus when not driving a write.
--
--  Packages included are:
--     DTUConstants - constants for the data transfer unit
--
--  Entities included are:
--     DTU - data transfer unit
--
--  Revision History:
--     14 May 2025  Garrett Knuf    Initial Revision (move from top-level).
--
----------------------------------------------------------------------------

--
-- Package containing constants for the DTU.
--

library ieee;
use ieee.std_logic_1164.all;

package DTUConstants is

    -- DataAccessMode - size of data access (read or write)
    constant DATAACCESSMODE_CNT      : integer := 3;
    constant DataAccessMode_BYTE    : integer range DATAACCESSMODE_CNT-1 downto 0 := 0;
    constant DataAccessMode_WORD    : integer range DATAACCESSMODE_CNT-1 downto 0 := 1;
    constant DataAccessMode_LONG    : integer range DATAACCESSMODE_CNT-1 downto 0 := 2;

    -- DBInMode - when reading either zero-extend or sign-extend data
    constant DBINMODE_CNT       : integer := 2;
    constant DBInMode_Signed    : integer range DBINMODE_CNT-1 downto 0 := 0;
    constant DBInMode_Unsigned  : integer range DBINMODE_CNT-1 downto 0 := 1;

end package;


--
-- DTU
--
-- The Data Transfer Unit (DTU) interfaces the SH-2 CPU with a 32-bit memory system,
-- enabling aligned and unaligned memory accesses for byte, word, and long word data
-- types. It handles data bus direction control, byte-wise memory enables, address
-- decoding for alignment, and sign extension of read data when neccessary.
--
-- On write operations, the DTU aligns the outgoing data (DBOut) to the appropriate
-- byte lanes based on the two least significant bits of the address bus (AB), and
-- active-low byte write enables (WE0-WE3) accordingly. The DB bus is driven with
-- algined output data during writing cycles.
--
-- On read operations, the DTU asserts active-low byte read enables (RE0 - RE3)
-- corresponding to the addressed byte lanes and captures the incoming data from 
-- the DB bus into DBIn. For byte and word reads, it performs sign or zero extension
-- of the result based on the DBInMode input.
--
-- All memory enable signal (WE/RE) are updated on the falling edge of the system
-- clock (CLK) to meet timing constraints. The data bus is tri-stated not actively
-- driving a write.
--
-- Access constraints:
--  Byte accesses are allowed at any address
--  Word accesses require word alignment (AB is multiple of 2)
--  Long accesses require long alignment (AB is multiple of 4)
--
-- Inputs:
--  DBOut           - 32-bit data to output to data bus
--  AB              - 32-bit address bus
--  RD              - read to memory (active low)
--  WR              - write to memory (active high)
--  DataAccessMode  - mode to access data (byte, word, long)
--  CLK             - system clock
--
-- Outputs:
--  DBIn            - 32-bit data read from data bus
--  WE0             - active low write enable to most significant byte
--  WE1             - active low write enable to second most significant byte
--  WE2             - active low write to second least significant byte
--  WE3             - active low write to least significant byte
--  RE0             - active low read enable to most significant byte
--  RE1             - active low read enable to second most significant byte
--  RE2             - active low read to second least significant byte
--  RE3             - active low read to least significant byte
--
-- Input/Outputs:
--  DB          - 32-bit bi-directional data bus
--

library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;
use work.DTUConstants.all;


entity DTU is

    port (
        DBOut           : in    std_logic_vector(DATA_BUS_SIZE-1 downto 0);     -- data to output to DB
        AB              : in    std_logic_vector(DATA_BUS_SIZE-1 downto 0);     -- address bus
        RD              : in    std_logic;                                      -- read enable (active-low)
        WR              : in    std_logic;                                      -- write enable (active-low)
        DataAccessMode  : in    integer range DATAACCESSMODE_CNT-1 downto 0;    -- select byte, word, long access
        DBInMode        : in    integer range DBINMODE_CNT-1 downto 0;          -- select signed or unsigned read
        CLK             : in    std_logic;                                      -- system clock
        DBIn            : out   std_logic_vector(DATA_BUS_SIZE-1 downto 0);     -- data read from DB
        WE0             : out   std_logic;                                      -- write enable byte0
        WE1             : out   std_logic;                                      -- write enable byte1
        WE2             : out   std_logic;                                      -- write enable byte2
        WE3             : out   std_logic;                                      -- write enable byte3
        RE0             : out   std_logic;                                      -- read enable byte0
        RE1             : out   std_logic;                                      -- read enable byte1
        RE2             : out   std_logic;                                      -- read enable byte2
        RE3             : out   std_logic;                                      -- read enable byte3
        DB              : inout std_logic_vector(DATA_BUS_SIZE-1 downto 0)      -- data bus
    );

end DTU;


architecture dataflow of DTU is

    -- Bus for write enables (not clocked)
    signal WE : std_logic_vector(3 downto 0);

    -- Bus for read enables (not clocked)
    signal RE : std_logic_vector(3 downto 0); 

    -- Bit pattern for read or write enables
    signal MemAccessBits : std_logic_vector(3 downto 0);

    -- Intermediate data bus output signal to align bytes
    signal DBOutAligned : std_logic_vector(DATA_BUS_SIZE-1 downto 0);

    -- Bit value to use when sign extending data read
    signal DBSignExtBit : std_logic;

begin

    -- DTU drives DB when outputting and is high impedance otherwise
    DB <= DBOutAligned when WR = '0' else (others => 'Z');

    -- Set bit patterns for read/write enable signals
    process (all)
    begin
        if WR = '0' then
            WE <= MemAccessBits;
            RE <= "1111";
        elsif RD = '0' then
            WE <= "1111";
            RE <= MemAccessBits;
        else
            WE <= "1111";
            RE <= "1111";
        end if;
    end process;

    
    -- Register read/write enable signals
    process (CLK)
    begin

        -- Default disable any memory access
        WE3 <= '1';
        WE2 <= '1';
        WE1 <= '1';
        WE0 <= '1';
        RE3 <= '1';
        RE2 <= '1';
        RE1 <= '1';
        RE0 <= '1';

        -- Only access memory on falling edge of clock to avoid setup time violations.
        if falling_edge(CLK) then
            WE3 <= WE(3);
            WE2 <= WE(2);
            WE1 <= WE(1);
            WE0 <= WE(0);
            RE3 <= RE(3);
            RE2 <= RE(2);
            RE1 <= RE(1);
            RE0 <= RE(0);
        end if;
    end process;


    -- Align DBOut and DBIn based on DataAccessMode and the address bus (AB)
    process (all)
    begin
        case DataAccessMode is

            -- Byte access mode
            when DataAccessMode_Byte =>
                if (AB(1 downto 0) = "11") then
                    DBOutAligned(7 downto 0) <= DBOut(7 downto 0);      -- least significant byte
                    DBIn(7 downto 0) <= DB(7 downto 0);
                    DBSignExtBit <= DB(7);
                    MemAccessBits <= "1110";
                elsif (AB(1 downto 0) = "10") then 
                    DBOutAligned(15 downto 8) <= DBOut(7 downto 0);     -- 2nd least significant byte
                    DBIn(7 downto 0) <= DB(15 downto 8);
                    DBSignExtBit <= DB(15);
                    MemAccessBits <= "1101";
                elsif (AB(1 downto 0) = "01") then
                    DBOutAligned(23 downto 16) <= DBOut(7 downto 0);    -- 2nd most significant byte
                    DBIn(7 downto 0) <= DB(23 downto 16);
                    DBSignExtBit <= DB(23);
                    MemAccessBits <= "1011";
                elsif (AB(1 downto 0) = "00") then 
                    DBOutAligned(31 downto 24) <= DBOut(7 downto 0);    -- most significant byte
                    DBIn(7 downto 0) <= DB(31 downto 24);
                    DBSignExtBit <= DB(31);
                    MemAccessBits <= "0111";
                else
                    DBOutAligned(7 downto 0) <= (others => 'X');        -- invalid addr
                    DBIn(7 downto 0) <= (others => 'X');
                    MemAccessBits <= "1111";
                end if;

                -- Zero extend unsigned values and sign extend signed values
                DBIn(31 downto 8) <= (31 downto 8 => '0')           when DBInMode = DBInMode_Unsigned else
                                     (31 downto 8 => DBSignExtBit)  when DBInMode = DBInMode_Signed else
                                     (31 downto 8 => 'X');

            -- Word access mode
            when DataAccessMode_Word =>
                -- Address must be word aligned (multiple of 2)
                if AB(1 downto 0) = "10" then
                    DBOutAligned(15 downto 0) <= DBOut(15 downto 0);        -- least significant word
                    DBIn(15 downto 0) <= DB(15 downto 0);
                    DBSignExtBit <= DB(15);
                    MemAccessBits <= "1100";
                elsif AB(1 downto 0) = "00" then
                    DBOutAligned(31 downto 16) <= DBOut(15 downto 0);       -- most significant word
                    DBIn(15 downto 0) <= DB(31 downto 16);
                    DBSignExtBit <= DB(31);
                    MemAccessBits <= "0011";
                else
                    DBOutAligned <= (others => 'X');                        -- invalid address
                    MemAccessBits <= "1111";
                end if;

                -- Zero extend unsigned values and sign extend signed values
                DBIn(31 downto 16) <= (31 downto 16 => '0')             when DBInMode = DBInMode_Unsigned else
                                      (31 downto 16 => DBSignExtBit)    when DBInMode = DBInMode_Signed else
                                      (31 downto 16 => 'X');

            -- Long word access mode                                        
            when DataAccessMode_Long =>
                -- Address must be longword aligned (multiple of 4)
                if (AB(1 downto 0) = "00") then
                    DBOutAligned <= DBOut;
                    DBIn <= DB(31 downto 0);
                    MemAccessBits <= "0000";
                else
                    DBOutAligned <= (others => 'X');
                    MemAccessBits <= "1111";
                end if;

            -- Invalid data access mode
            when others =>
                DBOutAligned <= (others => 'X');

        end case;

    end process;
    
end dataflow;
