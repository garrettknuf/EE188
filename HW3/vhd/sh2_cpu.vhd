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
--     16 May 2025      George Ore      Make interface synthesizable.
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
            PC_EX       : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- pipelined PC (delayed by two clocks)
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
            AB      : in    std_logic_vector(1 downto 0);                   -- address bus (least 2 significant bits)
            Result  : in    std_logic_vector(LONG_SIZE - 1 downto 0);       -- ALU result
            Tbit    : in    std_logic;                                      -- Tbit from ALU
            RegB    : in    std_logic_vector(REG_SIZE - 1 downto 0);

            -- CU Registers
            IR      : out   std_logic_vector(INST_SIZE - 1 downto 0) := x"DEAD";    -- instruction register
            SR      : out std_logic_vector(REG_SIZE - 1 downto 0);                  -- status register
            TempReg : out std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);             -- temporary register
            TempReg2 : out std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);            -- secondary temp register
            
            -- CU Output Signals
            UpdateIR  : out   std_logic;    -- update instruction register (used to delay pipeline during data access)
            UpdateSR  : out   std_logic;
            
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
            DataAccessMode : out integer range 2 downto 0;          -- align bytes, words, long

            -- Pipeline control signals
            UpdateIR_EX : in std_logic;    -- pipelined signal to update IR (used to detect memory access)
            UpdateSR_EX : in std_logic;    -- pipelined signal to update SR (used to determine conditional branching)
            ForceNormalStateNext : in std_logic
        );
    end component;

    component DTU is
        port (
            DBOut           : in    std_logic_vector(DATA_BUS_SIZE-1 downto 0);     -- data to output to DB
            AB              : in    std_logic_vector(1 downto 0);                   -- address bus (least 2 significant bits)
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
    signal ALUOpASel_ID    : integer range ALUOPASEL_CNT-1 downto 0;
    signal ALUOpBSel_ID    : integer range ALUOPBSEL_CNT-1 downto 0;
    signal ALU_FCmd_ID     : std_logic_vector(3 downto 0);
    signal ALU_CinCmd_ID   : std_logic_vector(1 downto 0);
    signal ALU_SCmd_ID     : std_logic_vector(2 downto 0);
    signal ALU_ALUCmd_ID   : std_logic_vector(1 downto 0);
    signal ALU_TbitOp_ID   : std_logic_vector(3 downto 0);

    signal ALUOpASel_EX    : integer range ALUOPASEL_CNT-1 downto 0;
    signal ALUOpBSel_EX    : integer range ALUOPBSEL_CNT-1 downto 0;
    signal ALU_FCmd_EX     : std_logic_vector(3 downto 0);
    signal ALU_CinCmd_EX   : std_logic_vector(1 downto 0);
    signal ALU_SCmd_EX     : std_logic_vector(2 downto 0);
    signal ALU_ALUCmd_EX   : std_logic_vector(1 downto 0);
    signal ALU_TbitOp_EX   : std_logic_vector(3 downto 0);

    signal ALU_Result    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal ALU_Tbit      : std_logic;

    -- RegArray Signals
    signal RegInSel_ID   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore_ID   : std_logic;
    signal RegASel_ID    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel_ID    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInSel_ID : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInDataSel_ID : integer range REGAXINDATASEL_CNT - 1 downto 0;
    signal RegAxStore_ID : std_logic;
    signal RegA1Sel_ID   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegOpSel_ID  : integer range REGOPSEL_CNT - 1 downto 0;

    signal RegInSel_EX   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore_EX   : std_logic;
    signal RegASel_EX    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel_EX    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInSel_EX : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInDataSel_EX : integer range REGAXINDATASEL_CNT - 1 downto 0;
    signal RegAxStore_EX : std_logic;
    signal RegA1Sel_EX   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegOpSel_EX  : integer range REGOPSEL_CNT - 1 downto 0;


    signal RegA       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegB       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA1      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegIn      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegAxIn    : std_logic_vector(LONG_SIZE - 1 downto 0);

    -- PAU Signals
    signal PAU_SrcSel_ID      : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel_ID   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal PAU_UpdatePC_ID    : std_logic;
    signal PAU_PRSel_ID       : integer range PRSEL_CNT-1 downto 0;
    signal PAU_IncDecSel_ID   : std_logic;
    signal PAU_IncDecBit_ID   : integer range 2 downto 0;
    signal PAU_PrePostSel_ID  : std_logic;

    signal PAU_SrcSel_EX      : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel_EX   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal PAU_UpdatePC_EX    : std_logic;
    signal PAU_PRSel_EX       : integer range PRSEL_CNT-1 downto 0;
    signal PAU_IncDecSel_EX   : std_logic;
    signal PAU_IncDecBit_EX   : integer range 2 downto 0;
    signal PAU_PrePostSel_EX  : std_logic;

    signal PC_ID              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    -- signal PC_Inter              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PC_EX           : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    signal PAU_ProgAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PAU_OffsetReg   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PR              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- DAU Signals
    signal DAU_SrcSel_ID      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel_ID   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4_ID     : std_logic_vector(3 downto 0);
    signal DAU_Offset8_ID     : std_logic_vector(7 downto 0);
    signal DAU_IncDecSel_ID   : std_logic;
    signal DAU_IncDecBit_ID   : integer range 2 downto 0;
    signal DAU_PrePostSel_ID  : std_logic;
    signal DAU_GBRSel_ID      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel_ID      : integer range VBRSEL_CNT-1 downto 0;

    signal DAU_SrcSel_EX      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel_EX   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4_EX     : std_logic_vector(3 downto 0);
    signal DAU_Offset8_EX     : std_logic_vector(7 downto 0);
    signal DAU_IncDecSel_EX   : std_logic;
    signal DAU_IncDecBit_EX   : integer range 2 downto 0;
    signal DAU_PrePostSel_EX  : std_logic;
    signal DAU_GBRSel_EX      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel_EX      : integer range VBRSEL_CNT-1 downto 0;

    signal DAU_SrcSel_MA      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel_MA   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4_MA     : std_logic_vector(3 downto 0);
    signal DAU_Offset8_MA     : std_logic_vector(7 downto 0);
    signal DAU_IncDecSel_MA   : std_logic;
    signal DAU_IncDecBit_MA   : integer range 2 downto 0;
    signal DAU_PrePostSel_MA  : std_logic;
    signal DAU_GBRSel_MA      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel_MA      : integer range VBRSEL_CNT-1 downto 0;
    
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
    signal DBInMode_ID         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode_ID   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR_ID : std_logic;
    signal RD_ID : std_logic;
    
    signal DBInMode_EX         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode_EX   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR_EX : std_logic;
    signal RD_EX : std_logic;

    signal DBInMode_MA         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode_MA   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR_MA : std_logic;
    signal RD_MA : std_logic;

    signal DBIn             : std_logic_vector(DATA_BUS_SIZE-1 downto 0);
    signal DBOut            : std_logic_vector(DATA_BUS_SIZE-1 downto 0);

    -- CU Signals
    signal IR_ID : std_logic_vector(INST_SIZE-1 downto 0);
    signal IR_EX : std_logic_vector(INST_SIZE-1 downto 0);
    signal IR_MA : std_logic_vector(11 downto 0);   -- reduce to 12 bits since we don't need the rest
    signal UpdateIR_ID : std_logic;
    signal UpdateIR_EX : std_logic;
    signal UpdateIR_MA : std_logic;
    signal UpdateSR_ID : std_logic;
    signal UpdateSR_EX : std_logic;

    signal SR : std_logic_vector(REG_SIZE-1 downto 0);
    signal TempReg : std_logic_vector(31 downto 0);
    signal TempReg2 : std_logic_vector(31 downto 0);

    -- Top-level mux signals
    signal DBOutSel_ID : integer range DBOUTSEL_CNT-1 downto 0;    -- select data bus output
    signal ABOutSel_ID : integer range 1 downto 0;                 -- select address bus output

    signal DBOutSel_EX : integer range DBOUTSEL_CNT-1 downto 0;    -- select data bus output
    signal ABOutSel_EX : integer range 1 downto 0;                 -- select address bus output

    signal DBOutSel_MA : integer range DBOUTSEL_CNT-1 downto 0;    -- select data bus output
    signal ABOutSel_MA : integer range 1 downto 0;                 -- select address bus output

  -- The following four signals are used to delay the insruction fetch information in
  -- case of memory access.

    -- Muxes for differentiating between normal and memory access stalled inputs
    signal DBMux : std_logic_vector(DATA_BUS_SIZE-1 downto 0);   -- select DB input PL or not PL
    signal ABMux : std_logic_vector(1 downto 0);                 -- select AB input PL or not PL

    -- Data bus pipeline
    signal DB_PL : std_logic_vector(DATA_BUS_SIZE-1 downto 0);   -- for stalling databus in memory access stage

    -- Address bus pipeline
    signal AB_PL : std_logic_vector(1 downto 0); -- additonal information for instruction register stalling 

    -- Signal that indicates if the a conditional branch should be taken
    signal TakeBranch : std_logic;
    signal CBRSlot : std_logic;

    signal LastInstBranched : std_logic;

    signal ForceNormalStateNext : std_logic;

    -- Conditional branch (CBR) IR detection mask
    constant IR_CBR_PATTERN : std_logic_vector(15 downto 8) := "10001--1";

    -- CBR condition bit decoding
    constant IR_CBR_COND_BIT : integer := 9;
    constant IR_CBR_COND_T : std_logic := '0';
    constant IR_CBR_COND_F : std_logic := '1';

    -- CBR slot bit decoding
    constant IR_CBR_SLOT_BIT : integer := 10;
    constant IR_CBR_SLOT_T : std_logic := '1';
    constant IR_CBR_SLOT_F : std_logic := '0';

begin

    -- Update the CU data bus input either normal or memory access stalled input
    DBMux <= DB_PL when UpdateIR_MA = '0' else DB;
    ABMux <= AB_PL when UpdateIR_MA = '0' else AB(1 downto 0);

    CondBranching  : process (all)
    begin
        -- Check if execution pipeline stage IR is conditional branch
        if std_match(IR_EX(15 downto 8), IR_CBR_PATTERN) then
            
            -- Check if conditional branch should be taken or not
            if IR_EX(IR_CBR_COND_BIT) = IR_CBR_COND_T then
                -- Branch if true (T=1)
                TakeBranch <= '1' when SR(0) = '1' and LastInstBranched = '0' else '0';
            else
                -- Branch if false (t=0)
                TakeBranch <= '1' when SR(0) = '0' and LastInstBranched = '0' else '0';
            end if;
        else
            TakeBranch <= '0';
        end if;

        CBRSlot <= '1' when IR_EX(IR_CBR_SLOT_BIT) = IR_CBR_SLOT_T else '0';

        -- PAU source should be pipelined PC if a conditional branch is taken
        PAU_OffsetSel_EX <= PAU_Offset8 when TakeBranch = '1' else PAU_OffsetWord;
        PAU_SrcSel_EX <= PAU_SrcSel_ID when TakeBranch = '0' else PAU_AddrPC_EX;

        ForceNormalStateNext <= '1' when TakeBranch = '1' else '0';
        
    end process;

    -- Instruction decoding to Execution Pipeline
    Pipeline : process (clock)
    begin
        -- Pass on instructions from one stage to the stage
        if rising_edge(clock) then

        
        -- Define initial reset values
            if reset = '0' then
                -- Instruction register pipeline
                IR_EX  <= (others => '0');

                -- DTU control signals
                DBInMode_EX <= DBInMode_Unsigned;
                DataAccessMode_EX <= DataAccessMode_WORD;
                WR_EX <= '1';
                RD_EX <= '0';
                
                DBInMode_MA <= DBInMode_Unsigned;
                DataAccessMode_MA <= DataAccessMode_WORD;
                WR_MA <= '1';
                RD_MA <= '0';
                UpdateIR_EX <= '1';
                UpdateIR_MA <= '1';

                ABOutSel_EX <= ABOutSel_Prog;
                ABOutSel_MA <= ABOutSel_Prog;
        
            else
                    

        -- Define pipeline operation
        --  There are four stages in the pipeline:
        --      1. Instruction Fetch (IF)
        --      2. Instruction Decode (ID)
        --      3. Execution (EX)
        --      4. Memory Access (MA)
        --
        --  The Instruction Fetch stage is defined by the PAU control signals that
        --  arrive at the PAU to output a certain value of PC
        --  TODO: Update how this works once we get the branching working
        --
        --  The Instruction Decode stage is mostly handled by the CU's internal IR
        --  register and decode logic. Most ID stage signals are output by the CU.
        -- 
        --  The Execution stage signals go through one round of
        --  
        --  The Memory Access stage 


                -- -- PAU source select should be pipelined PC if a conditional branch is taken
                -- PAU_SrcSel_EX <= PAU_SrcSel_ID when TakeBranch = '0' else PAU_AddrPC_EX;

                -- Always move update IR signal from execution to memory access stage
                UpdateIR_MA <= UpdateIR_EX;

                -- If the execution stage instruction updates IR, then activate pipeline
                --      Signals passed from Instruction Decode to Execution stage:
                --          - ALU control signals
                --          - RegArray control signals
                --          - DAU control signals
                --          - Update status register signal
                --          - Instruction register data
                if UpdateIR_EX = '1' then
                    -- ALU control signals
                    ALUOpASel_EX <= ALUOpASel_ID;
                    ALUOpBSel_EX <= ALUOpBSel_ID;
                    ALU_FCmd_EX <= ALU_FCmd_ID;
                    ALU_CinCmd_EX <= ALU_CinCmd_ID;
                    ALU_SCmd_EX <= ALU_SCmd_ID;
                    ALU_ALUCmd_EX <= ALU_ALUCmd_ID;
                    ALU_TbitOp_EX <= ALU_TbitOp_ID;

                    -- RegArray control signals
                    RegInSel_EX <= RegInSel_ID;
                    RegStore_EX <= RegStore_ID when TakeBranch = '0' or CBRSlot = '1' else '0';
                    RegASel_EX <= RegASel_ID;
                    RegBSel_EX <= RegBSel_ID;
                    RegAxInSel_EX <= RegAxInSel_ID;
                    RegAxInDataSel_EX <= RegAxInDataSel_ID;
                    RegAxStore_EX <= RegAxStore_ID when TakeBranch = '0' or CBRSlot = '1' else '0';
                    RegA1Sel_EX <= RegA1Sel_ID;
                    RegOpSel_EX <= RegOpSel_ID;

                    -- DAU control signals
                    DAU_SrcSel_EX <= DAU_SrcSel_ID;
                    DAU_OffsetSel_EX <= DAU_OffsetSel_ID;
                    DAU_Offset4_EX <= DAU_Offset4_ID;
                    DAU_Offset8_EX <= DAU_Offset8_ID;
                    DAU_IncDecSel_EX <= DAU_IncDecSel_ID;
                    DAU_IncDecBit_EX <= DAU_IncDecBit_ID;
                    DAU_PrePostSel_EX <= DAU_PrePostSel_ID;
                    DAU_GBRSel_EX <= DAU_GBRSel_ID when TakeBranch = '0' or CBRSlot = '1' else GBRSel_None;
                    DAU_VBRSel_EX <= DAU_VBRSel_ID when TakeBranch = '0' or CBRSlot = '1' else VBRSel_None;

                    -- Update status register signal
                    UpdateSR_EX <= UpdateSR_ID when TakeBranch = '0' or CBRSlot = '1' else '0';

                    -- Instruction register data
                    IR_EX <= IR_ID;

                    LastInstBranched <= TakeBranch;
                else 
                    -- Save the data bus input to pipeline register in case of memory access
                    DB_PL <= DB when UpdateIR_EX = '0';
                    AB_PL <= AB(1 downto 0) when UpdateIR_EX = '0';
                    
                end if;

                -- If the memory access stage instruction updates IR, then activate pipeline
                --      Signals passed from Instruction Decode to Execution stage:
                --          - Update IR signal
                --          - PAU control signals
                --      
                --      Signals passed from Instruction Decode to special intermediate stage:
                --          - Pipelined PC signal
                --      Signals passed from special intermediate to Execution stage:
                --          - Pipelined PC signal
                --
                --      Signals passed from Execution to Memory Access stage:
                --          - Instruction register data
                --          - DAU control signals
                if UpdateIR_MA = '1' then

                    -- Update IR signal
                    UpdateIR_EX <= UpdateIR_ID;

                                    -- PAU source select should be pipelined PC if a conditional branch is taken
                    -- PAU_SrcSel_EX <= PAU_SrcSel_ID when TakeBranch = '0' else PAU_AddrPC_EX;

                    -- PAU control signals
                    PAU_UpdatePC_EX <= PAU_UpdatePC_ID;
                    PAU_PRSel_EX <= PAU_PRSel_ID when TakeBranch = '0' or CBRSlot = '1' else PRSel_None;
                    PAU_IncDecSel_EX <= PAU_IncDecSel_ID;
                    PAU_IncDecBit_EX <= PAU_IncDecBit_ID;
                    PAU_PrePostSel_EX <= PAU_PrePostSel_ID;
                    
                    -- Pipelined PC signal
                    PC_EX <= PC_ID;

                    -- Instruction register data
                    IR_MA <= IR_EX(11 downto 0);

                    -- DAU control signals
                    DAU_SrcSel_MA <= DAU_SrcSel_EX;
                    DAU_OffsetSel_MA <= DAU_OffsetSel_EX;
                    DAU_Offset4_MA <= DAU_Offset4_EX;
                    DAU_Offset8_MA <= DAU_Offset8_EX;
                    DAU_IncDecSel_MA <= DAU_IncDecSel_EX;
                    DAU_IncDecBit_MA <= DAU_IncDecBit_EX;
                    DAU_PrePostSel_MA <= DAU_PrePostSel_EX;
                    DAU_GBRSel_MA <= DAU_GBRSel_EX;
                    DAU_VBRSel_MA <= DAU_VBRSel_EX;

                end if;

                DBOutSel_EX <= DBOutSel_ID;
                ABOutSel_EX <= ABOutSel_ID;

                DBOutSel_MA <= DBOutSel_EX;
                ABOutSel_MA <= ABOutSel_EX;

                -- DTU control signals
                DBInMode_EX <= DBInMode_ID;
                DataAccessMode_EX <= DataAccessMode_ID;
                WR_EX <= WR_ID when TakeBranch = '0' or CBRSlot = '1' else '1';
                RD_EX <= RD_ID when TakeBranch = '0' or CBRSlot = '1' else '0';
                
                DBInMode_MA <= DBInMode_EX;
                DataAccessMode_MA <= DataAccessMode_EX;
                WR_MA <= WR_EX;
                RD_MA <= RD_EX;
            end if;

        end if;
    end process;

    -- Select address to be either address output by PAU or DAU
    AB <= PAU_ProgAddr when ABOutSel_MA = ABOutSel_Prog else
          DAU_DataAddr when ABOutSel_MA = ABOutSel_Data else
          (others => 'X');

    -- Select data to output to data bus
    DBOut <= ALU_Result when DBOutSel_MA = DBOutSel_Result else
             GBR        when DBOutSel_MA = DBOutSel_GBR    else
             VBR        when DBOutSel_MA = DBOutSel_VBR    else
             SR         when DBOutSel_MA = DBOutSel_SR     else
             PR         when DBOutSel_MA = DBOutSel_PR     else
             PC_ID      when DBOutSel_MA = DBOutSel_PC     else
             (others => 'X');

    -- Create 32-bit ALU for standard logic and arithmetic operations
    SH2_ALU : ALU
        port map (
            RegA        => RegA,
            RegB        => RegB,
            TempReg     => TempReg2,
            Imm         => IR_EX(7 downto 0),
            DBIn        => DBIn,
            SR0         => SR(0),

            ALUOpASel   => ALUOpASel_EX,
            ALUOpBSel   => ALUOpBSel_EX,
            FCmd        => ALU_FCmd_EX,
            CinCmd      => ALU_CinCmd_EX,
            SCmd        => ALU_SCmd_EX,
            ALUCmd      => ALU_ALUCmd_EX,
            
            TbitOp      => ALU_TbitOp_EX,
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
            RegInSel        => RegInSel_EX,
            RegStore        => RegStore_EX,
            RegASel         => RegASel_EX,
            RegBSel         => RegBSel_EX,
            RegAxInSel      => RegAxInSel_EX,
            RegAxInDataSel  => RegAxInDataSel_EX,
            RegAxStore      => RegAxStore_EX,
            RegA1Sel        => RegA1Sel_EX,
            RegOpSel        => RegOpSel_EX,
            CLK             => clock,
            RegA            => RegA,
            RegB            => RegB,
            RegA1           => RegA1
        );

    -- Create Program Memory Access Unit (PAU)
    SH2_PAU : PAU
        port map (
            SrcSel     => PAU_SrcSel_EX,
            OffsetSel  => PAU_OffsetSel_EX,
            Offset8    => IR_EX(7 downto 0),
            Offset12   => IR_EX(11 downto 0),
            OffsetReg  => RegA1,
            TempReg    => TempReg,
            IncDecSel  => PAU_IncDecSel_EX,
            IncDecBit  => PAU_IncDecBit_EX,
            PrePostSel => PAU_PrePostSel_EX,
            DB         => DB,
            PC_EX      => PC_EX,
            UpdatePC   => PAU_UpdatePC_EX,
            PRSel      => PAU_PRSel_EX,
            CLK        => clock,
            ProgAddr   => PAU_ProgAddr,
            PC         => PC_ID,
            PR         => PR
        );

    -- Create Data Memory Access Unit (DAU)
    SH2_DAU : DAU
        port map (
            SrcSel     => DAU_SrcSel_MA,
            OffsetSel  => DAU_OffsetSel_MA,
            Offset4    => IR_MA(3 downto 0),
            Offset8    => IR_MA(7 downto 0),
            Rn         => RegA1,
            R0         => RegA,
            PC         => PC_ID,
            DB         => DB,
            IncDecSel  => DAU_IncDecSel_MA,
            IncDecBit  => DAU_IncDecBit_MA,
            PrePostSel => DAU_PrePostSel_MA,
            GBRSel     => DAU_GBRSel_MA,
            VBRSel     => DAU_VBRSel_MA,
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
            AB              => AB(1 downto 0),
            RD              => RD_MA,
            WR              => WR_MA,
            DataAccessMode  => DataAccessMode_MA,
            DBInMode        => DBInMode_MA,
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
            DB          => DBMux,
            AB          => ABMux,
            RegB        => RegB,
            Result      => ALU_Result,

            -- CU Registers
            SR          => SR,
            IR          => IR_ID,
            Tbit        => ALU_Tbit,
            TempReg     => TempReg,
            TempReg2    => TempReg2,

            -- CU Output Signals
            UpdateIR   => UpdateIR_ID,
            UpdateSR   => UpdateSR_ID,

            -- ALU Signals
            ALUOpASel   => ALUOpASel_ID,
            ALUOpBSel   => ALUOpBSel_ID,
            FCmd        => ALU_FCmd_ID,
            CinCmd      => ALU_CinCmd_ID,
            SCmd        => ALU_SCmd_ID,
            ALUCmd      => ALU_ALUCmd_ID,
            TbitOp      => ALU_TbitOp_ID,

            -- PAU Signals
            PAU_SrcSel      => PAU_SrcSel_ID,
            PAU_OffsetSel   => PAU_OffsetSel_ID,
            PAU_UpdatePC    => PAU_UpdatePC_ID,
            PAU_PRSel       => PAU_PRSel_ID,
            PAU_IncDecSel   => PAU_IncDecSel_ID,
            PAU_IncDecBit   => PAU_IncDecBit_ID,
            PAU_PrePostSel  => PAU_PrePostSel_ID,

            -- DAU Signals
            DAU_SrcSel      => DAU_SrcSel_ID,
            DAU_OffsetSel   => DAU_OffsetSel_ID,
            DAU_IncDecSel   => DAU_IncDecSel_ID,
            DAU_IncDecBit   => DAU_IncDecBit_ID,
            DAU_PrePostSel  => DAU_PrePostSel_ID,
            DAU_GBRSel      => DAU_GBRSel_ID,
            DAU_VBRSel      => DAU_VBRSel_ID,

            -- RegArray Signals
            RegInSel        => RegInSel_ID,
            RegStore        => RegStore_ID,
            RegASel         => RegASel_ID,
            RegBSel         => RegBSel_ID,
            RegAxInSel      => RegAxInSel_ID,
            RegAxInDataSel  => RegAxInDataSel_ID,
            RegAxStore      => RegAxStore_ID,
            RegA1Sel        => RegA1Sel_ID,
            RegOpSel        => RegOpSel_ID,

            -- DTU signals
            RD => RD_ID,
            WR => WR_ID,
            DataAccessMode => DataAccessMode_ID,
            DBInMode => DBInMode_ID,

            -- IO signals
            DBOutSel    => DBOutSel_ID,
            ABOutSel    => ABOutSel_ID,

            -- Pipeline signals
            UpdateIR_EX => UpdateIR_EX,
            UpdateSR_EX => UpdateSR_EX,
            ForceNormalStateNext => ForceNormalStateNext

        );

end structural;