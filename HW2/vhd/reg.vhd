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
        RegIn      : in   std_logic_vector(LONG_SIZE - 1 downto 0);
        RegInSel   : in   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegStore   : in   std_logic;
        RegASel    : in   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegBSel    : in   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxIn    : in   std_logic_vector(LONG_SIZE - 1 downto 0);
        RegAxInSel : in   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxStore : in   std_logic;
        RegA1Sel   : in   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegA2Sel   : in   integer  range REGARRAY_RegCnt - 1 downto 0;
        CLK        : in   std_logic;
        RegA       : out  std_logic_vector(LONG_SIZE - 1 downto 0);
        RegB       : out  std_logic_vector(LONG_SIZE - 1 downto 0);
        RegA1      : out  std_logic_vector(LONG_SIZE - 1 downto 0);
        RegA2      : out  std_logic_vector(LONG_SIZE - 1 downto 0)
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

    -- Unused signals
    signal RegDIn     : std_logic_vector(2 * REG_SIZE - 1 downto 0);
    signal RegDInSel  : integer  range REGARRAY_RegCnt/2 - 1 downto 0;
    signal RegDStore  : std_logic;
    signal RegDSel    : integer  range REGARRAY_RegCnt/2 - 1 downto 0;
    signal RegD       : std_logic_vector(2 * REG_SIZE - 1 downto 0);

begin

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
            RegB => RegB,
            RegA1 => RegA1,
            RegA2 => RegA2,
            RegD => RegD
        );

end behavioral;











