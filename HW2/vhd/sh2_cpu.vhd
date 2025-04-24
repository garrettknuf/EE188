----------------------------------------------------------------------------
--
--  Hitachi SH-2 RISC Processor
--
--  This is an implementation of 
--
--  Entities included are:
--    
--
--  Revision History:
--     16 April 2025    Garrett Knuf    Initial revision.
--
----------------------------------------------------------------------------

--
-- SH2_CPU
--
-- This is 
--
--  Inputs:
--    CLK   - system clock
--
--  In/outs:
--    DB    - data bus (16-bit)
--
--  Outputs:
--    AB    - address bus (32-bit)
--
library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;
use work.ALUConstants.all;
use work.TbitConstants.all;
use work.PAUConstants.all;
use work.DAUConstants.all;
use work.RegArrayConstants.all;

entity SH2_CPU is

    port (
        CLK     : in    std_logic;
        DB      : inout std_logic_vector(15 downto 0);
        AB      : out   std_logic_vector(31 downto 0);
        RD      : out   std_logic;
        WR      : out   std_logic
    );

end SH2_CPU;

architecture structural of SH2_CPU is

    component ALU is
        port (
            ALUOpA   : in      std_logic_vector(LONG_SIZE - 1 downto 0);
            ALUOpB   : in      std_logic_vector(LONG_SIZE - 1 downto 0);
            Cin      : in      std_logic;                               
            FCmd     : in      std_logic_vector(3 downto 0);            
            CinCmd   : in      std_logic_vector(1 downto 0);            
            SCmd     : in      std_logic_vector(3 downto 0);            
            ALUCmd   : in      std_logic_vector(1 downto 0);            
            TbitOp   : in      std_logic_vector(3 downto 0);              -- T-bit operation
            Result   : buffer  std_logic_vector(LONG_SIZE - 1 downto 0);
            Tbit     : out     std_logic                                
        );
    end component;

    component RegArray is
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
            RegOpSel   : in   integer  range REGOP_SrcCnt - 1 downto 0;
            CLK        : in   std_logic;
            RegA       : out  std_logic_vector(LONG_SIZE - 1 downto 0);
            RegB       : out  std_logic_vector(LONG_SIZE - 1 downto 0);
            RegA1      : out  std_logic_vector(LONG_SIZE - 1 downto 0);
            RegA2      : out  std_logic_vector(LONG_SIZE - 1 downto 0)
        );
    end component;

    component PAU is
        port (
            SrcSel      : in    integer range PAU_SRC_CNT - 1 downto 0;
            OffsetSel   : in    integer range PAU_OFFSET_CNT - 1 downto 0;
            Offset8     : in    std_logic_vector(7 downto 0);
            Offset12    : in    std_logic_vector(11 downto 0);
            OffsetReg   : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            UpdatePC    : in    std_logic;
            UpdatePR    : in    std_logic;
            CLK         : in    std_logic;
            ProgAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            PC          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            PR          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)
        );
    end component;

    component DAU is
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
            CLK         : in    std_logic;
            AddrIDOut   : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            DataAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   
            GBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)
        );
    end component;

    component StatusReg is
        port (
            Tbit        : in    std_logic;
            UpdateTbit  : in    std_logic;
            CLK         : in    std_logic;
            SR          : out   std_logic_vector(REG_SIZE - 1 downto 0)
        );
    end component;

    -- ALU Signals
    signal ALUOpA    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal ALUOpB    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal Cin       : std_logic;
    signal FCmd      : std_logic_vector(3 downto 0);
    signal CinCmd    : std_logic_vector(1 downto 0);
    signal SCmd      : std_logic_vector(3 downto 0);
    signal ALUCmd    : std_logic_vector(1 downto 0);
    signal TbitOp    : std_logic_vector(3 downto 0);
    signal Result    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal Tbit      : std_logic;

    -- RegArray Signals
    signal RegIn      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegInSel   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore   : std_logic;
    signal RegASel    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxIn    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegAxInSel : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxStore : std_logic;
    signal RegA1Sel   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegA2Sel   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegOpSel   : integer range REGOP_SrcCnt - 1 downto 0;
    signal RegA       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegB       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA1      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA2      : std_logic_vector(LONG_SIZE - 1 downto 0);

    -- PAU Signals
    signal PAU_SrcSel      : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal PAU_Offset8     : std_logic_vector(7 downto 0);
    signal PAU_Offset12    : std_logic_vector(11 downto 0);
    signal PAU_OffsetReg   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PAU_UpdatePC    : std_logic;
    signal PAU_UpdatePR    : std_logic;
    signal PAU_ProgAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PAU_PC          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PAU_PR          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- DAU Signals
    signal DAU_SrcSel      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4        : std_logic_vector(3 downto 0);
    signal DAU_Offset8     : std_logic_vector(7 downto 0);
    signal DAU_Rn             : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_R0             : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_PC          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_IncDecSel      : std_logic;
    signal DAU_IncDecBit      : integer range 2 downto 0;
    signal DAU_PrePostSel     : std_logic;
    signal DAU_LoadGBR        : std_logic;
    signal DAU_AddrIDOut      : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_DataAddr       : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_GBR            : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- StatusReg Signals
    signal Tbit_in        : std_logic;
    signal UpdateTbit     : std_logic;
    signal SR             : std_logic_vector(REG_SIZE - 1 downto 0);

begin

    -- Create 32-bit ALU for standard logic and arithmetic operations
    SH2_ALU : ALU
        port map (
            ALUOpA  => ALUOpA,
            ALUOpB  => ALUOpB,
            Cin     => Cin,
            FCmd    => FCmd,
            CinCmd  => CinCmd,
            SCmd    => SCmd,
            ALUCmd  => ALUCmd,
            TbitOp  => TbitOp,
            Result  => Result,
            Tbit    => Tbit
        );

    -- Create 32-bit register array with general purpose registers R0-R15
    SH2_RegArray : RegArray
        port map (
            RegIn       => RegIn,
            RegInSel    => RegInSel,
            RegStore    => RegStore,
            RegASel     => RegASel,
            RegBSel     => RegBSel,
            RegAxIn     => RegAxIn,
            RegAxInSel  => RegAxInSel,
            RegAxStore  => RegAxStore,
            RegA1Sel    => RegA1Sel,
            RegA2Sel    => RegA2Sel,
            RegOpSel    => RegOpSel,
            CLK         => CLK,
            RegA        => RegA,
            RegB        => RegB,
            RegA1       => RegA1,
            RegA2       => RegA2
        );

    -- Program Memory Access Unit (PAU)
    SH2_PAU : PAU
        port map (
            SrcSel     => PAU_SrcSel,
            OffsetSel  => PAU_OffsetSel,
            Offset8    => PAU_Offset8,
            Offset12   => PAU_Offset12,
            OffsetReg  => PAU_OffsetReg,
            UpdatePC   => PAU_UpdatePC,
            UpdatePR   => PAU_UpdatePR,
            CLK        => CLK,
            ProgAddr   => PAU_ProgAddr,
            PC         => PAU_PC,
            PR         => PAU_PR
        );

    -- Data Memory Access Unit (DAU)
    SH2_DAU : DAU
        port map (
            SrcSel     => DAU_SrcSel,
            OffsetSel  => DAU_OffsetSel,
            Offset4    => DAU_Offset4,
            Offset8    => DAU_Offset8,
            Rn         => DAU_Rn,
            R0         => DAU_R0,
            PC         => DAU_PC,
            IncDecSel  => DAU_IncDecSel,
            IncDecBit  => DAU_IncDecBit,
            PrePostSel => DAU_PrePostSel,
            LoadGBR    => DAU_LoadGBR,
            CLK        => CLK,
            AddrIDOut  => DAU_AddrIDOut,
            DataAddr   => DAU_DataAddr,
            GBR        => DAU_GBR
        );

    -- Status Register (SR)
    SH2_SR : StatusReg
        port map (
            Tbit        => Tbit,
            UpdateTbit  => UpdateTbit,
            CLK         => CLK,
            SR          => SR
        );

end structural;
