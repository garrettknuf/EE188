----------------------------------------------------------------------------
--
--  Hitachi SH-2 RISC Processor
--
--  This file contains the complete top-level structural implementation of 
--  the Hitachi SH-2 RISC Processor. It includes instantations of all major
--  components: ALU, RegArray, CU, PAU, DAU, and DTU. It also implements a
--  five stage pipeline. The SH2_CPU entity defines the interface of the
--  processor and connects its internal subsystems in a structural
--  architecture. It is used for integration and testing of the full
--  processor design. The main resource for design is the SuperH RISC 
--  Engine SH-1/SH-2 Progamming Manual by Hitachi September 3, 1996.
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
    end component;

    component PAU is
        port (
            -- Control signals
            SrcSel      : in    integer range PAU_SRC_CNT - 1 downto 0;         -- source select
            OffsetSel   : in    integer range PAU_OFFSET_CNT - 1 downto 0;      -- offset select
            UpdatePC    : in    std_logic;                                      -- update PC or hold
            PRSel       : in    integer range PRSEL_CNT-1 downto 0;             -- select modify PR
            IncDecSel   : in    std_logic;                                      -- select inc/dec
            IncDecBit   : in    integer range 2 downto 0;                       -- select bit to inc/dec
            PrePostSel  : in    std_logic;                                      -- select decrement by 4

            -- Source inputs
            DB          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- data bus
            PC_EX       : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- pipelined PC (delayed by two clocks)

            -- Offset inputs
            Offset8     : in    std_logic_vector(7 downto 0);                   -- 8-bit offset
            Offset12    : in    std_logic_vector(11 downto 0);                  -- 12-bit offset
            OffsetReg   : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- register offest
            TempReg     : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- temporary register offset

            -- System signal
            CLK         : in    std_logic;                                      -- clock

            -- Output signals
            ProgAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program address
            PC          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program counter
            PR          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)    -- procedure register
        );
    end component;

    component DAU is
        port (
            -- Source inputs
            PC          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program counter
            Rn          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- generic register

            -- Offset inputs
            Offset4     : in    std_logic_vector(3 downto 0);                   -- 4-bit offset
            Offset8     : in    std_logic_vector(7 downto 0);                   -- 8-bit offset
            R0          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- register R0

            -- Data bus input
            DB          : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);   -- databus

            -- Control signals
            SrcSel      : in    integer range DAU_SRC_CNT - 1 downto 0;         -- source select
            OffsetSel   : in    integer range DAU_OFFSET_CNT - 1 downto 0;      -- offset select
            IncDecSel   : in    std_logic;                                      -- select inc/dec
            IncDecBit   : in    integer range 2 downto 0;                       -- select bit to inc/dec
            PrePostSel  : in    std_logic;                                      -- select pre/post
            GBRSel      : in    integer range GBRSel_CNT-1 downto 0;            -- select GBR
            VBRSel      : in    integer range VBRSel_CNT-1 downto 0;            -- select VBR
            CLK         : in    std_logic;                                      -- system clock
            RST         : in    std_logic;                                      -- system reset

            -- Output signals
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

            -- CU Registers TODO: IS IT VALID TO SET AN INITIAL VALUE?
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
            ForceNormalStateNext : in std_logic;
            BranchSel : out integer range BRANCHSEL_CNT-1 downto 0
        );
    end component;

    component DTU is
        port (
            -- Data input
            DBOut           : in    std_logic_vector(DATA_BUS_SIZE-1 downto 0);     -- data to output to DB

            -- Control inputs
            AB              : in    std_logic_vector(1 downto 0);                   -- address bus (least 2 significant bits)
            RD              : in    std_logic;                                      -- read enable (active-low)
            WR              : in    std_logic;                                      -- write enable (active-low)
            DataAccessMode  : in    integer range DATAACCESSMODE_CNT-1 downto 0;    -- select byte, word, long access
            DBInMode        : in    integer range DBINMODE_CNT-1 downto 0;          -- select signed or unsigned read
            CLK             : in    std_logic;                                      -- system clock

            -- Control outputs
            DBIn            : out   std_logic_vector(DATA_BUS_SIZE-1 downto 0);     -- data read from DB
            WE0             : out   std_logic;                                      -- write enable byte0
            WE1             : out   std_logic;                                      -- write enable byte1
            WE2             : out   std_logic;                                      -- write enable byte2
            WE3             : out   std_logic;                                      -- write enable byte3
            RE0             : out   std_logic;                                      -- read enable byte0
            RE1             : out   std_logic;                                      -- read enable byte1
            RE2             : out   std_logic;                                      -- read enable byte2
            RE3             : out   std_logic;                                      -- read enable byte3

            -- In/Out data bus
            DB              : inout std_logic_vector(DATA_BUS_SIZE-1 downto 0)      -- data bus
        );
    end component;


    -- ALU Signals
    -- Instruction Decode stage control signals
    signal ALUOpASel_ID    : integer range ALUOPASEL_CNT-1 downto 0;
    signal ALUOpBSel_ID    : integer range ALUOPBSEL_CNT-1 downto 0;
    signal ALU_FCmd_ID     : std_logic_vector(3 downto 0);
    signal ALU_CinCmd_ID   : std_logic_vector(1 downto 0);
    signal ALU_SCmd_ID     : std_logic_vector(2 downto 0);
    signal ALU_ALUCmd_ID   : std_logic_vector(1 downto 0);
    signal ALU_TbitOp_ID   : std_logic_vector(3 downto 0);
    -- Execute stage control signals
    signal ALUOpASel_EX    : integer range ALUOPASEL_CNT-1 downto 0;
    signal ALUOpBSel_EX    : integer range ALUOPBSEL_CNT-1 downto 0;
    signal ALU_FCmd_EX     : std_logic_vector(3 downto 0);
    signal ALU_CinCmd_EX   : std_logic_vector(1 downto 0);
    signal ALU_SCmd_EX     : std_logic_vector(2 downto 0);
    signal ALU_ALUCmd_EX   : std_logic_vector(1 downto 0);
    signal ALU_TbitOp_EX   : std_logic_vector(3 downto 0);
    -- Output signals
    signal ALU_Result    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal ALU_Tbit      : std_logic;


    -- RegArray Signals
    -- Instruction Decode stage control signals
    signal RegInSel_ID   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore_ID   : std_logic;
    signal RegASel_ID    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel_ID    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInSel_ID : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInDataSel_ID : integer range REGAXINDATASEL_CNT - 1 downto 0;
    signal RegAxStore_ID : std_logic;
    signal RegA1Sel_ID   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegOpSel_ID  : integer range REGOPSEL_CNT - 1 downto 0;
    -- Execute stage control signals
    signal RegInSel_EX   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore_EX   : std_logic;
    signal RegASel_EX    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel_EX    : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInSel_EX : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInDataSel_EX : integer range REGAXINDATASEL_CNT - 1 downto 0;
    signal RegAxStore_EX : std_logic;
    signal RegA1Sel_EX   : integer range REGARRAY_RegCnt - 1 downto 0;
    signal RegOpSel_EX  : integer range REGOPSEL_CNT - 1 downto 0;
    -- Output signals
    signal RegA       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegB       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA1      : std_logic_vector(LONG_SIZE - 1 downto 0);
    -- Input signals
    signal RegIn      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegAxIn    : std_logic_vector(LONG_SIZE - 1 downto 0);


    -- PAU Signals
    -- Instruction Decode stage control signals
    signal PAU_SrcSel_ID      : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel_ID   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal PAU_UpdatePC_ID    : std_logic;
    signal PAU_PRSel_ID       : integer range PRSEL_CNT-1 downto 0;
    signal PAU_IncDecSel_ID   : std_logic;
    signal PAU_IncDecBit_ID   : integer range 2 downto 0;
    signal PAU_PrePostSel_ID  : std_logic;
    -- Execute stage control signals
    signal PAU_SrcSel_EX      : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel_EX   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal PAU_UpdatePC_EX    : std_logic;
    signal PAU_PRSel_EX       : integer range PRSEL_CNT-1 downto 0;
    signal PAU_IncDecSel_EX   : std_logic;
    signal PAU_IncDecBit_EX   : integer range 2 downto 0;
    signal PAU_PrePostSel_EX  : std_logic;
    -- Output signals
    signal PAU_ProgAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PAU_OffsetReg   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PR              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    -- PC pipeline signals
    signal PC_ID              : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PC_EX           : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);


    -- DAU Signals
    -- Instruction Decode stage control signals
    signal DAU_SrcSel_ID      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel_ID   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4_ID     : std_logic_vector(3 downto 0);
    signal DAU_Offset8_ID     : std_logic_vector(7 downto 0);
    signal DAU_IncDecSel_ID   : std_logic;
    signal DAU_IncDecBit_ID   : integer range 2 downto 0;
    signal DAU_PrePostSel_ID  : std_logic;
    signal DAU_GBRSel_ID      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel_ID      : integer range VBRSEL_CNT-1 downto 0;
    -- Execute stage control signals
    signal DAU_SrcSel_EX      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel_EX   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4_EX     : std_logic_vector(3 downto 0);
    signal DAU_Offset8_EX     : std_logic_vector(7 downto 0);
    signal DAU_IncDecSel_EX   : std_logic;
    signal DAU_IncDecBit_EX   : integer range 2 downto 0;
    signal DAU_PrePostSel_EX  : std_logic;
    signal DAU_GBRSel_EX      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel_EX      : integer range VBRSEL_CNT-1 downto 0;
    -- Memory Access stage control signals
    signal DAU_SrcSel_MA      : integer range DAU_SRC_CNT - 1 downto 0;
    signal DAU_OffsetSel_MA   : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal DAU_Offset4_MA     : std_logic_vector(3 downto 0);
    signal DAU_Offset8_MA     : std_logic_vector(7 downto 0);
    signal DAU_IncDecSel_MA   : std_logic;
    signal DAU_IncDecBit_MA   : integer range 2 downto 0;
    signal DAU_PrePostSel_MA  : std_logic;
    signal DAU_GBRSel_MA      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel_MA      : integer range VBRSEL_CNT-1 downto 0;
    -- Input signals    
    signal DAU_Rn          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_R0          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_PC          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_IncDecSel   : std_logic;
    signal DAU_IncDecBit   : integer range 2 downto 0;
    signal DAU_PrePostSel  : std_logic;
    signal DAU_GBRSel      : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel      : integer range VBRSEL_CNT-1 downto 0;
    -- Output signals
    signal DAU_AddrIDOut   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_DataAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal GBR             : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal VBR             : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);


    -- DTU Signals
    -- Instruction Decode stage control signals
    signal DBInMode_ID         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode_ID   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR_ID : std_logic;
    signal RD_ID : std_logic;
    -- Execute stage control signals    
    signal DBInMode_EX         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode_EX   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR_EX : std_logic;
    signal RD_EX : std_logic;
    -- Memory Access stage control signals
    signal DBInMode_MA         : integer range DBINMODE_CNT-1 downto 0;
    signal DataAccessMode_MA   : integer range DATAACCESSMODE_CNT-1 downto 0;
    signal WR_MA : std_logic;
    signal RD_MA : std_logic;
    -- Output signals
    signal DBIn             : std_logic_vector(DATA_BUS_SIZE-1 downto 0);
    signal DBOut            : std_logic_vector(DATA_BUS_SIZE-1 downto 0);


    -- CU Signals
    -- Instruction Register (IR) pipeline
    signal IR_ID : std_logic_vector(INST_SIZE-1 downto 0);
    signal IR_EX : std_logic_vector(11 downto 0);
    signal IR_MA : std_logic_vector(11 downto 0);   -- reduce to 12 bits since we don't need the rest
    -- Update IR signal pipeline
    signal UpdateIR_ID : std_logic;
    signal UpdateIR_EX : std_logic;
    signal UpdateIR_MA : std_logic;
    -- Update SR pipeline
    signal UpdateSR_ID : std_logic;
    signal UpdateSR_EX : std_logic;
    -- Output signals
    signal SR : std_logic_vector(REG_SIZE-1 downto 0);
    signal TempReg : std_logic_vector(31 downto 0);
    signal TempReg2 : std_logic_vector(31 downto 0);


-- Top-level pipeline signals

    -- SH2 CPU bus pipelines
    -- Data bus pipeline
    signal DB_PL : std_logic_vector(DATA_BUS_SIZE-1 downto 0);   -- for stalling databus in memory access stage
    -- Address bus pipeline
    signal AB_PL : std_logic_vector(1 downto 0); -- additonal information for instruction register stalling 

    -- SH2 CPU bus control signal pipelines
    -- Databus out selection pipeline
    signal DBOutSel_ID : integer range DBOUTSEL_CNT-1 downto 0;
    signal DBOutSel_EX : integer range DBOUTSEL_CNT-1 downto 0;
    signal DBOutSel_MA : integer range DBOUTSEL_CNT-1 downto 0;
    -- Address bus out selection pipeline
    signal ABOutSel_ID : integer range 1 downto 0;
    signal ABOutSel_EX : integer range 1 downto 0;
    signal ABOutSel_MA : integer range 1 downto 0;

-- Top-level pipeline state signals and muxes
--      The following signals are used to describe, redirect, or delay the flow of the pipeline
--          This could be caused by special cases such as:
--              - Memory access
--              - Branching
--              - Pipeline flush
--              - Pipeline stall

    -- Signal that indicates if a branch should be taken
    signal TakeBranch : std_logic;
    -- Signal that indicates if the pipeline should be flushed
    signal FlushPL : std_logic;
    -- Signal that indicates if the control unit should enforce a normal state in the next ID cycle
    signal ForceNormalStateNext : std_logic;
    -- Branch type selection signal pipeline (This is a CU control signal so it might belong up in another section)
    signal BranchSel_ID : integer range BRANCHSEL_CNT-1 downto 0;
    signal BranchSel_EX : integer range BRANCHSEL_CNT-1 downto 0;

    -- Control Unit (CU) input pipeline control signals 
    --      The control unit handles the transition between the Insruction Fetch (IF) stage
    --      and the Instruction Decode (ID) stage. 
    --      
    --      In case of a memory access, the required IF -> ID information stored within
    --      DB and AB will experience a pipeline stall determined by the output of the 
    --      following mux outputs:
    signal DBMux : std_logic_vector(DATA_BUS_SIZE-1 downto 0);   -- DB or DB_PL in case of stall
    signal ABMux : std_logic_vector(1 downto 0);     -- AB(1 downto 0) or AB_PL in case of stall


    -- Program Memory Access Unit (PAU) input pipeline control signals 
    --      The PAU requires different pipelined input sources in the case of branches.
    --      These will be determined by the output of the following mux outputs:
    signal PAU_SrcSel_Mux   : integer range PAU_SRC_CNT - 1 downto 0;
    signal PAU_OffsetSel_Mux   : integer range PAU_OFFSET_CNT - 1 downto 0;


begin

    -- This process contains the combinational logic for the pipeline state signals and muxes.
    -- Relevant control signals:
    --      - TakeBranch signal
    --      - FlushPL signal
    --      - ForceNormalStateNext signal
    -- Relevant muxes:
    --      - PAU primary source selection mux
    --      - PAU offset selection mux
    --      - CU input signal mux (delay toggle mux)
    Branching  : process (all)
    begin

    -- Determine branch pipeline state signal
        if BranchSel_EX = BranchSel_BF or BranchSel_EX = BranchSel_BFS then            
            -- Detect false conditional branches
            -- NOTE: SR is the clocked status register in CU, not the ALU output
            TakeBranch <= '1' when SR(0) = '0' else '0';
        elsif BranchSel_EX = BranchSel_BT or BranchSel_EX = BranchSel_BTS then
            -- Detect true conditional branches
            TakeBranch <= '1' when SR(0) = '1' else '0';
        elsif BranchSel_EX /= BranchSel_None then
            -- Detect unconditional branches
            TakeBranch <= '1';
        else
            -- No branch taken
            TakeBranch <= '0';
        end if;

    -- Determine flush pipeline state signal if taking successful conditional branch
        if TakeBranch = '1' and (BranchSel_EX = BranchSel_BF or BranchSel_EX = BranchSel_BT) then
            FlushPL <= '1';
        else
            FlushPL <= '0';
        end if;

    -- Determine force normal state next signal
        -- If a branch is taken, the next state should be forced to normal
        ForceNormalStateNext <= '1' when TakeBranch = '1' else '0';



    -- CU/IF input signal muxes
        --  The input to the CU should always be directly from DB and AB unless it is 
        --  being stalled. UpdateIR = '0' signifies a memory access operation,
        --  so when such a signal reaches the MA stage, an IF pipeline stall is occuring
        --  and the CU should receive the pipeline delayed signal.
        DBMux <= DB_PL when UpdateIR_MA = '0' else DB;  -- (PL signals stored when UpdateIR_EX = '0')
        ABMux <= AB_PL when UpdateIR_MA = '0' else AB(1 downto 0);

    -- PAU input signal muxes
        --  If a branch was taken, the input to the PAU source and PAU offset
        --  should correspond to the specific branch type.
        if TakeBranch = '1' then
            if (BranchSel_EX = BranchSel_Always) then
                -- Pipelined PC value is used for unconditional branches
                PAU_SrcSel_Mux <= PAU_AddrPC_EX;
            elsif (BranchSel_EX = BranchSel_RET) then
                -- Procedure Register (PR) is used for return instructions
                PAU_SrcSel_Mux <= PAU_AddrPR;
            elsif (BranchSel_EX = BranchSel_JUMP) then
                -- Zero address is used for jump instructions
                PAU_SrcSel_Mux <= PAU_AddrZero;
            else
                -- All other branches use the pipelined PC value
                PAU_SrcSel_Mux <= PAU_AddrPC_EX;
            end if;
        else
            -- If no branch is taken, the PAU the normal pipelined control signal
            PAU_SrcSel_Mux <= PAU_SrcSel_EX;
        end if;

        -- In most cases, PAU_OffsetSel_EX will contain a branch's offset selection.
        -- PAU_OffsetSel_EX is computed in the clocked pipeline procedure.
        if (BranchSel_EX = BranchSel_BF or BranchSel_EX = BranchSel_BT or 
                BranchSel_EX = BranchSel_BFS or BranchSel_EX = BranchSel_BTS) then
            -- Offset selection should be overridden if conditional branch is taken
            PAU_OffsetSel_Mux <= PAU_OffsetSel_EX when TakeBranch = '1' else PAU_OffsetWord;
        elsif (BranchSel_EX = BranchSel_Always) then
            -- Override offset selection for unconditional branches
            PAU_OffsetSel_Mux <= PAU_OffsetSel_EX;
        elsif (BranchSel_EX = BranchSel_JUMP) then
            -- Override offset selection for jump instructions
            PAU_OffsetSel_Mux <= PAU_OffsetSel_EX;
            -- PAU_OffsetSel_Mux <= PAU_OffsetReg;
        else
            -- If no branch is taken, simply increment PC
            PAU_OffsetSel_Mux <= PAU_OffsetWord;
        end if;
        
    end process;


    -- This process contains the behavior of clocked DFFs in the pipeline
    -- and determines when each stage's registers are updated or stalled.
    Pipeline : process (clock)
    begin
        -- Pass on signals from one stage to another stage on rising clock
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



    -- Define pipeline operation
    --  There are five stages in the pipeline:
    --      1. Instruction Fetch (IF)
    --      2. Instruction Decode (ID)
    --      3. Execution (EX)
    --      4. Memory Access (MA)
    --      5. Write Back (WB)
    --
    --  1) The IF stage's operation is defined by the PAU's PC output determined
    --  by the PAU control signals and the address selection signal (ABOutSel) being
    --  set to ABOutSel_Prog. All of these signals are pipelined. This results in the
    --  data bus input fetching an instruction from program memory. To delay the IF
    --  stage, the databus and address bus signals that go into the CU are pipelined
    --  to delay the signals from reaching the next stage (ID).
    --      IF Stage Flow Diagram:
    --  PMAU Control Signals -> PC + ABOutSel_Prog -> DB + AB (may be PL delayed) -> CU (IR)
    --
    --  2) The ID stage's operation is mostly handled by the CU's internal IR
    --  register decode logic. Most ID stage signals are output by the CU with the
    --  notible exception of PC which is output from the PAU when a previous instruction's
    --  PAU control signals reach the EX stage.
    --      ID Stage Flow Diagram:
    --  CU (IR) -> ALUcmds_ID, REGcmds_ID, PAUcmds_ID, MAUcmds_ID, DTUcmds_ID, CUcmds_ID
    --  PAUcmds_EX -> PAU -> PC_ID
    -- 
    --  3) The EX stage's operation is the clocking of ID signals through a DFF.
    --  At this stage of the pipeline, signals finally reach the ALU, REG, PAU, and DAU
    --  components and the corresponding instruction's signals can finally be processed.
    --  However, certain signals might need to be delayed and pipeline stalled by
    --  preventing the transition of the ID stage signals to the EX stage.
    --      EX Stage Flow Diagram:
    --  DEF: X = ALUcmds or REGcmds or PAUcmds or DAUcmds or DTUcmds or CUcmds or PCcmds
    --  X_ID (possible delay)-> X_EX
    --
    --  4) The MA stage's operation is the clocking of the EX stage signals through a DFF.
    --  This stage of the pipeline is not guaranteed for all instructions, and is only
    --  valid for instructions that access memory. This is conveniently denoted by the 
    --  instuction's UpdateIR signal. If UpdateIR is '1', then the instruction does not
    --  access memory. If it is '0', then memory should be accessed and the DTU control
    --  signals can transition from the EX stage to the MA stage where they reach DTU.
    --  While the MA stage is active, it will be in contention with the IF stage since
    --  both require memory access. As a result, a valid MA stage will result in all
    --  other pipeline stages execpt for WB to be stalled one clock cycle.
    --      MA Stage Flow Diagram: 
    --  DEF: X = ALUcmds or REGcmds or PAUcmds or DAUcmds or DTUcmds or CUcmds or PCcmds
    --  IF signals (delay if MA valid aka UpdateIR is '0')-> CU (IR)
    --  TODO: Decide if you need to document a NOP insertion delay
    --  CU (IR) (delay if MA valid aka UpdateIR is '0') -> X_ID
    --  X_ID (delay if MA valid aka UpdateIR is '0') -> X_EX
    --  DTUcmds_EX -> DTUcmds_MA -> DTU -> External memory unit access
    --  
    --  5) The WB stage's operation is the directing of stalled EX stage signals into 
    --  a component that requires the data accessed in the MA stage. This is only
    --  applicable to instructions that access memory and use the read memory in their
    --  operation. This write back might be in contention with another instruction's
    --  EX stage if both are accessing the same register. In this case, the WB stage
    --  takes priority and the EX stage instruction is stalled, along with the all
    --  other stages.
    --  TODO: Decide if you need to document an indicator signal
    --      WB Stage Flow Diagram:
    --  DEF: X = ALUcmds or REGcmds or PAUcmds or DAUcmds or DTUcmds or CUcmds or PCcmds
    --  IF signals (delay if WB contention)-> CU (IR)
    --  TODO: Decide if you need to document a NOP insertion delay
    --  CU (IR) (delay if WB contention) -> X_ID
    --  X_ID (delay if WB contention) -> X_EX
    --  DTUcmds_EX -> DTUcmds_MA -> DTU -> External memory unit access
    --  X_EX + Memory databus (If valid WB signal) -> Component with target register
            else

            -- Pipeline signals that ALWAYS transition to next stage on rising clock
            -- TODO: Comments here are inaccurate, must fix

                -- UpdateIR (!memory access indicator)
                -- Indicate no mem access in EX stage if pipeline is flushed
                -- TODO: possible bug
                UpdateIR_EX <= UpdateIR_ID when FlushPL = '0' else '1';
                UpdateIR_MA <= UpdateIR_EX;

                -- SH2 CPU bus output control signals (ID -> EX -> MA)
                DBOutSel_EX <= DBOutSel_ID; -- select databus output
                DBOutSel_MA <= DBOutSel_EX; -- (ALUresult, PC, SR, PR, GBR, VBR)

                ABOutSel_EX <= ABOutSel_ID; -- select addressbus output
                ABOutSel_MA <= ABOutSel_EX; -- (PAU or DAU)

                -- DTU control signals (ID -> EX -> MA)
                DBInMode_EX <= DBInMode_ID;
                DBInMode_MA <= DBInMode_EX;
                DataAccessMode_EX <= DataAccessMode_ID;
                DataAccessMode_MA <= DataAccessMode_EX;
                -- EX stage DTU RD/WR control signals are set to read in case of flush
                RD_EX <= RD_ID when FlushPL = '0' else '0';                
                RD_MA <= RD_EX;
                WR_EX <= WR_ID when FlushPL = '0' else '1';
                WR_MA <= WR_EX;
                

            --
            --    Memory Access Instuction in Execution Stage
            --
            --  cycle |   1  |   2  |   3  ->   4  |   5  |
            --  ins_1 |  IF  |  ID  |  EX  ->  MA  |  WB  | 
            --  ins_2 |         IF  |  ID  ->  --  |  EX  |
            --  ins_3 |                IF  ->  --  |  ID  |
            --  ins_4 |                        --  |  IF  |
            --
            --
            --  If a memory access instruction has reached the
            --  EX stage, indicated by UpdatesIR_EX = '0', then
            --  the EX, ID, and IF stages should be stalled 
            --  upon the next clock and specific preparations
            --  should occur. If UpdatesIR_EX = '1' instead, 
            --  then the pipeline should proceed as normal
            --  with the IF, ID, and EX stages all getting their
            --  values updated.
            --
            --  In the event of a flush, the pipeline should retain its values.
            --
            --      Signals passed from Instruction Decode to Execution stage:
            --          - ALU control signals
            --          - RegArray control signals
            --          - DAU control signals
            --          - **Update status register signal
            --          - **Instruction register data
            --      Missing signals:
            --          - PAU control signals
            --          - Pipelined PC signal
            --          - **Branch type selection control signal
            --
            --  ** means lone signals

                -- No memory access instruction in Execution Stage
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
                    RegStore_EX <= RegStore_ID when FlushPL = '0' else '0';
                    RegASel_EX <= RegASel_ID;
                    RegBSel_EX <= RegBSel_ID;
                    RegAxInSel_EX <= RegAxInSel_ID;
                    RegAxInDataSel_EX <= RegAxInDataSel_ID;
                    RegAxStore_EX <= RegAxStore_ID when FlushPL = '0' else '0';
                    RegA1Sel_EX <= RegA1Sel_ID;
                    RegOpSel_EX <= RegOpSel_ID;

                    -- DAU control signals
                    DAU_SrcSel_EX <= DAU_SrcSel_ID when FlushPL = '0' else DAU_SrcSel_EX;
                    DAU_OffsetSel_EX <= DAU_OffsetSel_ID when FlushPL = '0' else DAU_OffsetSel_EX;                    
                    DAU_Offset4_EX <= DAU_Offset4_ID when FlushPL = '0' else DAU_Offset4_EX;
                    DAU_Offset8_EX <= DAU_Offset8_ID when FlushPL = '0' else DAU_Offset8_EX;                    
                    DAU_IncDecSel_EX <= DAU_IncDecSel_ID when FlushPL = '0' else DAU_IncDecSel_EX;
                    DAU_IncDecBit_EX <= DAU_IncDecBit_ID when FlushPL = '0' else DAU_IncDecBit_EX;
                    DAU_PrePostSel_EX <= DAU_PrePostSel_ID when FlushPL = '0' else DAU_PrePostSel_EX;
                    DAU_GBRSel_EX <= DAU_GBRSel_ID when FlushPL = '0' else GBRSel_None;
                    DAU_VBRSel_EX <= DAU_VBRSel_ID when FlushPL = '0' else VBRSel_None;

                    -- Update status register signal
                    UpdateSR_EX <= UpdateSR_ID when FlushPL = '0' else '0';

                    -- Instruction register data
                    IR_EX <= IR_ID(11 downto 0);


                -- Memory access instruction detected in EX Stage
                else 

                    -- Stall IF stage by updating the PAU control signals this keeps PC
                    -- at its current value in the next cycle?? NOT IMPLEMENTED

                    -- Prepare to stall ID stage by saving the current IF control signals 
                    -- (data and address bus) to their pipeline registers so that they
                    -- are reused in the next cycle.
                    DB_PL <= DB when UpdateIR_EX = '0';
                    AB_PL <= AB(1 downto 0) when UpdateIR_EX = '0';
                    -- PROBABLY CAN GET RID OF THIS

                    -- Stall EX stage by not clocking in the current ID stage signals
                    
                end if;


            --
            --    Memory Access Instuction in Memory Access Stage
            --
            --  If a memory access instruction has reached the
            --  MA stage, indicated by UpdatesIR_MA = '0',  then the
            --  EX, ID, and IF stages are in the process of being
            --  stalled. The pipeline should then prepare for one
            --  of three possible cases determined by the WriteBack 
            --  and WB_EX_Contention signals:
            --
            --  1) WriteBack = '0', WB_EX_Contention = '0'
            --  cycle |   1  |   2  |   3  |   4  |    5  |
            --  ins_1 |  IF  |  ID  |  EX  |  MA          | 
            --  ins_2 |         IF  |  ID  |  --  ->  EX  |
            --  ins_3 |                IF  |  --  ->  ID  |
            --  ins_4 |                       --  ->  IF  |
            --
            --  In this case, the pipeline should prepare to
            --  return to normal operation by pushing the IF,
            --  ID, and EX stages down the pipeline.
            --
            --  2) WriteBack = '1', WB_EX_Contention = '0'
            --  cycle |   1  |   2  |   3  |   4  ->   5  |
            --  ins_1 |  IF  |  ID  |  EX  |  MA  ->  WB  | 
            --  ins_2 |         IF  |  ID  |  --  ->  EX  |
            --  ins_3 |                IF  |  --  ->  ID  |
            --  ins_4 |                       --  ->  IF  |
            --
            --  In this case, the pipeline should prepare to
            --  return to normal operation by pushing the IF,
            --  ID, and EX stages down the pipeline while
            --  also routing the WB signals to their intended
            --  destination.
            --
            --  3) WriteBack = '1', WB_EX_Contention = '1'
            --  cycle |   1  |   2  |   3  |   4  ->   5  |   6  |
            --  ins_1 |  IF  |  ID  |  EX  |  MA  ->  WB  |      |
            --  ins_2 |         IF  |  ID  |  --  ->  --  |  EX  |
            --  ins_3 |                IF  |  --  ->  --  |  ID  |
            --  ins_4 |                       --  ->  --  |  IF  |
            --
            --  In this case, the pipeline should continue to
            --  stall the EX, ID, and IF stages while also
            --  routing the WB signals to their intended
            --  destination.
            --
            --  If instead there is no detected memory access 
            --  instruction in the MA stage (UpdatesIR_MA = '1'),
            --  then the pipeline should operate as normal and
            --  propagate all stages.
            --  
            --  No memory access instruction in MA Stage (UpdatesIR_MA = '1')
            --  cycle |   1  |   2  |   3  |   4  |   5   |
            --  ins_1 |  IF  |  ID  |  EX  |
            --  ins_2 |         IF  |  ID  |  EX  |
            --  ins_3 |                IF  |  ID  ->  EX  |
            --  ins_4 |                       IF  ->  ID  |
            --
            --  For some reason PAU control signals, the branch
            --  type selection control signal, and the pipelined
            --  PC signal pipelines from the ID stage to the EX
            --  stage are controlled here. Additionally, the IR
            --  bit information signal and the DAU control signals
            --  should be pipelined from the EX stage to the MA stage.
            --              
            --  
            --  In the event of a flush, TODO: Figure this out later.
            --
            --      Signals passed from Instruction Decode to Execution stage:
            --          - PAU control signals
            --          - Pipelined PC signal
            --          - **Branch type selection control signal
            --
            --      Signals passed from Execution to Memory Access stage:
            --          - Instruction register data
            --          - DAU control signals
            --
            --  ** means lone signals

                -- No memory access instruction in MA Stage
                if UpdateIR_MA = '1' then

                    -- Branch type selection control signal
                    BranchSel_EX <= BranchSel_ID when FlushPL = '0' else BranchSel_None;

                    -- PAU control signals
                    PAU_UpdatePC_EX <= PAU_UpdatePC_ID;
                    PAU_PRSel_EX <= PAU_PRSel_ID when FlushPL = '0' else PRSel_None;
                    PAU_IncDecSel_EX <= PAU_IncDecSel_ID;
                    PAU_IncDecBit_EX <= PAU_IncDecBit_ID;
                    PAU_PrePostSel_EX <= PAU_PrePostSel_ID;
                    -- PAU input sources change when branch is taken                   
                    PAU_SrcSel_EX <= PAU_SrcSel_ID when TakeBranch = '0' else PAU_AddrPC;
                    PAU_OffsetSel_EX <= PAU_OffsetSel_ID when TakeBranch = '0' else PAU_OffsetWord;    

                   -- Pipelined PC signal
                    PC_EX <= PC_ID when FlushPL = '0' else AB;



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

            end if; -- reset = '0'

        end if; -- rising_edge(clock);

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


-- SH2 CPU Component Implementation and Port Mapping
--  Create the all SH2 CPU component and map the ports to the internal signals.

    -- Create 32-bit ALU for standard logic and arithmetic operations
    SH2_ALU : ALU
        port map (
            -- Operand signals (inputs)
            RegA        => RegA,
            RegB        => RegB,
            TempReg     => TempReg2,
            Imm         => IR_EX(7 downto 0),
            DBIn        => DBIn,
            SR0         => SR(0),

            -- Control signals (inputs)
            ALUOpASel   => ALUOpASel_EX,
            ALUOpBSel   => ALUOpBSel_EX,
            FCmd        => ALU_FCmd_EX,
            CinCmd      => ALU_CinCmd_EX,
            SCmd        => ALU_SCmd_EX,
            ALUCmd      => ALU_ALUCmd_EX,

            -- Output signals            
            TbitOp      => ALU_TbitOp_EX,
            Result      => ALU_Result,
            Tbit        => ALU_Tbit
        );

    -- Create 32-bit register array with general purpose registers R0-R15
    SH2_RegArray : RegArray
        port map (
            -- RegIn input
            Result          => ALU_Result,

            -- RegAxIn inputs
            DataAddrID      => DAU_AddrIDOut,
            DataAddr        => DAU_DataAddr,
            SR              => SR,
            GBR             => GBR,
            VBR             => VBR,
            PR              => PR,

            -- Control signals (inputs)
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

            -- Register outputs
            RegA            => RegA,
            RegB            => RegB,
            RegA1           => RegA1
        );

    -- Create Program Memory Access Unit (PAU)
    SH2_PAU : PAU
        port map (
            -- Control signals
            SrcSel     => PAU_SrcSel_Mux,
            OffsetSel  => PAU_OffsetSel_Mux,
            UpdatePC   => PAU_UpdatePC_EX,
            PRSel      => PAU_PRSel_EX,
            IncDecSel  => PAU_IncDecSel_EX,
            IncDecBit  => PAU_IncDecBit_EX,
            PrePostSel => PAU_PrePostSel_EX,

            -- Source inputs
            DB         => DB,
            PC_EX      => PC_EX,

            -- Offset inputs
            Offset8    => IR_EX(7 downto 0),
            Offset12   => IR_EX(11 downto 0),
            OffsetReg  => RegA1,
            TempReg    => TempReg,

            -- System signal
            CLK        => clock,

            -- Output signals
            ProgAddr   => PAU_ProgAddr,
            PC         => PC_ID,
            PR         => PR
        );

    -- Create Data Memory Access Unit (DAU)
    SH2_DAU : DAU
        port map (
            -- Source inputs
            PC         => PC_ID,
            Rn         => RegA1,

            -- Offset inputs
            Offset4    => IR_EX(3 downto 0),
            Offset8    => IR_EX(7 downto 0),
            R0         => RegA,

            -- Data inputs
            DB         => DB,

            -- Control signals
            SrcSel     => DAU_SrcSel_EX,
            OffsetSel  => DAU_OffsetSel_EX,
            IncDecSel  => DAU_IncDecSel_EX,
            IncDecBit  => DAU_IncDecBit_EX,
            PrePostSel => DAU_PrePostSel_EX,
            GBRSel     => DAU_GBRSel_EX,
            VBRSel     => DAU_VBRSel_EX,
            CLK        => clock,
            RST        => Reset,

            -- Output signals
            AddrIDOut  => DAU_AddrIDOut,
            DataAddr   => DAU_DataAddr,
            GBR        => GBR,
            VBR        => VBR
        );

    -- Create Data Transfer Unit (DTU) to interface with memory
    SH2_DTU : DTU
        port map (
            -- Data input
            DBOut           => DBOut,

            -- Control inputs
            AB              => AB(1 downto 0),
            RD              => RD_MA,
            WR              => WR_MA,
            DataAccessMode  => DataAccessMode_MA,
            DBInMode        => DBInMode_MA,
            CLK             => clock,

            -- Control outputs
            DBIn            => DBIn,
            WE0             => WE0,
            WE1             => WE1,
            WE2             => WE2,
            WE3             => WE3,
            RE0             => RE0,
            RE1             => RE1,
            RE2             => RE2,
            RE3             => RE3,

            -- In/Out data bus
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
            ForceNormalStateNext => ForceNormalStateNext,
            BranchSel => BranchSel_ID
        );

end structural;