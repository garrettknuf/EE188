----------------------------------------------------------------------------
--
--  General Purpose Register Set
--
--  This is an implementation of 16 32-bit general purpose registers for the
--  SH-2 CPU. They are numbered R0-R15. R15 is also used as the stack pointer
--  for exception handling. All registers may be used for addressing and may
--  be combined with R0 when generating address. For any given instruction there
--  may be zero, one, or two, register operands. The result of the instruction
--  will generally be returned to one of the register operations. Which registers
--  to use is encoded in the control signals. Note that registers used as
--  addresses may be read and written independently of the ALU accesses.
--
--  Packages included are:
--     RegArrayConstants - constants for the general purpose registers
--
--  Entities included are:
--     RegArray - program memory access unit
--
--  Revision History:
--     17 Apr 2025  Garrett Knuf    Initial Revision.
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
-- This is an implementation of 32-bit register array with 16 registers. All
-- registers may be used for addressing and may be combined with R0 when generating
-- addresses. The registers used as address may be read and written independently
-- of the ALU accesses. It uses the GenericRegArray entity and removes the double
-- data size features to consolidate register array interface for SH2 specifically.
--
--  Inputs:
--    RegIn      - input bus to the registers
--    RegInSel   - which register to write (log regcnt bits)
--    RegStore   - actually write to a register
--    RegASel    - register to read onto bus A (log regcnt bits)
--    RegBSel    - register to read onto bus B (log regcnt bits)
--    RegAxIn    - input bus for address register updates
--    RegAxInSel - which address register to write (log regcnt bits - 1)
--    RegAxStore - actually write to an address register
--    RegA1Sel   - register to read onto address bus 1 (log regcnt bits)
--    RegA2Sel   - register to read onto address bus 2 (log regcnt bits)
--    CLK        - the system clock
--
--  Outputs:
--    RegA       - register value for bus A
--    RegB       - register value for bus B
--    RegA1      - register value for address bus 1
--    RegA2      - register value for address bus 2
--

library ieee;
use ieee.std_logic_1164.all;
use work.array_type_pkg.all;
use work.GenericConstants.all;
use work.RegArrayConstants.all;

entity RegArray is

    port (
        -- RegIn inputs
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
        RegStore        : in   std_logic;                                   -- decide store result or not
        RegASel         : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select RegA output
        RegBSel         : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select RegB output
        RegAxInSel      : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select where to save RegAxIn input
        RegAxInDataSel  : in   integer range REGAXINDATASEL_CNT - 1 downto 0;  -- select input to RegAxIn
        RegAxStore      : in   std_logic;                                   -- decide store RegAxIn or not
        RegA1Sel        : in   integer range REGARRAY_RegCnt - 1 downto 0;      -- select RegA1 output
        RegOpSel        : in   integer range REGOPSEL_CNT - 1 downto 0;        -- select special register operation
        CLK             : in   std_logic;                                   -- system clock

        -- Register Outputs
        RegA            : out  std_logic_vector(REG_SIZE - 1 downto 0);     -- register A
        RegB            : out  std_logic_vector(REG_SIZE - 1 downto 0);     -- register B
        RegA1           : out  std_logic_vector(REG_SIZE - 1 downto 0)      -- register Addr1
    );

end RegArray;


architecture behavioral of RegArray is

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


    signal RegIn    : std_logic_vector(REG_SIZE - 1 downto 0);
    signal RegAxIn  : std_logic_vector(REG_SIZE - 1 downto 0);

    -- RegB output prior to possible special register operation
    signal RegBRaw  : std_logic_vector(REG_SIZE - 1 downto 0);

    -- Unused signals
    signal RegA2      : std_logic_vector(REG_SIZE - 1 downto 0);
    signal RegA2Sel   : integer  range REGARRAY_RegCnt - 1 downto 0; 
    signal RegDIn     : std_logic_vector(2 * REG_SIZE - 1 downto 0);
    signal RegDInSel  : integer  range REGARRAY_RegCnt/2 - 1 downto 0;
    signal RegDStore  : std_logic;
    signal RegDSel    : integer  range REGARRAY_RegCnt/2 - 1 downto 0;
    signal RegD       : std_logic_vector(2 * REG_SIZE - 1 downto 0);

begin

    RegIn <= Result;

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
                RegB <= RegBRaw;
            when RegOpSel_SWAPB =>
                RegB <= RegBRaw(31 downto 16) & RegBRaw(7 downto 0) & RegBRaw(15 downto 8);
            when RegOpSel_SWAPW =>
                RegB <= RegBRaw(15 downto 0) & RegBRaw(31 downto 16);
            when RegOpSel_XTRCT =>
                RegB <= RegBRaw(15 downto 0) & RegA(31 downto 16);
            when RegOpSel_EXTSB =>
                RegB <= (31 downto 8 => RegBRaw(7)) & RegBRaw(7 downto 0);
            when RegOpSel_EXTSW =>
                RegB <= (31 downto 16 => RegBRaw(15)) & RegBRaw(15 downto 0);
            when RegOpSel_EXTUB =>
                RegB <= (31 downto 8 => '0') & RegBRaw(7 downto 0);
            when RegOpSel_EXTUW =>
                RegB <= (31 downto 16 => '0') & RegBRaw(15 downto 0);
            when RegOpSel_SHLL2 =>
                RegB <= RegBRaw(29 downto 0) & (1 downto 0 => '0');
            when RegOpSel_SHLL8 =>
                RegB <= RegBRaw(23 downto 0) & (7 downto 0 => '0');
            when RegOpSel_SHLL16 =>
                RegB <= RegBRaw(15 downto 0) & (15 downto 0 => '0');
            when RegOpSel_SHLR2 =>
                RegB <= (1 downto 0 => '0') & RegBRaw(31 downto 2);
            when RegOpSel_SHLR8 =>
                RegB <= (7 downto 0 => '0') & RegBRaw(31 downto 8);
            when RegOpSel_SHLR16 =>
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
            RegA2Sel => RegA2Sel,
            RegDIn => RegDIn,
            RegDInSel => RegDInSel,
            RegDStore => RegDStore,
            RegDSel => RegDSel,
            clock => CLK,
            RegA => RegA,
            RegB => RegBRaw,
            RegA1 => RegA1,
            RegA2 => RegA2,
            RegD => RegD
        );

end behavioral;











