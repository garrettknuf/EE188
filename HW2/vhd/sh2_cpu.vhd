----------------------------------------------------------------------------
--
--  Hitachi SH-2 RISC Processor
--
--  This is an implementation of the Hitachi SH-2 RISC Processor.
--
--  Entities included are:
--    SH2_CPU - top level structural of CPU
--
--  Revision History:
--     16 April 2025    Garrett Knuf    Initial revision.
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.ALUConstants.all;
use work.TbitConstants.all;
use work.PAUConstants.all;
use work.DAUConstants.all;
use work.RegArrayConstants.all;
use work.CUConstants.all;

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
            ALUOpA   : in      std_logic_vector(LONG_SIZE - 1 downto 0);  -- first operand
            ALUOpB   : in      std_logic_vector(LONG_SIZE - 1 downto 0);  -- second operand
            Cin      : in      std_logic;                                 -- carry in
            FCmd     : in      std_logic_vector(3 downto 0);              -- F-Block operation
            CinCmd   : in      std_logic_vector(1 downto 0);              -- carry in operation
            SCmd     : in      std_logic_vector(3 downto 0);              -- shift operation
            ALUCmd   : in      std_logic_vector(1 downto 0);              -- ALU result select
            TbitOp   : in      std_logic_vector(3 downto 0);              -- T-bit operation
            Result   : buffer  std_logic_vector(LONG_SIZE - 1 downto 0);  -- ALU result
            Tbit     : out     std_logic                                  -- T-bit result
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
            RST         : in    std_logic;
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

    component CU is
        port (
            -- CU Input Signals
            CLK     : in    std_logic;
            RST     : in    std_logic;
            DB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
            SR      : in    std_logic_vector(REG_SIZE - 1 downto 0);
            AB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
            IR      : out    std_logic_vector(INST_SIZE - 1 downto 0);
            DBOutSel : out integer range 5 downto 0;
            ABOutSel : out integer range 1 downto 0;

            -- ALU Control Signals
            ALUOpASel   : out     integer range 1 downto 0;
            ALUOpBSel   : out     integer range 2 downto 0;
            FCmd        : out     std_logic_vector(3 downto 0);            
            CinCmd      : out     std_logic_vector(1 downto 0);            
            SCmd        : out     std_logic_vector(3 downto 0);            
            ALUCmd      : out     std_logic_vector(1 downto 0);
            TbitOp      : out     std_logic_vector(3 downto 0);

            -- StatusReg Control Signals
            UpdateTbit  : out   std_logic;

            -- PAU Control Signals
            PAU_SrcSel      : out   integer range PAU_SRC_CNT - 1 downto 0;
            PAU_OffsetSel   : out   integer range PAU_OFFSET_CNT - 1 downto 0;
            PAU_UpdatePC    : out   std_logic;
            PAU_UpdatePR    : out   std_logic;

            -- DAU Control Signals
            DAU_SrcSel      : out   integer range DAU_SRC_CNT - 1 downto 0;
            DAU_OffsetSel   : out   integer range DAU_OFFSET_CNT - 1 downto 0;
            DAU_IncDecSel   : out   std_logic;
            DAU_IncDecBit   : out   integer range 2 downto 0;
            DAU_PrePostSel  : out   std_logic;
            DAU_LoadGBR     : out   std_logic;

            -- RegArray Control Signals
            RegInSelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
            RegStore   : out   std_logic;
            RegASelCmd   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
            RegBSelCmd    : out   integer  range REGARRAY_RegCnt - 1 downto 0;
            RegAxInSelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
            RegAxStore : out   std_logic;
            RegA1SelCmd   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
            RegA2SelCmd   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
            RegOpSel   : out   integer  range REGOp_SrcCnt - 1 downto 0;
        
            -- IO Control signals
            RE0     : out   std_logic;
            RE1     : out   std_logic;
            RE2     : out   std_logic;
            RE3     : out   std_logic;
            WE0     : out   std_logic;
            WE1     : out   std_logic;
            WE2     : out   std_logic;
            WE3     : out   std_logic;

            DB_WR   : out std_logic
        );
    end component;

    -- ALU Signals
    signal ALUOpASel : integer range 1 downto 0;
    signal ALUOpBSel : integer range 2 downto 0;
    signal ALU_Cin       : std_logic;
    signal ALU_FCmd      : std_logic_vector(3 downto 0);
    signal ALU_CinCmd    : std_logic_vector(1 downto 0);
    signal ALU_SCmd      : std_logic_vector(3 downto 0);
    signal ALU_ALUCmd    : std_logic_vector(1 downto 0);
    signal ALU_TbitOp    : std_logic_vector(3 downto 0);
    signal ALU_Result    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal ALU_Tbit      : std_logic;

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
    signal SR_UpdateTbit     : std_logic;
    signal SR             : std_logic_vector(REG_SIZE - 1 downto 0);

    signal ALUOpA : std_logic_vector(LONG_SIZE-1 downto 0);
    signal ALUOpB : std_logic_vector(LONG_SIZE-1 downto 0);

    signal DBOutSel : integer range 5 downto 0;
    signal DBOut : std_logic_vector(DATA_BUS_SIZE-1 downto 0);

    signal ABOutSel : integer range 1 downto 0;

    signal IR : std_logic_vector(INST_SIZE-1 downto 0);

    signal DB_WR : std_logic;

    signal RegInSelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegASelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInSelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegA1SelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegA2SelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;

begin

    -- DAU inputs (non-control signals)
    DAU_Offset4 <= IR(3 downto 0);
    DAU_Offset8 <= IR(7 downto 0);
    DAU_Rn <= RegA1;
    DAU_R0 <= RegA2;
    DAU_PC <= PAU_PC;

    -- ALU inputs (non-control signals)
    ALUOpA <= RegA  when ALUOpASel = ALUOpASel_RegA else
              DB    when ALUOpASel = ALUOpASel_DB else
              (others => 'X');
    ALUOpB <= RegB  when ALUOpBSel = ALUOpBSel_RegB else
              (31 downto 8 => '0') & IR(7 downto 0) when ALUOpBSel = ALUOpBSel_Imm_Unsigned else
              (31 downto 8 => IR(7)) & IR(7 downto 0) when ALUOpBSel = ALUOpBSel_Imm_Signed else
              (others => 'X');
    ALU_Cin <= SR(0);

    -- PAU inputs (non-control signals)
    PAU_Offset8 <= IR(7 downto 0);
    PAU_Offset12 <= IR(11 downto 0);
    PAU_OffsetReg <= RegA1;

    -- RegArray inputs (non-control signals)
    RegIn <= ALU_Result;
    RegAxIn <= DAU_AddrIDOut;

    RegInSel <= to_integer(unsigned(IR(11 downto 8))) when RegInSelCmd = RegInSelCmd_Rn else 0;
    RegASel <= to_integer(unsigned(IR(11 downto 8))) when RegASelCmd = RegASelCmd_Rn else 0;
    RegBSel <= to_integer(unsigned(IR(7 downto 4)));

    RegA1Sel <= to_integer(unsigned(IR(11 downto 8))) when RegA1SelCmd = RegA1SelCmd_Rn else 0;

    DBOut <= ALU_Result when DBOutSel = DBOutSel_Result else
            --  SR when DBOutSel = DBOutSel_SR else
            --  DAU_GBR when DBOutSel = DBOutSel_GBR else
             -- ALU_Result when DBOutSel = DBOutSel_VBR else
            --  PAU_PR when DBOutSel = DBOutSel_PR else
            --  PAU_PC when DBOutSel = DBOutSel_PC else
             (others => 'X');

    DB <= DBOut when DB_WR = '0' else (others => 'Z');
    -- DB <= DBOut            when  (WE0 = '0' or WE1 = '0' or WE2 = '0' or WE3 = '0') else
    --       (others => 'Z')   when (RE0 = '0' or RE1 = '0' or RE2 = '0' or RE3 = '0') else
    --       (others => 'X');
    -- DB <= (others => 'Z');

    AB <= PAU_ProgAddr when ABOutSel = ABOutSel_Prog else
          DAU_DataAddr when ABOutSel = ABOutSel_Data else
          (others => 'X');
    -- AB <= PAU_ProgAddr;


    PAU_Offset8 <= IR(7 downto 0);
    PAU_Offset12 <= IR(11 downto 0);



    -- Create 32-bit ALU for standard logic and arithmetic operations
    SH2_ALU : ALU
        port map (
            ALUOpA  => ALUOpA,
            ALUOpB  => ALUOpB,
            Cin     => ALU_Cin,
            FCmd    => ALU_FCmd,
            CinCmd  => ALU_CinCmd,
            SCmd    => ALU_SCmd,
            ALUCmd  => ALU_ALUCmd,
            TbitOp  => ALU_TbitOp,
            Result  => ALU_Result,
            Tbit    => ALU_Tbit
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
            CLK         => clock,
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
            CLK        => clock,
            RST        => reset,
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
            CLK        => clock,
            AddrIDOut  => DAU_AddrIDOut,
            DataAddr   => DAU_DataAddr,
            GBR        => DAU_GBR
        );

    -- Status Register (SR)
    SH2_SR : StatusReg
        port map (
            Tbit        => ALU_Tbit,
            UpdateTbit  => SR_UpdateTbit,
            CLK         => clock,
            SR          => SR
        );

    -- Control Unit (CU)
    SH2_CU : CU
        port map (
            -- CU Input Signals
            CLK         => clock,
            RST         => reset,
            DB          => DB,
            AB          => AB,
            SR          => SR,
            IR          => IR,

            DBOutSel    => DBOutSel,
            ABOutSel    => ABOutSel,

            -- ALU Control Signals
            ALUOpASel   => ALUOpASel,
            ALUOpBSel   => ALUOpBSel,
            FCmd        => ALU_FCmd,
            CinCmd      => ALU_CinCmd,
            SCmd        => ALU_SCmd,
            ALUCmd      => ALU_ALUCmd,
            TbitOp      => ALU_TbitOp,

            -- StatusReg Control Signals
            UpdateTbit  => SR_UpdateTbit,

            -- PAU Control Signals
            PAU_SrcSel      => PAU_SrcSel,
            PAU_OffsetSel   => PAU_OffsetSel,
            PAU_UpdatePC    => PAU_UpdatePC,
            PAU_UpdatePR    => PAU_UpdatePR,

            -- DAU Control Signals
            DAU_SrcSel      => DAU_SrcSel,
            DAU_OffsetSel   => DAU_OffsetSel,
            DAU_IncDecSel   => DAU_IncDecSel,
            DAU_IncDecBit   => DAU_IncDecBit,
            DAU_PrePostSel  => DAU_PrePostSel,
            DAU_LoadGBR     => DAU_LoadGBR,

            -- RegArray Control Signals
            RegInSelCmd  => RegInSelCmd,
            RegStore     => RegStore,
            RegASelCmd   => RegASelCmd,
            RegBSelCmd   => RegBSelCmd,
            RegAxInSelCmd => RegAxInSelCmd,
            RegAxStore   => RegAxStore,
            RegA1SelCmd  => RegA1SelCmd,
            RegA2SelCmd  => RegA2SelCmd,
            RegOpSel     => RegOpSel,

            -- IO Control signals
            RE0 => RE0,
            RE1 => RE1,
            RE2 => RE2,
            RE3 => RE3,
            WE0 => WE0,
            WE1 => WE1,
            WE2 => WE2,
            WE3 => WE3,

            DB_WR => DB_WR
        );

end structural;
