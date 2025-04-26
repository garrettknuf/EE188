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

package InstConstants is

    -- Data Transfer Instructions (Table 5.3)
    constant OpMOV_Imm_To_Rn          : std_logic_vector(INST_SIZE-1 downto 0) := "1110------------";
    constant OpMOVW_At_Disp_PC_To_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "1001------------";
    constant OpMOVL_At_Disp_PC_To_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "1101------------";
    constant OpMOV_Rm_To_Rn           : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0011";
    constant OpMOVB_Rm_To_At_Rn       : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------0000";
    constant OpMOVW_Rm_To_At_Rn       : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------0001";
    constant OpMOVL_Rm_To_At_Rn       : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------0010";
    constant OpMOVB_At_Rm_To_Rn       : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0000";
    constant OpMOVW_At_Rm_To_Rn       : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0001";
    constant OpMOVL_At_Rm_Rn          : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0010";
    constant OpMOVB_Rm_To_At_Dec_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------0000";
    constant OpMOVW_Rm_To_At_Dec_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------0001";
    constant OpMOVL_Rm_To_At_Dec_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------0010";
    constant OpMOVB_At_Rm_Inc_To_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0100";
    constant OpMOVW_At_Rm_Inc_To_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0101";
    constant OpMOVL_At_Rm_Inc_To_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0110";
    constant OpMOVB_R0_To_At_Disp_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "10000000--------";
    constant OpMOVW_R0_To_At_Disp_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "10000001--------";
    constant OpMOVL_R0_To_At_Disp_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "0001------------";
    constant OpMOVB_At_Disp_Rm_To_R0  : std_logic_vector(INST_SIZE-1 downto 0) := "10000100--------";
    constant OpMOVW_At_Disp_Rm_To_R0  : std_logic_vector(INST_SIZE-1 downto 0) := "10000101--------";
    constant OpMOVL_At_Disp_Rm_To_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "0101------------";
    constant OpMOVB_Rm_To_At_R0_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0000--------0100";
    constant OpMOVW_Rm_To_At_R0_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0000--------0101";
    constant OpMOVL_Rm_To_At_R0_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0000--------0100";
    constant OpMOVB_At_R0_Rm_To_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0000--------1100";
    constant OpMOVW_At_R0_Rm_To_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0000--------1101";
    constant OpMOVL_At_R0_Rm_To_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0000--------1110";
    constant OpMOVB_R0_To_At_Disp_GBR : std_logic_vector(INST_SIZE-1 downto 0) := "11000000--------";
    constant OpMOVW_R0_To_At_Disp_GBR : std_logic_vector(INST_SIZE-1 downto 0) := "11000001--------";
    constant OpMOVL_R0_To_At_Disp_GBR : std_logic_vector(INST_SIZE-1 downto 0) := "11000010--------";
    constant OpMOVB_At_Disp_GBR_To_R0 : std_logic_vector(INST_SIZE-1 downto 0) := "11000100--------";
    constant OpMOVW_At_Disp_GBR_To_R0 : std_logic_vector(INST_SIZE-1 downto 0) := "11000101--------";
    constant OpMOVL_At_Disp_GBR_To_R0 : std_logic_vector(INST_SIZE-1 downto 0) := "11000110--------";
    constant OpMOVA                   : std_logic_vector(INST_SIZE-1 downto 0) := "11000111--------";
    constant OpMOVT                   : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00101001";
    constant OpSwapB                  : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1000";
    constant OpSwapW                  : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1001";
    constant OpXTRCT                  : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------1101";

    -- Arithmetic Instructions (Table 5.4)
    constant OpADD_Rm_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------1100";
    constant OpADD_Imm_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "0111------------";
    constant OpADDC         : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------1110";
    constant OpADDV         : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------1111";
    constant OpCMP_EQ_Imm   : std_logic_vector(INST_SIZE-1 downto 0) := "10001000--------";
    constant OpCMP_EQ_RmRn  : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------0000";
    constant OpCMP_HS       : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------0010";
    constant OpCMP_GE       : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------0011";
    constant OpCMP_HI       : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------0110";
    constant OpCMP_GT       : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------0111";
    constant OpCMP_PL       : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00010101";
    constant OpCMP_PZ       : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00010001";
    constant OpCMP_STR      : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------1100";
    -- TODO: DIV1
    -- TODO: DIV0S
    -- TODO: DIV0U
    -- TODO: DMULS.L
    -- TODO: DMULU.L
    constant OpDT           : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00010000";
    constant OpEXTS_B       : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1110";
    constant OpEXTS_W       : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1111";
    constant OpEXTU_B       : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1100";
    constant OpEXTU_W       : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1101";
    -- TODO: MAC.L
    -- TODO: MAC.W
    -- TODO: MUL.L
    -- TODO: MULS.W
    -- TODO: MULU.W
    constant OpNEG          : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1011";
    constant OpNEGC         : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------1010";
    constant OpSUB          : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------1000";
    constant OpSUBC         : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------1010";
    constant OpSUBV         : std_logic_vector(INST_SIZE-1 downto 0) := "0011--------1011";

    -- Logic Operation Instructions (Table 5.5)
    constant OpAND_Rm_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------1001";
    constant OpAND_Imm_Rn   : std_logic_vector(INST_SIZE-1 downto 0) := "11001001--------";
    constant OpAND_Imm_B    : std_logic_vector(INST_SIZE-1 downto 0) := "11001101--------";
    constant OpNOT          : std_logic_vector(INST_SIZE-1 downto 0) := "0110--------0111";
    constant OpOR_Rm_Rn     : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------1011";
    constant OpOR_Imm       : std_logic_vector(INST_SIZE-1 downto 0) := "11001011--------";
    constant OpOR_Imm_B     : std_logic_vector(INST_SIZE-1 downto 0) := "11001011--------";
    constant OpTAS_B        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00011011";
    constant OpTST_Rm_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------1000";
    constant OpTST_Imm      : std_logic_vector(INST_SIZE-1 downto 0) := "11001000--------";
    constant OpTST_Imm_B    : std_logic_vector(INST_SIZE-1 downto 0) := "11001100--------";
    constant OpXOR_Rm_Rn    : std_logic_vector(INST_SIZE-1 downto 0) := "0010--------1010";
    constant OpXOR_Imm      : std_logic_vector(INST_SIZE-1 downto 0) := "11001010--------";
    constant OpXOR_Imm_B    : std_logic_vector(INST_SIZE-1 downto 0) := "11001110--------";

    -- Shift Instructions (Table 5.6)
    constant OpROTL         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00000100";
    constant OpROTR         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00000101";
    constant OpROTCL        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100100";
    constant OpROTCR        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100101";
    constant OpSHAL         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100000";
    constant OpSHAR         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100001";
    constant OpSHLL         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00000000";
    constant OpSHLR         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00000001";
    constant OpSHLL2        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00001000";
    constant OpSHLR2        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00001001";
    constant OpSHLL8        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00011000";
    constant OpSHLR8        : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00011001";
    constant OpSHLL16       : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00101000";
    constant OpSHLR16       : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00101001";

    -- Branch Instructions (Table 5.7)
    constant OpBF           : std_logic_vector(INST_SIZE-1 downto 0) := "10001011--------";
    constant OpBFS          : std_logic_vector(INST_SIZE-1 downto 0) := "10001111--------";
    constant OpBT           : std_logic_vector(INST_SIZE-1 downto 0) := "10001001--------";
    constant OpBTS          : std_logic_vector(INST_SIZE-1 downto 0) := "10001101--------";
    constant OpBRA          : std_logic_vector(INST_SIZE-1 downto 0) := "1010------------";
    constant OpBRAF         : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00100011";
    constant OpBSR          : std_logic_vector(INST_SIZE-1 downto 0) := "1011------------";
    constant OpBSRF         : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00000011";
    constant OpJMP          : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00101011";
    constant OpJSR          : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00001011";
    constant OpRTS          : std_logic_vector(INST_SIZE-1 downto 0) := "0000000000001011";

    -- System Control Instructions (Table 5.8)
    constant OpCLRT                  : std_logic_vector(INST_SIZE-1 downto 0) := "0000000000001000";
    -- TODO: CLRMAC
    constant OpLDC_Rm_To_SR          : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00001110";
    constant OpLDC_Rm_To_GBR         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00011110";
    constant OpLDC_Rm_To_VBR         : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00101110";
    constant OpLDCL_At_Rm_Inc_To_SR  : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00000111";
    constant OpLDCL_At_Rm_Inc_To_GBR : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00010111";
    constant OpLDCL_At_Rm_Inc_To_VBR : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100111";
    -- TODO: LDS Rm, MACH
    -- TODO: LDS Rm, MACL
    constant OpLDS_Rm_To_PR          : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00101010";
    -- TODO: LDS.L @Rm+, MACH
    -- TODO: LDS.L @Rm+, MACL
    constant OpLDSL_At_Rm_Inc_To_PR  : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00101010";
    constant OpNOP                   : std_logic_vector(INST_SIZE-1 downto 0) := "0000000000001001";
    constant OpRTE                   : std_logic_vector(INST_SIZE-1 downto 0) := "0000000000101011";
    constant OpSETT                  : std_logic_vector(INST_SIZE-1 downto 0) := "0000000000011000";
    -- TODO: Sleep
    constant OpSTC_SR_To_Rn          : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00000010";
    constant OpSTC_GBR_To_Rn         : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00010010";
    constant OpSTC_VBR_To_Rn         : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00100010";
    constant OpSTCL_SR_To_At_Dec_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00000011";
    constant OpSTCL_GBR_To_At_Dec_Rn : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00010011";
    constant OpSTCL_VBR_To_At_Dec_Rn : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100011";
    -- TODO: STS MACH, Rn
    -- TODO: STS MACL, Rn
    -- TODO: STS MACH, Rn
    constant OpSTS_PR_To_Rn          : std_logic_vector(INST_SIZE-1 downto 0) := "0000----00101010";
    -- TODO: STSL MACH, @-Rn
    -- TODO: STSL MACL, @-Rn
    constant OpSTSL_PR_To_At_Dec_Rn  : std_logic_vector(INST_SIZE-1 downto 0) := "0100----00100010";
    constant OpTRAPA                 : std_logic_vector(INST_SIZE-1 downto 0) := "11000011--------";
    
    constant OpIdle                  : std_logic_vector(INST_SIZE-1 downto 0) := "0000000000000000";

end package;

--
-- Package containing constants for the control unit.
--

library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;
use work.RegArrayConstants.all;

package CUConstants is

    -- ALUOpASel - select input for ALUOpA
    constant ALUOpASel_RegA  : integer range 1 downto 0 := 0;
    constant ALUOpASel_DB    : integer range 1 downto 0 := 1;


    -- ALUOpBSel - select input for ALUOpB
    constant ALUOpBSel_RegB         : integer range 2 downto 0 := 0;
    constant ALUOpBSel_Imm_Signed   : integer range 2 downto 0 := 1;
    constant ALUOpBSel_Imm_Unsigned : integer range 2 downto 0 := 2;

    -- RegInSrcSel - select inputs to RegIn
    -- constant RegInSrcSel_Result : integer

    -- RegInSel - select where to save input to RegIn
    constant RegInSelCmd_Rn : integer range 1 downto 0 := 0;
    constant RegInSelCmd_R0 : integer range 1 downto 0 := 1;

    -- RegASelCmd - select what RegA outputs
    constant RegASelCmd_Rn : integer range 1 downto 0 := 0;
    constant RegASelCmd_DB : integer range 1 downto 0 := 1;

    -- RegBSelCmd - select what RegB outputs
    constant RegBSelCmd_Rm : integer range 1 downto 0 := 0;
    constant RegBSelCmd_R0 : integer range 1 downto 0 := 1;
    
    -- RegA1SelCmd - select what RegA1 outputs
    constant RegA1SelCmd_Rn : integer range 2 downto 0 := 0;
    constant RegA1SelCmd_Rm : integer range 2 downto 0 := 1;
    constant RegA1SelCmd_R0 : integer range 2 downto 0 := 2;

    -- DBOutSel - select output of databus
    constant DBOutSel_Result : integer range 5 downto 0 := 0;
    constant DBOutSel_SR     : integer range 5 downto 0 := 1;
    constant DBOutSel_GBR    : integer range 5 downto 0 := 2;
    constant DBOutSel_VBR    : integer range 5 downto 0 := 3;
    constant DBOutSel_PR     : integer range 5 downto 0 := 4;
    constant DBOutSel_PC     : integer range 5 downto 0 := 5;

    -- ABSel - select output of address bus
    constant ABSel_Prog : integer range 1 downto 0 := 0;
    constant ABSel_Data : integer range 1 downto 0 := 1;

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
use work.InstConstants.all;

entity CU is

    port (
        -- CU Input Signals
        CLK     : in    std_logic;
        RST     : in    std_logic;
        DB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
        SR      : in    std_logic_vector(REG_SIZE - 1 downto 0);
        IR      : out   std_logic_vector(INST_SIZE - 1 downto 0) := OpIdle;

        DBOutSel : out integer range 5 downto 0;

        -- ALU Control Signals
        ALUOpASel   : out     integer range 1 downto 0 := 0;
        ALUOpBSel   : out     integer range 2 downto 0 := 0;
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
        RegASelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegBSelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxInSelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxStore : out   std_logic;
        RegA1SelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegA2SelCmd : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegOpSel : out   integer  range REGOp_SrcCnt - 1 downto 0;
    
        -- IO Control signals
        RD      : out   std_logic;
        WR      : out   std_logic

    );

end CU;

architecture behavioral of CU is

    constant Idle           : integer := 0;
    constant Fetch          : integer := 1;
    constant WaitForRead    : integer := 2;
    constant BranchSlot     : integer := 3;
    constant WaitForReadPostInc : integer := 4;
    constant RTE_Init : integer := 5;
    constant TRAPA_Init : integer := 6;
    constant STATE_CNT      : integer := 7;

    signal NextState : integer range STATE_CNT-1 downto 0;

    signal UpdateIR : std_logic;

    signal Tbit : std_logic;

begin

    Tbit <= SR(0);

    -- Control Unit FSM
    process (CLK)
    begin

        if rising_edge(CLK) then
            if RST = '1' then
                IR <= DB(31 downto 16) when UpdateIR = '1' else IR;
            else
                IR <= OpIdle;
            end if;
        end if;

    end process;

    -- Instruction decoding (auto-generated)
    -- <AUTO-GEN PLACEHOLDER (do not remove or modify): Instruction decoding>

end behavioral;
