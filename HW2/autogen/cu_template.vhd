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
    constant RegASelCmd_Rn : integer range 2 downto 0 := 0;
    constant RegASelCmd_DB : integer range 2 downto 0 := 1;
    constant RegASelCmd_R0 : integer range 2 downto 0 := 2;

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
    constant ABOutSel_Prog : integer range 1 downto 0 := 0;
    constant ABOutSel_Data : integer range 1 downto 0 := 1;

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

        IR      : out   std_logic_vector(INST_SIZE - 1 downto 0) := OpIdle;

        DBOutSel : out integer range 5 downto 0;

        ABOutSel : out integer range 1 downto 0;

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
        RegInSelCmd     : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegStore        : out   std_logic;
        RegASelCmd      : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegBSelCmd      : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxInSelCmd   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxStore      : out   std_logic;
        RegA1SelCmd     : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegA2SelCmd     : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegOpSel        : out   integer  range REGOp_SrcCnt - 1 downto 0;
    
        -- IO Control signals
        RE0     : out   std_logic;
        RE1     : out   std_logic;
        RE2     : out   std_logic;
        RE3     : out   std_logic;
        WE0     : out   std_logic;
        WE1     : out   std_logic;
        WE2     : out   std_logic;
        WE3     : out   std_logic;

        DB_WR   : out   std_logic

    );

end CU;

architecture behavioral of CU is

    constant Normal         : integer := 0;
    constant WaitForFetch   : integer := 1;
    constant WriteByte_Mask : integer := 2;
    constant WriteWord_Mask     : integer := 3;
    constant WaitForReadPostInc : integer := 4;
    constant RTE_Init : integer := 5;
    constant TRAPA_Init : integer := 6;
    constant STATE_CNT      : integer := 7;

    signal NextState : integer range STATE_CNT-1 downto 0;
    signal CurrentState : integer range STATE_CNT-1 downto 0;

    signal UpdateIR : std_logic;

    signal Tbit : std_logic;

    signal MemRE0 : std_logic;
    signal MemRE1 : std_logic;
    signal MemRE2 : std_logic;
    signal MemRE3 : std_logic;
    signal MemWE0 : std_logic;
    signal MemWE1 : std_logic;
    signal MemWE2 : std_logic;
    signal MemWE3 : std_logic;


begin

    Tbit <= SR(0);

    DB_WR <= MemWE0 and MemWE1 and MemWE2 and MemWE3;

    -- Control Unit Registers
    process (CLK)
    begin

        if rising_edge(CLK) then
            if RST = '1' then
                IR <= DB(31 downto 16) when UpdateIR = '1' and AB(1 downto 0) = "00" else
                      DB(15 downto 0) when UpdateIR = '1' and AB(1 downto 0) = "10" else
                      IR;
                CurrentState <= NextState;
            else
                IR <= OpIdle;
                CurrentState <= Normal;
            end if;

            -- Memory access avoided since address bus changing
            RE0 <= '1';
            RE1 <= '1';
            RE2 <= '1';
            RE3 <= '1';
            WE0 <= '1';
            WE1 <= '1';
            WE2 <= '1';
            WE3 <= '1';

        end if;
        
        if falling_edge(CLK) then
            RE0 <= MemRE0;
            RE1 <= MemRE1;
            RE2 <= MemRE2;
            RE3 <= MemRE3;
            WE0 <= MemWE0;
            WE1 <= MemWE1;
            WE2 <= MemWE2;
            WE3 <= MemWE3;
        end if;
    end process;
    
    process (all)
    begin

    -- Instruction decoding (auto-generated)
    -- <AUTO-GEN PLACEHOLDER (do not remove or modify): Instruction decoding>

    -- end of auto-generated code (continue process)

    -- Finite State Machine (FSM)
    -- These commands override the above instruction decoding when the control
    -- unit is in the non-default state.

        if CurrentState = WaitForFetch then
            ALUOpASel <= ALUOpASel_RegA;
            ALUOpBSel <= ALUOpBSel_RegB;
            FCmd <= (others => '-');
            CinCmd <= (others => '-');
            SCmd <= (others => '-');
            ALUCmd <= (others => '-');
            TbitOp <= (others => '-');
            UpdateTbit <= '0';
            PAU_SrcSel <= PAU_AddrPC;
            PAU_OffsetSel <= PAU_OffsetWord;
            PAU_UpdatePC <= '1';
            PAU_UpdatePR <= '0';
            DAU_SrcSel <= unused;
            DAU_OffsetSel <= unused;
            DAU_IncDecSel <= '-';
            DAU_IncDecBit <= unused;
            DAU_PrePostSel <= '-';
            DAU_LoadGBR <= '0';
            RegInSelCmd <= unused;
            RegStore <= '0';
            RegASelCmd <= unused;
            RegBSelCmd <= unused;
            RegAxInSelCmd <= unused;
            RegAxStore <= '0';
            RegA1SelCmd <= unused;
            RegA2SelCmd <= unused;
            RegOpSel <= RegOp_None;
            MemRE0 <= '0';
            MemRE1 <= '0';
            MemRE2 <= '0';
            MemRE3 <= '0';
            MemWE0 <= '1';
            MemWE1 <= '1';
            MemWE2 <= '1';
            MemWE3 <= '1';
            ABOutSel <= ABOutSel_Prog;
            DBOutSel <= unused;
            NextState <= Normal;
            UpdateIR <= '1';
        end if;
        
    end process;


end behavioral;
