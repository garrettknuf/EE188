----------------------------------------------------------------------------
--
--  General Purpose Register Set
--
--  This is an implement of a 16 32-bit general purpose register array for the
--  SH-2 CPU. They are numbered R0-R15. R15 is also used as the stack pointer
--  for exception handling. All registers may be used for addressing and may
--  be combined with R0 when generating address. For any given instruction there
--  may be zero, one, or two, register operands. The result of the instruction
--  will generally be returned to one of the register operations. Which registers
--  to use is encoded in the control signals. Note that registers used as
--  addresses may be read and written independently of the ALU accesses. The
--  register array support writing special sources (SR, PR, GBR, VBR) in addition
--  to the ALU result or DAU address output. Special operand operations (sign/zero
--  extension, swaps, shifts, etc.) are also support on the RegB output. This
--  wraps the generic GenericRegArray entity.
--
--  Packages included are:
--     RegArrayConstants - constants for the general purpose registers
--
--  Entities included are:
--     RegArray - program memory access unit
--
--  Revision History:
--     17 Apr 2025  Garrett Knuf    Initial Revision.
--      3 May 2025  George Ore      Add special reg operations.
--      7 May 2025  Garrett Knuf    Move external muxes for RegAxInSel internal.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the general purpose register set.
--

library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;

package RegArrayConstants is

    constant REGARRAY_RegCnt : integer := 16; -- R0-R15
    constant R0     : integer := 0;
    constant R1     : integer := 1;
    constant R2     : integer := 2;
    constant R3     : integer := 3;
    constant R4     : integer := 4;
    constant R5     : integer := 5;
    constant R6     : integer := 6;
    constant R7     : integer := 7;
    constant R8     : integer := 8;
    constant R9     : integer := 9;
    constant R10    : integer := 10;
    constant R11    : integer := 11;
    constant R12    : integer := 12;
    constant R13    : integer := 13;
    constant R14    : integer := 14;
    constant R15    : integer := 15;

    -- RegOp - select special register operations
    constant REGOPSEL_CNT     : integer := 14;
    constant RegOpSel_None    : integer := 0;
    constant RegOpSel_SWAPB   : integer := 1;
    constant RegOpSel_SWAPW   : integer := 2;
    constant RegOpSel_XTRCT   : integer := 3;
    constant RegOpSel_EXTSB   : integer := 4;
    constant RegOpSel_EXTSW   : integer := 5;
    constant RegOpSel_EXTUB   : integer := 6;
    constant RegOpSel_EXTUW   : integer := 7;
    constant RegOpSel_SHLL2   : integer := 8;
    constant RegOpSel_SHLL8   : integer := 9;
    constant RegOpSel_SHLL16  : integer := 10;
    constant RegOpSel_SHLR2   : integer := 11;
    constant RegOpSel_SHLR8   : integer := 12;
    constant RegOpSel_SHLR16  : integer := 13;

    -- RegAxInDataSel - select input to RegAxIn
    constant REGAXINDATASEL_CNT        : integer := 6;
    constant RegAxInDataSel_AddrIDOut  : integer range REGAXINDATASEL_CNT-1 downto 0 := 0;
    constant RegAxInDataSel_DataAddr   : integer range REGAXINDATASEL_CNT-1 downto 0 := 1;
    constant RegAxInDataSel_SR         : integer range REGAXINDATASEL_CNT-1 downto 0 := 2;
    constant RegAxInDataSel_GBR        : integer range REGAXINDATASEL_CNT-1 downto 0 := 3;
    constant RegAxInDataSel_VBR        : integer range REGAXINDATASEL_CNT-1 downto 0 := 4;
    constant RegAxInDataSel_PR         : integer range REGAXINDATASEL_CNT-1 downto 0 := 5;

end package;

--
-- RegArray
--
-- This 32-bit wide register array with 16 general purpose registers implements
-- the generic GenericRegArray for the SH-2 CPU to store data. Data can be output
-- from RegA, RegB, RegA1. Data can be written through RegIn and RegAxIn.
--
--  Inputs:
--    Result     - ALU result
--    DataAddrID - increment/decremented address of DAU
--    DataAddr   - data address of DAU
--    SR         - status register
--    GBR        - global base register
--    VBR        - vector base register
--    PR         - procedure register
--    RegInSel   - which register to write (log regcnt bits)
--    RegStore   - actually write to a register
--    RegASel    - register to read onto bus A (log regcnt bits)
--    RegBSel    - register to read onto bus B (log regcnt bits)
--    RegAxInSel - which address register to write (log regcnt bits - 1)
--    RegAxInDataSel - which data to write into 
--    RegAxStore - actually write to an address register
--    RegA1Sel   - register to read onto address bus 1 (log regcnt bits)
--    ReOpSel    - which special operation to perform if any on RegB
--    CLK        - the system clock
--
--  Outputs:
--    RegA       - register value for bus A
--    RegB       - register value for bus B
--    RegA1      - register value for address bus 1
--

library ieee;
use ieee.std_logic_1164.all;
use work.array_type_pkg.all;
use work.GenericConstants.all;
use work.RegArrayConstants.all;

entity RegArray is

    port (
        -- RegIn input
        Result      : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- ALU Result

        -- RegAxIn inputs
        DataAddrID  : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- DAU inc/dec address
        DataAddr    : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- DAU address
        SR          : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- Status register
        GBR         : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- Global base register
        VBR         : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- Vector base register
        PR          : in   std_logic_vector(LONG_SIZE - 1 downto 0);    -- Procedure register

        -- Control signals
        RegInSel        : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select where to save Result
        RegStore        : in   std_logic;                                       -- decide store result or not
        RegASel         : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select RegA output
        RegBSel         : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select RegB output
        RegAxInSel      : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select where to save RegAxIn input
        RegAxInDataSel  : in   integer range REGAXINDATASEL_CNT - 1 downto 0;   -- select input to RegAxIn
        RegAxStore      : in   std_logic;                                       -- decide store RegAxIn or not
        RegA1Sel        : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select RegA1 output
        RegOpSel        : in   integer range REGOPSEL_CNT - 1 downto 0;         -- select special register operation
        CLK             : in   std_logic;                                       -- system clock

        -- Register Outputs
        RegA            : out  std_logic_vector(REG_SIZE - 1 downto 0);     -- register A
        RegB            : out  std_logic_vector(REG_SIZE - 1 downto 0);     -- register B
        RegA1           : out  std_logic_vector(REG_SIZE - 1 downto 0)      -- register Addr1
    );

end RegArray;


architecture behavioral of RegArray is

    -- Define generic register array that is wrapped
    component GenericRegArray is
        generic (
            regcnt   : integer := REGARRAY_RegCnt;
            wordsize : integer := REG_SIZE
        );
    
        port(
            RegIn      : in   std_logic_vector(wordsize - 1 downto 0);
            RegInSel   : in   integer  range regcnt - 1 downto 0;
            RegStore   : in   std_logic;
            RegASel    : in   integer  range regcnt - 1 downto 0;
            RegBSel    : in   integer  range regcnt - 1 downto 0;
            RegAxIn    : in   std_logic_vector(wordsize - 1 downto 0);
            RegAxInSel : in   integer  range regcnt - 1 downto 0;
            RegAxStore : in   std_logic;
            RegA1Sel   : in   integer  range regcnt - 1 downto 0;
            RegA2Sel   : in   integer  range regcnt - 1 downto 0;
            RegDIn     : in   std_logic_vector(2 * wordsize - 1 downto 0);
            RegDInSel  : in   integer  range regcnt/2 - 1 downto 0;
            RegDStore  : in   std_logic;
            RegDSel    : in   integer  range regcnt/2 - 1 downto 0;
            clock      : in   std_logic;
            RegA       : out  std_logic_vector(wordsize - 1 downto 0);
            RegB       : out  std_logic_vector(wordsize - 1 downto 0);
            RegA1      : out  std_logic_vector(wordsize - 1 downto 0);
            RegA2      : out  std_logic_vector(wordsize - 1 downto 0);
            RegD       : out  std_logic_vector(2 * wordsize - 1 downto 0)
        );
    end component;

    -- Inputs to change register values
    signal RegIn    : std_logic_vector(REG_SIZE - 1 downto 0);
    signal RegAxIn  : std_logic_vector(REG_SIZE - 1 downto 0);

    -- RegB output prior to possible special register operation
    signal RegBRaw  : std_logic_vector(REG_SIZE - 1 downto 0);

begin

    -- First possible value to update is ALU result
    RegIn <= Result;

    -- Second possible set of values to set into a register
    RegAxIn <= DataAddrID   when RegAxInDataSel = RegAxInDataSel_AddrIDOut else 
               DataAddr     when RegAxInDataSel = RegAxInDataSel_DataAddr else
               SR           when RegAxInDataSel = RegAxInDataSel_SR else
               GBR          when RegAxInDataSel = RegAxInDataSel_GBR else
               VBR          when RegAxInDataSel = RegAxInDataSel_VBR else
               PR           when RegAxInDataSel = RegAxInDataSel_PR else
               (others => 'X');

    -- Special register operations
    process(all)
    begin
        case RegOpSel is
            when RegOpSel_None =>
                -- No op
                RegB <= RegBRaw;
            when RegOpSel_SWAPB =>
                -- Swap low two bytes
                RegB <= RegBRaw(31 downto 16) & RegBRaw(7 downto 0) & RegBRaw(15 downto 8);
            when RegOpSel_SWAPW =>
                -- Swap high and low word
                RegB <= RegBRaw(15 downto 0) & RegBRaw(31 downto 16);
            when RegOpSel_XTRCT =>
                -- Use low word of RegB and high word of RegA
                RegB <= RegBRaw(15 downto 0) & RegA(31 downto 16);
            when RegOpSel_EXTSB =>
                -- sign extend byte
                RegB <= (31 downto 8 => RegBRaw(7)) & RegBRaw(7 downto 0);
            when RegOpSel_EXTSW =>
                -- sign extend word
                RegB <= (31 downto 16 => RegBRaw(15)) & RegBRaw(15 downto 0);
            when RegOpSel_EXTUB =>
                -- zero extend byte
                RegB <= (31 downto 8 => '0') & RegBRaw(7 downto 0);
            when RegOpSel_EXTUW =>
                -- zero extend word
                RegB <= (31 downto 16 => '0') & RegBRaw(15 downto 0);
            when RegOpSel_SHLL2 =>
                -- logical shift left by 2
                RegB <= RegBRaw(29 downto 0) & (1 downto 0 => '0');
            when RegOpSel_SHLL8 =>
                -- logical shift left by 8
                RegB <= RegBRaw(23 downto 0) & (7 downto 0 => '0');
            when RegOpSel_SHLL16 =>
                -- logical shift left by 16
                RegB <= RegBRaw(15 downto 0) & (15 downto 0 => '0');
            when RegOpSel_SHLR2 =>
                -- logical shift right by 2
                RegB <= (1 downto 0 => '0') & RegBRaw(31 downto 2);
            when RegOpSel_SHLR8 =>
                -- logical shift right by 8
                RegB <= (7 downto 0 => '0') & RegBRaw(31 downto 8);
            when RegOpSel_SHLR16 =>
                -- logical shift right by 16
                RegB <= (15 downto 0 => '0') & RegBRaw(31 downto 16);
            when others =>
                RegB <= (others => 'X');
        end case;
    end process;

    -- Instantiate generic memory unit
    Generic_RegArray : GenericRegArray

        generic map (
            regcnt => REGARRAY_RegCnt,
            wordsize => REG_SIZE
        )
        port map (
            RegIn => RegIn,
            RegInSel => RegInSel,
            RegStore => RegStore,
            RegASel => RegASel,
            RegBSel => RegBSel,
            RegAxIn => RegAxIn,
            RegAxInSel => RegAxInSel,
            RegAxStore => RegAxStore,
            RegA1Sel => RegA1Sel,
            RegA2Sel => 0,
            RegDIn => (others => '0'),
            RegDInSel => 0,
            RegDStore => '0',
            RegDSel => 0,
            clock => CLK,
            RegA => RegA,
            RegB => RegBRaw,
            RegA1 => RegA1,
            RegA2 => open,
            RegD => open
        );

end behavioral;
