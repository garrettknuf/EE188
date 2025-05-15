----------------------------------------------------------------------------
--
--  SH-2 Control Unit
--
--  This is an implementation of 
--
--  Entities included are:
--    
--
--  Revision History:
--     18 April 2025    Garrett Knuf    Initial revision.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the control unit.
--

library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;
use work.RegArrayConstants.all;

package CUConstants is

    -- RegInSel - select where to save input to RegIn
    constant REGINSELCMD_CNT   : integer := 3;
    constant RegInSelCmd_Rn    : integer range REGINSELCMD_CNT-1 downto 0 := 0;    -- generic register
    constant RegInSelCmd_R0    : integer range REGINSELCMD_CNT-1 downto 0 := 1;    -- register R0
    constant RegInSelCmd_R15   : integer range REGINSELCMD_CNT-1 downto 0 := 2;    -- register R15

    -- RegASelCmd - select what RegA outputs
    constant RegASelCmd_Rn : integer range 2 downto 0 := 0;     -- generic register
    constant RegASelCmd_DB : integer range 2 downto 0 := 1;     -- databus
    constant RegASelCmd_R0 : integer range 2 downto 0 := 2;     -- register R0

    -- RegBSelCmd - select what RegB outputs
    constant RegBSelCmd_Rm : integer range 2 downto 0 := 0;     -- generic register
    constant RegBSelCmd_R0 : integer range 2 downto 0 := 1;     -- register R0
    constant RegBSelCmd_Rn : integer range 2 downto 0 := 2;     -- generic register
    
    -- RegA1SelCmd - select what RegA1 outputs
    constant RegA1SelCmd_CNT : integer := 4;
    constant RegA1SelCmd_Rn  : integer range RegA1SelCmd_CNT-1 downto 0 := 0;
    constant RegA1SelCmd_Rm  : integer range RegA1SelCmd_CNT-1 downto 0 := 1;
    constant RegA1SelCmd_R0  : integer range RegA1SelCmd_CNT-1 downto 0 := 2;
    constant RegA1SelCmd_R15 : integer range RegA1SelCmd_CNT-1 downto 0 := 3;

    -- RegAxInSelCmd - select what RegA1 outputs
    constant RegAxInSelCmd_CNT : integer := 4;
    constant RegAxInSelCmd_Rn  : integer range RegAxInSelCmd_CNT-1 downto 0 := 0;
    constant RegAxInSelCmd_Rm  : integer range RegAxInSelCmd_CNT-1 downto 0 := 1;
    constant RegAxInSelCmd_R0  : integer range RegAxInSelCmd_CNT-1 downto 0 := 2;
    constant RegAxInSelCmd_R15 : integer range RegAxInSelCmd_CNT-1 downto 0 := 3;

    -- DBOutSel - select output of databus
    constant DBOUTSEL_CNT    : integer := 6;
    constant DBOutSel_Result : integer range DBOUTSEL_CNT-1 downto 0 := 0;
    constant DBOutSel_SR     : integer range DBOUTSEL_CNT-1 downto 0 := 1;
    constant DBOutSel_GBR    : integer range DBOUTSEL_CNT-1 downto 0 := 2;
    constant DBOutSel_VBR    : integer range DBOUTSEL_CNT-1 downto 0 := 3;
    constant DBOutSel_PR     : integer range DBOUTSEL_CNT-1 downto 0 := 4;
    constant DBOutSel_PC     : integer range DBOUTSEL_CNT-1 downto 0 := 5;

    -- ABSel - select output of address bus
    constant ABOutSel_Prog : integer range 1 downto 0 := 0;
    constant ABOutSel_Data : integer range 1 downto 0 := 1;

    constant TempRegSel_CNT      : integer := 5;
    constant TempRegSel_Offset8  : integer range TempRegSel_CNT-1 downto 0 := 0;
    constant TempRegSel_Offset12 : integer range TempRegSel_CNT-1 downto 0 := 1;
    constant TempRegSel_RegB     : integer range TempRegSel_CNT-1 downto 0 := 2;
    constant TempRegSel_Result   : integer range TempRegSel_CNT-1 downto 0 := 3;
    constant TempRegSel_DataBus  : integer range TempRegSel_CNT-1 downto 0 := 4;

    constant StatusReg_Tbit     : integer := 0; -- T bit
    constant StatusReg_Sbit     : integer := 1; -- S bit
    constant StatusReg_I0bit    : integer := 4; -- Interrupt mask I0
    constant StatusReg_I1bit    : integer := 5; -- Interrupt mask I1
    constant StatusReg_I2bit    : integer := 6; -- Interrupt mask I2
    constant StatusReg_I3bit    : integer := 7; -- Interrupt mask I3
    constant StatusReg_Qbit     : integer := 8; -- Q bit
    constant StatusReg_Mbit     : integer := 9; -- M bit

    constant SRSEL_CNT  : integer := 4;
    constant SRSel_Tbit : integer range SRSEL_CNT-1 downto 0 := 0;
    constant SRSel_DB   : integer range SRSEL_CNT-1 downto 0 := 1;
    constant SRSel_Reg  : integer range SRSEL_CNT-1 downto 0 := 2;
    constant SRSel_Tmp2 : integer range SRSEL_CNT-1 downto 0 := 3;

    constant unused : integer := 0;

end package;


--
--
--
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.DTUConstants.all;
use work.CUConstants.all;
use work.ALUConstants.all;
use work.GenericALUConstants.all;
use work.MemUnitConstants.all;
use work.DAUConstants.all;
use work.PAUConstants.all;
use work.RegArrayConstants.all;
use work.OpcodeConstants.all;

entity CU is

    port (
        -- CU Input Signals
        CLK     : in    std_logic;
        RST     : in    std_logic;
        DB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
        AB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
        Result      : in  std_logic_vector(LONG_SIZE - 1 downto 0);   -- ALU result
        Tbit    : in    std_logic;
        IR      : out   std_logic_vector(INST_SIZE - 1 downto 0) := x"DEAD";
        

        -- ALU Control Signals
        ALUOpASel   : out     integer range ALUOPASEL_CNT-1 downto 0 := 0;
        ALUOpBSel   : out     integer range ALUOPBSEL_CNT-1 downto 0 := 0;
        FCmd        : out     std_logic_vector(3 downto 0);            
        CinCmd      : out     std_logic_vector(1 downto 0);            
        SCmd        : out     std_logic_vector(2 downto 0);            
        ALUCmd      : out     std_logic_vector(1 downto 0);
        TbitOp      : out     std_logic_vector(3 downto 0);

        -- PAU Control Signals
        PAU_SrcSel      : out   integer range PAU_SRC_CNT - 1 downto 0;
        PAU_OffsetSel   : out   integer range PAU_OFFSET_CNT - 1 downto 0;
        PAU_UpdatePC    : out   std_logic;
        PAU_PRSel       : out   integer range PRSEL_CNT-1 downto 0;
        PAU_IncDecBit   : out   integer range 2 downto 0;
        PAU_IncDecSel   : out   std_logic;
        PAU_PrePostSel  : out   std_logic;

        -- DAU Control Signals
        DAU_SrcSel      : out   integer range DAU_SRC_CNT - 1 downto 0;
        DAU_OffsetSel   : out   integer range DAU_OFFSET_CNT - 1 downto 0;
        DAU_IncDecSel   : out   std_logic;
        DAU_IncDecBit   : out   integer range 2 downto 0;
        DAU_PrePostSel  : out   std_logic;
        DAU_GBRSel      : out   integer range GBRSEL_CNT-1 downto 0;
        DAU_VBRSel      : out   integer range VBRSEL_CNT-1 downto 0;

        -- RegArray Control Signals
        RegInSel        : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegStore        : out   std_logic;
        RegASel         : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegBSel         : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxInSel      : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxInDataSel  : out   integer range REGAXINDATASEL_CNT - 1 downto 0;
        RegAxStore      : out   std_logic;
        RegA1Sel        : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegOpSel        : out   integer  range REGOPSEL_CNT - 1 downto 0;
    
        -- IO Control signals
        DBOutSel : out integer range DBOUTSEL_CNT-1 downto 0;
        ABOutSel : out integer range 1 downto 0;
        DBInMode : out integer range 1 downto 0;
        RD     : out   std_logic;
        WR     : out   std_logic;
        DataAccessMode : out integer range 2 downto 0;

        TempReg : out std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        TempRegSel : out integer range 4 downto 0;

        SR      : out std_logic_vector(REG_SIZE - 1 downto 0);

        RegB : in std_logic_vector(REG_SIZE - 1 downto 0)
    );

end CU;

architecture behavioral of CU is

    constant Normal              : integer := 0;
    constant WaitForFetch        : integer := 1;
    constant BranchSlot          : integer := 2;
    constant BranchSlotRet       : integer := 3;
    constant BranchSlotDirect    : integer := 4;
    constant BootReadSP          : integer := 5;
    constant BootWaitForFetch    : integer := 6;
    constant WriteBack           : integer := 7;
    constant WaitForFetch_R_TRAPA: integer := 8;
    constant WaitForFetch2_W     : integer := 9;
    constant WaitForFetch3       : integer := 10;
    constant BranchSlotRTE       : integer := 11;
    constant WaitForFetch_R_RTE  : integer := 12;
    constant WaitForFetch2_R_RTE : integer := 13;
    constant Sleep               : integer := 14;
    constant STATE_CNT           : integer := 15;

    signal NextState : integer range STATE_CNT-1 downto 0;
    signal CurrentState : integer range STATE_CNT-1 downto 0;

    signal UpdateIR : std_logic;
    signal UpdateSR : std_logic;

    signal UpdateTempReg : std_logic;

    signal TempRegMuxOut : std_logic_vector(31 downto 0);

    signal UpdateTempReg2 : std_logic;

    signal TempReg2 : std_logic_vector(31 downto 0);

    signal RegInSelCmd : integer range REGARRAY_RegCnt-1 downto 0;
    signal RegASelCmd : integer range REGARRAY_RegCnt-1 downto 0;
    signal RegBSelCmd : integer range REGARRAY_RegCnt-1 downto 0;
    signal RegAxInSelCmd : integer range REGARRAY_RegCnt-1 downto 0;
    signal RegA1SelCmd : integer range REGARRAY_RegCnt-1 downto 0;
    
    signal SRSel : integer range SRSEL_CNT-1 downto 0;
    
begin

    --
    TempRegMuxOut <= (31 downto 9 => IR(7)) & IR(7 downto 0) & '0' when TempRegSel = TempRegSel_Offset8 else
                    (31 downto 13 => IR(11)) & IR(11 downto 0) & '0' when TempRegSel = TempRegSel_Offset12 else
                    RegB when TempRegSel = TempRegSel_RegB else
                    Result when TempRegSel = TempRegSel_Result else
                    DB when TempRegSel = TempRegSel_DataBus else
                    (others => 'X');

    RegInSel <= to_integer(unsigned(IR(11 downto 8)))   when RegInSelCmd = RegInSelCmd_Rn else
                R15                                     when RegInSelCmd = RegInSelCmd_R15 else
                R0                                      when RegInSelCmd = RegInSelCmd_R0;
    RegASel <= to_integer(unsigned(IR(11 downto 8))) when RegASelCmd = RegASelCmd_Rn else 0;
    RegBSel <= to_integer(unsigned(IR(7 downto 4))) when RegBSelCmd = RegBSelCmd_Rm else
               to_integer(unsigned(IR(11 downto 8))) when RegBSelCmd = RegBSelCmd_Rn else 0;

    RegA1Sel <= to_integer(unsigned(IR(11 downto 8))) when RegA1SelCmd = RegA1SelCmd_Rn else
                to_integer(unsigned(IR(7 downto 4))) when RegA1SelCmd = RegA1SelCmd_Rm else
                0;
    RegAxInSel <= to_integer(unsigned(IR(11 downto 8))) when RegAxInSelCmd = RegAxInSelCmd_Rn else
                  to_integer(unsigned(IR(7 downto 4))) when RegAxInSelCmd = RegAxInSelCmd_Rm else
                  0;

    -- Control Unit Registers
    process (CLK)
    begin

        if rising_edge(CLK) then
            if RST = '1' then
                -- Since databus is 32-bits, the IR is the high 16 bits when the
                -- program address when is at an address that is a multiple of 4.
                -- When it's not a multiple of 4 them the IR is the low 16 bits.
                IR <= DB(31 downto 16) when UpdateIR = '1' and AB(1 downto 0) = "00" else
                      DB(15 downto 0) when UpdateIR = '1' and AB(1 downto 0) = "10" else
                      IR;

                if UpdateSR = '1' then
                    SR <= (31 downto 1 => '0') & Tbit  when SRSel = SRSel_Tbit else
                          DB    when SRSel = SRSel_DB   else
                          RegB   when SRSel = SRSel_Reg  else
                          TempReg2 when SRSel = SRSel_Tmp2  else
                          (others => 'X');
                end if;

                --
                TempReg <= TempRegMuxOut when UpdateTempReg = '1' else TempReg;

                --
                TempReg2 <= DB when UpdateTempReg2 = '1' else TempReg2;

                -- Set state of FSM
                CurrentState <= NextState;
            else
                -- Reset to idle instruction (rising edge after reset)
                IR <= OpBoot;
                CurrentState <= Normal;
            end if;

        end if;
    end process;
    
    process (all)
    begin

    -- Instruction decoding (auto-generated)
    -- <AUTO-GEN PLACEHOLDER (do not remove or modify): Instruction decoding>

    -- end of auto-generated code (continue process)
        
    end process;


end behavioral;
