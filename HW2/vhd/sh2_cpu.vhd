----------------------------------------------------------------------------
--
--  Hitachi SH-2 RISC Processor
--
--  This file contains the complete top-level structural implementation of the
--  Hitachi SH-2 RISC Processor. It includes instantations of all major components:
--  ALU, RegArray, CU, PAU, DAU, and DTU. THE SH2_CPU entity defines the interface
--  of the processor and connects its internal subsystems in a structural
--  architecture. It is used for integration and testing of the full processor
--  design. The main resource for design is the SuperH RISC Engine SH-1/SH-2
--  Progamming Manual by Hitachi September 3, 1996.
--
--  Entities included are:
--    SH2_CPU - top level structural of CPU
--
--  Revision History:
--     16 Apr 2025      Garrett Knuf    Initial revision.
--     22 Apr 2025      Garrett Knuf    Integrated all components together.
--     13 May 2025      Garrett Knuf    Connect DTU.
--
----------------------------------------------------------------------------

--
--  SH2_CPU
--
--  This is the complete entity declaration for the SH-2 CPU.  It is used to
--  test the complete design.
--
--  Inputs:
--    Reset  - active low reset signal
--    NMI    - active falling edge non-maskable interrupt
--    INT    - active low maskable interrupt
--    clock  - the system clock
--
--  Outputs:
--    AB     - memory address bus (32 bits)
--    RE0    - first byte read signal, active low
--    RE1    - second byte read signal, active low
--    RE2    - third byte read signal, active low
--    RE3    - fourth byte read signal, active low
--    WE0    - first byte write signal, active low
--    WE1    - second byte write signal, active low
--    WE2    - third byte write signal, active low
--    WE3    - fourth byte write signal, active low
--
--  Inputs/Outputs:
--    DB     - memory data bus (32 bits)
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.GenericALUConstants.all;
use work.ALUConstants.all;
use work.GenericALUConstants.all;
use work.PAUConstants.all;
use work.DAUConstants.all;
use work.RegArrayConstants.all;
use work.CUConstants.all;
use work.DTUConstants.all;

entity  SH2_CPU  is

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

end  SH2_CPU;

architecture structural of SH2_CPU is

    component ALU is
    port (
            -- Operand inputs
            RegA     : in       std_logic_vector(LONG_SIZE - 1 downto 0);   -- RegArray RegA
            RegB     : in       std_logic_vector(LONG_SIZE - 1 downto 0);   -- RegArray RegB
            TempReg  : in       std_logic_vector(LONG_SIZE - 1 downto 0);   -- CU TempReg
            Imm      : in       std_logic_vector(IMM_SIZE - 1 downto 0);    -- Immediate value
            DBIn     : in       std_logic_vector(LONG_SIZE - 1 downto 0);   -- DataBusIn
            SR0      : in       std_logic;                                  -- StatusReg Bit0

            -- Control signals
            ALUOpASel   : in    integer range ALUOPASEL_CNT-1 downto 0;     -- operand A select
            ALUOpBSel   : in    integer range ALUOPBSEL_CNT-1 downto 0;     -- operand B select
            FCmd        : in    std_logic_vector(3 downto 0);               -- F-Block operation
            CinCmd      : in    std_logic_vector(1 downto 0);               -- carry in operation
            SCmd        : in    std_logic_vector(2 downto 0);               -- shift operation
            ALUCmd      : in    std_logic_vector(1 downto 0);               -- ALU result select
            TbitOp      : in    std_logic_vector(3 downto 0);               -- T-bit operation

            -- Outputs
            Result   : out      std_logic_vector(LONG_SIZE - 1 downto 0);   -- ALU Result
            TBit     : out      std_logic                                   -- Calculated T bit
        );
    end component;

    component RegArray is
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
    end component;

    component PAU is
        port (
            SrcSel      : in    integer range PAU_SRC_CNT - 1 downto 0;         -- source select
            OffsetSel   : in    integer range PAU_OFFSET_CNT - 1 downto 0;      -- offset select
            Offset8     : in    std_logic_vector(7 downto 0);                   -- 8-bit offset
            Offset12    : in    std_logic_vector(11 downto 0);                  -- 12-bit offset
            OffsetReg   : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- register offest
            TempReg     : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- temporary register offset
            UpdatePC    : in    std_logic;                                      -- update PC or hold
            PRSel       : in    integer range PRSEL_CNT-1 downto 0;             -- select modify PR
            IncDecSel   : in    std_logic;                                      -- select inc/dec
            IncDecBit   : in    integer range 2 downto 0;                       -- select bit to inc/dec
            PrePostSel  : in    std_logic;                                      -- select decrement by 4
            DB          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- data bus
            CLK         : in    std_logic;                                      -- clock
            ProgAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program address
            PC          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program counter
            PR          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)    -- procedure register
        );
    end component;

    component DAU is
        port (
            SrcSel      : in    integer range DAU_SRC_CNT - 1 downto 0;         -- source select
            OffsetSel   : in    integer range DAU_OFFSET_CNT - 1 downto 0;      -- offset select
            Offset4     : in    std_logic_vector(3 downto 0);                   -- 4-bit offset
            Offset8     : in    std_logic_vector(7 downto 0);                   -- 8-bit offset
            Rn          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- generic register
            R0          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- register R0
            PC          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program counter
            DB          : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);   -- databus
            IncDecSel   : in    std_logic;                                      -- select inc/dec
            IncDecBit   : in    integer range 2 downto 0;                       -- select bit to inc/dec
            PrePostSel  : in    std_logic;                                      -- select pre/post
            GBRSel      : in    integer range GBRSel_CNT-1 downto 0;            -- select GBR
            VBRSel      : in    integer range VBRSel_CNT-1 downto 0;            -- select VBR
            CLK         : in    std_logic;                                      -- system clock
            RST         : in    std_logic;                                      -- system reset
            AddrIDOut   : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- inc/dec address output
            DataAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- data address
            GBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- global base register
            VBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)    -- vector base register
        );
    end component;

    component CU is
        port (
            -- CU Input Signals
            CLK     : in    std_logic;                                      -- system clock
            RST     : in    std_logic;                                      -- system reset
            DB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);   -- data bus
            AB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);   -- address bus
            Result  : in    std_logic_vector(LONG_SIZE - 1 downto 0);       -- ALU result
            Tbit    : in    std_logic;                                      -- Tbit from ALU
            RegB    : in    std_logic_vector(REG_SIZE - 1 downto 0);

            -- CU Registers
            IR      : out   std_logic_vector(INST_SIZE - 1 downto 0) := x"DEAD";    -- instruction register
            SR      : out std_logic_vector(REG_SIZE - 1 downto 0);                  -- status register
            TempReg : out std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);             -- temporary register
            TempRegSel : out integer range 4 downto 0;                              -- select temporary register
            
            -- ALU Control Signals
            ALUOpASel   : out     integer range ALUOPASEL_CNT-1 downto 0 := 0;  -- select operand A
            ALUOpBSel   : out     integer range ALUOPBSEL_CNT-1 downto 0 := 0;  -- select operand B
            FCmd        : out     std_logic_vector(3 downto 0);                 -- Fblock control
            CinCmd      : out     std_logic_vector(1 downto 0);                 -- carry in
            SCmd        : out     std_logic_vector(2 downto 0);                 -- shift block control
            ALUCmd      : out     std_logic_vector(1 downto 0);                 -- output mux
            TbitOp      : out     std_logic_vector(3 downto 0);                 -- tbit control

            -- PAU Control Signals
            PAU_SrcSel      : out   integer range PAU_SRC_CNT - 1 downto 0;     -- select address source
            PAU_OffsetSel   : out   integer range PAU_OFFSET_CNT - 1 downto 0;  -- select offset source
            PAU_UpdatePC    : out   std_logic;                                  -- update PC
            PAU_PRSel       : out   integer range PRSEL_CNT-1 downto 0;         -- select PR control
            PAU_IncDecSel   : out   std_logic;                                  -- select for inc/dec
            PAU_IncDecBit   : out   integer range 2 downto 0;                   -- select inc/dec
            PAU_PrePostSel  : out   std_logic;                                  -- select pre/post

            -- DAU Control Signals
            DAU_SrcSel      : out   integer range DAU_SRC_CNT - 1 downto 0;     -- select address source
            DAU_OffsetSel   : out   integer range DAU_OFFSET_CNT - 1 downto 0;  -- select offset source
            DAU_IncDecSel   : out   std_logic;                                  -- select inc/dec
            DAU_IncDecBit   : out   integer range 2 downto 0;                   -- select inc/dec bit
            DAU_PrePostSel  : out   std_logic;                                  -- select pre/post
            DAU_GBRSel      : out   integer range GBRSEL_CNT-1 downto 0;        -- select GBR load
            DAU_VBRSel      : out   integer range VBRSEL_CNT-1 downto 0;        -- select VBR load

            -- RegArray Control Signals
            RegInSel        : out   integer  range REGARRAY_RegCnt - 1 downto 0;    -- select input reg
            RegStore        : out   std_logic;                                      -- store input reg
            RegASel         : out   integer  range REGARRAY_RegCnt - 1 downto 0;    -- select output RegA
            RegBSel         : out   integer  range REGARRAY_RegCnt - 1 downto 0;    -- select output regB
            RegAxInSel      : out   integer  range REGARRAY_RegCnt - 1 downto 0;    -- select address input reg
            RegAxInDataSel  : out   integer range REGAXINDATASEL_CNT - 1 downto 0;  -- select data to address input
            RegAxStore      : out   std_logic;                                      -- store address input
            RegA1Sel        : out   integer  range REGARRAY_RegCnt - 1 downto 0;    -- select address reg output
            RegOpSel        : out   integer  range REGOPSEL_CNT - 1 downto 0;       -- select special reg operation
        
            -- IO Control signals
            DBOutSel : out integer range DBOUTSEL_CNT-1 downto 0;   -- select databus output
            ABOutSel : out integer range 1 downto 0;                -- select addressbus output
            DBInMode : out integer range 1 downto 0;                -- select sign/unsigned databus read
            RD     : out   std_logic;                               -- read (active-low)
            WR     : out   std_logic;                               -- write (active-low)
            DataAccessMode : out integer range 2 downto 0           -- align bytes, words, long
        );
    end component;

    component DTU is
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
    end component;


    -- ALU Signals
    signal ALUOpASel    : integer range ALUOPASEL_CNT-1 downto 0;
    signal ALUOpBSel    : integer range ALUOPBSEL_CNT-1 downto 0;
    signal ALU_FCmd     : std_logic_vector(3 downto 0);
    signal ALU_CinCmd   : std_logic_vector(1 downto 0);
    signal ALU_SCmd     : std_logic_vector(2 downto 0);
    signal ALU_ALUCmd   : std_logic_vector(1 downto 0);
    signal ALU_TbitOp   : std_logic_vector(3 downto 0);
    signal ALU_Result   : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal ALU_Tbit     : std_logic;

    -- RegArray Signals
    signal RegIn      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegInSel   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore   : std_logic;
    signal RegASel    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxIn    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegAxInSel : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInDataSel : integer range REGAXINDATASEL_CNT - 1 downto 0;
    signal RegAxStore : std_logic;
    signal RegA1Sel   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegOpSel   : integer range REGOPSEL_CNT - 1 downto 0;
    signal RegA       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegB       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA1      : std_logic_vector(LONG_SIZE - 1 downto 0);

    -- PAU Signals
    signal PAU_SrcSel      : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal PAU_Offset8     : std_logic_vector(7 downto 0);
    signal PAU_Offset12    : std_logic_vector(11 downto 0);
    signal PAU_OffsetReg   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PAU_UpdatePC    : std_logic;
    signal PAU_PRSel       : integer range PRSEL_CNT-1 downto 0;
    signal PAU_IncDecSel   : std_logic;
    signal PAU_IncDecBit   : integer range 2 downto 0;
    signal PAU_PrePostSel  : std_logic;
    signal PAU_ProgAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PC              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PR              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- DAU Signals
    signal DAU_SrcSel      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4     : std_logic_vector(3 downto 0);
    signal DAU_Offset8     : std_logic_vector(7 downto 0);
    signal DAU_Rn          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_R0          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_PC          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_IncDecSel   : std_logic;
    signal DAU_IncDecBit   : integer range 2 downto 0;
    signal DAU_PrePostSel  : std_logic;
    signal DAU_GBRSel      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel      : integer range VBRSEL_CNT-1 downto 0;
    signal DAU_AddrIDOut   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_DataAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal GBR             : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal VBR             : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- DTU Signals
    signal DBIn             : std_logic_vector(DATA_BUS_SIZE-1 downto 0);
    signal DBOut            : std_logic_vector(DATA_BUS_SIZE-1 downto 0);
    signal DBInMode         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR : std_logic;
    signal RD : std_logic;

    -- CU Signals
    signal IR : std_logic_vector(INST_SIZE-1 downto 0);
    signal SR : std_logic_vector(REG_SIZE-1 downto 0);
    signal TempReg : std_logic_vector(31 downto 0);
    signal TempRegSel : integer range 4 downto 0;

    -- Top-level mux signals
    signal DBOutSel : integer range DBOUTSEL_CNT-1 downto 0;    -- select data bus output
    signal ABOutSel : integer range 1 downto 0;                 -- select address bus output

begin

    -- Select address to be either address output by PAU or DAU
    AB <= PAU_ProgAddr when ABOutSel = ABOutSel_Prog else
          DAU_DataAddr when ABOutSel = ABOutSel_Data else
          (others => 'X');

    -- Select data to output to data bus
    DBOut <= ALU_Result when DBOutSel = DBOutSel_Result else
             GBR        when DBOutSel = DBOutSel_GBR    else
             VBR        when DBOutSel = DBOutSel_VBR    else
             SR         when DBOutSel = DBOutSel_SR     else
             PR         when DBOutSel = DBOutSel_PR     else
             PC         when DBOutSel = DBOutSel_PC     else
             (others => 'X');

    -- Create 32-bit ALU for standard logic and arithmetic operations
    SH2_ALU : ALU
        port map (
            RegA        => RegA,
            RegB        => RegB,
            TempReg     => TempReg,
            Imm         => IR(7 downto 0),
            DBIn        => DBIn,
            SR0         => SR(0),

            ALUOpASel   => ALUOpASel,
            ALUOpBSel   => ALUOpBSel,
            FCmd        => ALU_FCmd,
            CinCmd      => ALU_CinCmd,
            SCmd        => ALU_SCmd,
            ALUCmd      => ALU_ALUCmd,
            TbitOp      => ALU_TbitOp,
            Result      => ALU_Result,
            Tbit        => ALU_Tbit
        );

    -- Create 32-bit register array with general purpose registers R0-R15
    SH2_RegArray : RegArray
        port map (
            Result          => ALU_Result,
            DataAddrID      => DAU_AddrIDOut,
            DataAddr        => DAU_DataAddr,
            SR              => SR,
            GBR             => GBR,
            VBR             => VBR,
            PR              => PR,
            RegInSel        => RegInSel,
            RegStore        => RegStore,
            RegASel         => RegASel,
            RegBSel         => RegBSel,
            RegAxInSel      => RegAxInSel,
            RegAxInDataSel  => RegAxInDataSel,
            RegAxStore      => RegAxStore,
            RegA1Sel        => RegA1Sel,
            RegOpSel        => RegOpSel,
            CLK             => clock,
            RegA            => RegA,
            RegB            => RegB,
            RegA1           => RegA1
        );

    -- Create Program Memory Access Unit (PAU)
    SH2_PAU : PAU
        port map (
            SrcSel     => PAU_SrcSel,
            OffsetSel  => PAU_OffsetSel,
            Offset8    => IR(7 downto 0),
            Offset12   => IR(11 downto 0),
            OffsetReg  => RegA1,
            TempReg    => TempReg,
            IncDecSel  => PAU_IncDecSel,
            IncDecBit  => PAU_IncDecBit,
            PrePostSel => PAU_PrePostSel,
            DB         => DB,
            UpdatePC   => PAU_UpdatePC,
            PRSel      => PAU_PRSel,
            CLK        => clock,
            ProgAddr   => PAU_ProgAddr,
            PC         => PC,
            PR         => PR
        );

    -- Create Data Memory Access Unit (DAU)
    SH2_DAU : DAU
        port map (
            SrcSel     => DAU_SrcSel,
            OffsetSel  => DAU_OffsetSel,
            Offset4    => IR(3 downto 0),
            Offset8    => IR(7 downto 0),
            Rn         => RegA1,
            R0         => RegA,
            PC         => PC,
            DB         => DB,
            IncDecSel  => DAU_IncDecSel,
            IncDecBit  => DAU_IncDecBit,
            PrePostSel => DAU_PrePostSel,
            GBRSel     => DAU_GBRSel,
            VBRSel     => DAU_VBRSel,
            CLK        => clock,
            RST        => Reset,
            AddrIDOut  => DAU_AddrIDOut,
            DataAddr   => DAU_DataAddr,
            GBR        => GBR,
            VBR        => VBR
        );

    -- Create Data Transfer Unit (DTU) to interface with memory
    SH2_DTU : DTU
        port map (
            DBOut           => DBOut,
            AB              => AB,
            RD              => RD,
            WR              => WR,
            DataAccessMode  => DataAccessMode,
            DBInMode        => DBInMode,
            CLK             => clock,
            DBIn            => DBIn,
            WE0             => WE0,
            WE1             => WE1,
            WE2             => WE2,
            WE3             => WE3,
            RE0             => RE0,
            RE1             => RE1,
            RE2             => RE2,
            RE3             => RE3,
            DB              => DB
        );

    -- Control Unit (CU)
    SH2_CU : CU
        port map (
            
            -- CU Input Signals
            CLK         => clock,
            RST         => reset,
            DB          => DB,
            AB          => AB,
            RegB        => RegB,
            Result      => ALU_Result,

            -- CU Registers
            SR          => SR,
            IR          => IR,
            Tbit        => ALU_Tbit,
            TempReg     => TempReg,
            TempRegSel  => TempRegSel,

            -- ALU Signals
            ALUOpASel   => ALUOpASel,
            ALUOpBSel   => ALUOpBSel,
            FCmd        => ALU_FCmd,
            CinCmd      => ALU_CinCmd,
            SCmd        => ALU_SCmd,
            ALUCmd      => ALU_ALUCmd,
            TbitOp      => ALU_TbitOp,

            -- PAU Signals
            PAU_SrcSel      => PAU_SrcSel,
            PAU_OffsetSel   => PAU_OffsetSel,
            PAU_UpdatePC    => PAU_UpdatePC,
            PAU_PRSel       => PAU_PRSel,
            PAU_IncDecSel   => PAU_IncDecSel,
            PAU_IncDecBit   => PAU_IncDecBit,
            PAU_PrePostSel  => PAU_PrePostSel,

            -- DAU Signals
            DAU_SrcSel      => DAU_SrcSel,
            DAU_OffsetSel   => DAU_OffsetSel,
            DAU_IncDecSel   => DAU_IncDecSel,
            DAU_IncDecBit   => DAU_IncDecBit,
            DAU_PrePostSel  => DAU_PrePostSel,
            DAU_GBRSel      => DAU_GBRSel,
            DAU_VBRSel      => DAU_VBRSel,

            -- RegArray Signals
            RegInSel        => RegInSel,
            RegStore        => RegStore,
            RegASel         => RegASel,
            RegBSel         => RegBSel,
            RegAxInSel      => RegAxInSel,
            RegAxInDataSel  => RegAxInDataSel,
            RegAxStore      => RegAxStore,
            RegA1Sel        => RegA1Sel,
            RegOpSel        => RegOpSel,

            -- DTU signals
            RD => RD,
            WR => WR,
            DataAccessMode => DataAccessMode,
            DBInMode => DBInMode,

            -- IO signals
            DBOutSel    => DBOutSel,
            ABOutSel    => ABOutSel

        );

end structural;