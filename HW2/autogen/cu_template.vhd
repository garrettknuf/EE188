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

    -- ALUOpASel - select input for ALUOpA
    constant ALUOpASel_RegA  : integer range 3 downto 0 := 0;   -- RegA of RegArray
    constant ALUOpASel_DB    : integer range 3 downto 0 := 1; 

    -- ALUOpBSel - select input for ALUOpB
    constant ALUOpBSel_RegB         : integer range 5 downto 0 := 0;    -- RegB of RegArray
    constant ALUOpBSel_Imm_Signed   : integer range 5 downto 0 := 1;    -- immediate signed
    constant ALUOpBSel_Imm_Unsigned : integer range 5 downto 0 := 2;    -- immediate unsigned
    constant ALUOpBSel_Offset8      : integer range 5 downto 0 := 3;    -- 8-bit signed offsetx2
    constant ALUOpBSel_Offset12     : integer range 5 downto 0 := 4;    -- 12-bit signed offsetx2

    -- RegInSel - select where to save input to RegIn
    constant RegInSelCmd_Rn : integer range 2 downto 0 := 0;    -- generic register
    constant RegInSelCmd_R0 : integer range 2 downto 0 := 1;    -- register R0
    constant RegInSelCmd_R15 : integer range 2 downto 0 := 2;    -- register R15

    -- RegASelCmd - select what RegA outputs
    constant RegASelCmd_Rn : integer range 2 downto 0 := 0;     -- generic register
    constant RegASelCmd_DB : integer range 2 downto 0 := 1;     -- databus
    constant RegASelCmd_R0 : integer range 2 downto 0 := 2;     -- register R0

    -- RegBSelCmd - select what RegB outputs
    constant RegBSelCmd_Rm : integer range 2 downto 0 := 0;     -- generic register
    constant RegBSelCmd_R0 : integer range 2 downto 0 := 1;     -- register R0
    constant RegBSelCmd_Rn : integer range 2 downto 0 := 2;     -- generic register
    
    -- RegA1SelCmd - select what RegA1 outputs
    constant RegA1SelCmd_Rn : integer range 2 downto 0 := 0;
    constant RegA1SelCmd_Rm : integer range 2 downto 0 := 1;
    constant RegA1SelCmd_R0 : integer range 2 downto 0 := 2;

    -- RegAxInSelCmd - select what RegA1 outputs
    constant RegAxInSelCmd_Rn : integer range 2 downto 0 := 0;
    constant RegAxInSelCmd_Rm : integer range 2 downto 0 := 1;
    constant RegAxInSelCmd_R0 : integer range 2 downto 0 := 2;

    -- DBOutSel - select output of databus
    constant DBOutSel_Result : integer range 5 downto 0 := 0;
    constant DBOutSel_SR     : integer range 5 downto 0 := 1;
    constant DBOutSel_GBR    : integer range 5 downto 0 := 2;
    constant DBOutSel_VBR    : integer range 5 downto 0 := 3;
    constant DBOutSel_PR     : integer range 5 downto 0 := 4;
    constant DBOutSel_PC     : integer range 5 downto 0 := 5;

    -- ABSel - select output of address bus
    constant ABOutSel_Prog : integer range 1 downto 0 := 0;
    constant ABOutSel_Data : integer range 1 downto 0 := 1;

    -- DataAccessMode - size of data access (read or write)
    constant DataAccessMode_BYTE : integer range 2 downto 0 := 0;
    constant DataAccessMode_WORD : integer range 2 downto 0 := 1;
    constant DataAccessMode_LONG : integer range 2 downto 0 := 2;

    constant DBInMode_Signed : integer range 1 downto 0 := 0;
    constant DBInMode_Unsigned : integer range 1 downto 0 := 1;

    constant TempRegSel_Offset8 : integer range 4 downto 0 := 0;
    constant TempRegSel_Offset12 : integer range 4 downto 0 := 1;
    constant TempRegSel_RegB : integer range 4 downto 0 := 2;

    constant REGAXDATAIN_CNT : integer := 6;
    constant RegAxDataIn_AddrIDOut  : integer range REGAXDATAIN_CNT-1 downto 0 := 0;
    constant RegAxDataIn_DataAddr   : integer range REGAXDATAIN_CNT-1 downto 0 := 1;
    constant RegAxDataIn_SR         : integer range REGAXDATAIN_CNT-1 downto 0 := 2;
    constant RegAxDataIn_GBR        : integer range REGAXDATAIN_CNT-1 downto 0 := 3;
    constant RegAxDataIn_VBR        : integer range REGAXDATAIN_CNT-1 downto 0 := 4;
    constant RegAxDataIn_PR         : integer range REGAXDATAIN_CNT-1 downto 0 := 5;

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
use work.CUConstants.all;
use work.ALUConstants.all;
use work.TbitConstants.all;
use work.MemUnitConstants.all;
use work.DAUConstants.all;
use work.PAUConstants.all;
use work.RegArrayConstants.all;
use work.StatusRegConstants.all;
use work.OpcodeConstants.all;

entity CU is

    port (
        -- CU Input Signals
        CLK     : in    std_logic;
        RST     : in    std_logic;
        DB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
        SR      : in    std_logic_vector(REG_SIZE - 1 downto 0);
        AB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);

        IR      : out   std_logic_vector(INST_SIZE - 1 downto 0) := x"DEAD";
        

        -- ALU Control Signals
        ALUOpASel   : out     integer range 2 downto 0 := 0;
        ALUOpBSel   : out     integer range 4 downto 0 := 0;
        FCmd        : out     std_logic_vector(3 downto 0);            
        CinCmd      : out     std_logic_vector(1 downto 0);            
        SCmd        : out     std_logic_vector(3 downto 0);            
        ALUCmd      : out     std_logic_vector(1 downto 0);
        TbitOp      : out     std_logic_vector(3 downto 0);

        -- StatusReg Control Signals
        UpdateSR    : out   std_logic;
        SRSel       : out   integer range SRSEL_CNT-1 downto 0;

        -- PAU Control Signals
        PAU_SrcSel      : out   integer range PAU_SRC_CNT - 1 downto 0;
        PAU_OffsetSel   : out   integer range PAU_OFFSET_CNT - 1 downto 0;
        PAU_UpdatePC    : out   std_logic;
        PAU_PRSel       : out   integer range PRSEL_CNT-1 downto 0;
        PAU_IncDecBit   : out   integer range 2 downto 0;
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
        RegInSelCmd     : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegStore        : out   std_logic;
        RegASelCmd      : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegBSelCmd      : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxInSelCmd   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxStore      : out   std_logic;
        RegA1SelCmd     : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegA2SelCmd     : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegOpSel        : out   integer  range REGOp_SrcCnt - 1 downto 0;
        RegAxDataInSel  : out   integer  range REGAXDATAIN_CNT-1 downto 0;
    
        -- IO Control signals
        DBOutSel : out integer range 5 downto 0;
        ABOutSel : out integer range 1 downto 0;
        DBInMode : out integer range 1 downto 0;
        RD     : out   std_logic;
        WR     : out   std_logic;
        DataAccessMode : out integer range 2 downto 0;

        TempReg : out std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        TempRegSel : out integer range 4 downto 0;

        RegB : in std_logic_vector(REG_SIZE - 1 downto 0)
    );

end CU;

architecture behavioral of CU is

    constant Normal             : integer := 0;
    constant WaitForFetch       : integer := 1;
    constant BranchSlot         : integer := 2;
    constant BranchSlotRet      : integer := 3;
    constant BranchSlotDirect   : integer := 4;
    constant BootReadSP         : integer := 5;
    constant BootWaitForFetch   : integer := 6;

    constant Sleep : integer := 7;
    constant STATE_CNT      : integer := 8;

    signal NextState : integer range STATE_CNT-1 downto 0;
    signal CurrentState : integer range STATE_CNT-1 downto 0;

    signal UpdateIR : std_logic;

    signal Tbit : std_logic;

    signal UpdateTempReg : std_logic;

    signal TempRegMuxOut : std_logic_vector(31 downto 0);

begin

    Tbit <= SR(0);

    --
    TempRegMuxOut <= (31 downto 9 => IR(7)) & IR(7 downto 0) & '0' when TempRegSel = TempRegSel_Offset8 else
                    (31 downto 13 => IR(11)) & IR(11 downto 0) & '0' when TempRegSel = TempRegSel_Offset12 else
                    RegB when TempRegSel = TempRegSel_RegB else
                    (others => 'X');

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


                --
                TempReg <= TempRegMuxOut when UpdateTempReg = '1' else TempReg;

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
