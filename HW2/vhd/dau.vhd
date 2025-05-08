----------------------------------------------------------------------------
--
--  Data Memory Access Unit (DAU)
--
--  This is an implementation of a data memory access unit for SH2 CPU. It
--  generates the address and reads or write the data for the data memory.
--  The data memory is address as bytes, words, or long words with 32 bits of
--  address (4 GB total data memory space). Words must be addressed at even
--  addresses and long words can only be accessed at addresses that are multiples
--  of four. The addressing modes are described in the instruction descriptions.
--  It also contains the General Base Register (GBR) that is used in some
--  addressing modes.
--
--  Packages included are:
--     DAUConstants - constants for the data access unit
--
--  Entities included are:
--     DAU - data memory access unit
--
--  Revision History:
--     17 Apr 2025  Garrett Knuf    Initial Revision.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the DAU.
--

library ieee;
use ieee.std_logic_1164.all;

package DAUConstants is
    constant DAU_SRC_CNT    : integer := 6;     -- number of DAU address sources
    constant DAU_OFFSET_CNT : integer := 9;     -- number of DAU offset sources
    constant DAU_MAX_INCDEC_BIT : integer := 2; -- max value for DAU IncDecBit input

    -- Address source mux select
    constant DAU_AddrPC     : integer := 0; -- PC
    constant DAU_AddrPC_LW  : integer := 1; -- PC for long word
    constant DAU_AddrRn     : integer := 2; -- register value
    constant DAU_AddrGBR    : integer := 3; -- GBR
    constant DAU_AddrVBR    : integer := 4; -- VBR
    constant DAU_AddrZero   : integer := 5; -- Zero

    -- Offset source mux select
    constant DAU_OffsetZero : integer := 0; -- zero
    constant DAU_OffsetR0   : integer := 1; -- R0
    constant DAU_Offset4x1  : integer := 2; -- 4-bit offset x 1
    constant DAU_Offset4x2  : integer := 3; -- 4-bit offset x 2
    constant DAU_Offset4x4  : integer := 4; -- 4-bit offset x 4
    constant DAU_Offset8x1  : integer := 5; -- 8-bit offset x 1
    constant DAU_Offset8x2  : integer := 6; -- 8-bit offset x 2
    constant DAU_Offset8x4  : integer := 7; -- 8-bit offset x 4
    constant DAU_OffsetWord : integer := 8; -- word offset (2)

end package;

--
-- DAU
--
-- This is an implemenation of the data memory access unit for the SH-2 CPU.
-- It uses the generic MemUnit to handle many of the data address calculations.
-- It also has the GBR register.
--
-- Inputs:
--  SrcSel      - mux select for address source
--  OffsetSel   - mux select for offset source 
--  Offset4     - 4-bit offset value
--  Offset8     - 8-bit offset value
--  Rn          - general purpose register value
--  R0          - R0 value
--  IncDecSel   - select increment or decrement
--  IncDecBit   - select 1/2/4 for inc/dec value
--  PrePostSel  - select pre/post inc/dec
--  LoadGBR     - update GBR to Rn (1) or hold (0)
--  CLK         - clock
--
-- Outputs:
--  AddrIDOut   - output of address incrementer/decrementer
--  DataAddr    - data address bus
--  GBR         - global base register
--

library ieee;
use ieee.std_logic_1164.all;
use work.array_type_pkg.all;
use work.GenericConstants.all;
use work.MemUnitConstants.all;
use work.DAUConstants.all;

entity DAU is

    port (
        SrcSel      : in    integer range DAU_SRC_CNT - 1 downto 0;
        OffsetSel   : in    integer range DAU_OFFSET_CNT - 1 downto 0;
        Offset4     : in    std_logic_vector(3 downto 0);
        Offset8     : in    std_logic_vector(7 downto 0);
        Rn          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        R0          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        PC          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        IncDecSel   : in    std_logic;
        IncDecBit   : in    integer range 2 downto 0;
        PrePostSel  : in    std_logic;
        LoadGBR     : in    std_logic;
        LoadVBR     : in    std_logic;
        CLK         : in    std_logic;
        RST         : in    std_logic;
        AddrIDOut   : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        DataAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   
        GBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        VBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)
    );

end DAU;


architecture behavioral of DAU is

    component MemUnit is
        generic (
            srcCnt       : integer;
            offsetCnt    : integer;
            maxIncDecBit : integer;
            wordsize     : integer
        );
        port(
            AddrSrc    : in      std_logic_array(srccnt - 1 downto 0)(wordsize - 1 downto 0);
            SrcSel     : in      integer  range srccnt - 1 downto 0;
            AddrOff    : in      std_logic_array(offsetcnt - 1 downto 0)(wordsize - 1 downto 0);
            OffsetSel  : in      integer  range offsetcnt - 1 downto 0;
            IncDecSel  : in      std_logic;
            IncDecBit  : in      integer  range maxIncDecBit downto 0;
            PrePostSel : in      std_logic;
            Address    : out     std_logic_vector(wordsize - 1 downto 0);
            AddrSrcOut : buffer  std_logic_vector(wordsize - 1 downto 0)
        );
    end component;
    
    -- Address mux sources
    signal AddrSrc  : std_logic_array(DAU_SRC_CNT - 1 downto 0)(ADDR_BUS_SIZE - 1 downto 0);

    -- Address offset mux sources
    signal AddrOff  : std_logic_array(DAU_OFFSET_CNT - 1 downto 0)(ADDR_BUS_SIZE - 1 downto 0);

begin

    -- Inputs to address source mux
    AddrSrc(DAU_AddrPC) <= PC;
    AddrSrc(DAU_AddrPC_LW) <= PC and x"FFFFFFFC"; -- mask bottom two bits if long word
    AddrSrc(DAU_AddrRn) <= Rn;
    AddrSrc(DAU_AddrGBR) <= GBR;
    AddrSrc(DAU_AddrZero) <= (others => '0');

    -- Inputs to offset mux
    AddrOff(DAU_OffsetZero) <= (others => '0');
    AddrOff(DAU_OffsetR0) <= R0;
    AddrOff(DAU_Offset4x1) <= (31 downto 4 => '0') & Offset4;
    AddrOff(DAU_Offset4x2) <= (31 downto 5 => '0') & Offset4 & '0';
    AddrOff(DAU_Offset4x4) <= (31 downto 6 => '0') & Offset4 & "00";
    AddrOff(DAU_Offset8x1) <= (31 downto 8 => '0') & Offset8;
    AddrOff(DAU_Offset8x2) <= (31 downto 9 => '0') & Offset8 & '0';
    AddrOff(DAU_Offset8x4) <= (31 downto 10 => '0') & Offset8 & "00";
    AddrOff(DAU_OffsetWord) <= (31 downto 2 => '0') & "10";

    -- Update registers of DAU
    DAU_registers : process (CLK)
    begin
        if rising_edge(CLK) then

            -- Update GBR
            GBR <= Rn when LoadGBR = '1' else GBR;

        end if;
    end process;

    VBR_reset : process (CLK)
    begin
        if rising_edge(CLK) then
            VBR <= (others => '0') when RST = '0' else VBR;
        end if;
    end process;

    -- Instantiate generic memory unit
    Generic_DAU : MemUnit
        generic map (
            srcCnt => DAU_SRC_CNT,              -- number of address sources
            offsetCnt => DAU_OFFSET_CNT,        -- number of offset sources
            maxIncDecBit => DAU_MAX_INCDEC_BIT, -- 1/2/4 possible 
            wordsize => ADDR_BUS_SIZE           -- 32-bit addressing
        )
        port map (
            AddrSrc => AddrSrc,         -- address source
            SrcSel => SrcSel,           -- address source mux select
            AddrOff => AddrOff,         -- offset source
            OffsetSel => OffsetSel,     -- offset source mux select
            IncDecSel => IncDecSel,     -- select inc/dec
            IncDecBit => IncDecBit,     -- size of inc/dec
            PrePostSel => PrePostSel,   -- select pre/post
            Address => DataAddr,        -- address bus
            AddrSrcOut => AddrIDOut     -- output of inc/dec
        );

end behavioral;











