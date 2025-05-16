----------------------------------------------------------------------------
--
--  SH-2 Control Unit
--
--  This file contains the control unit (CU) implementation for a SH-2 processor.
--  It decodes instructions and generates control signals for the ALU, PAU, DAU,
--  RegArray, DTU, and top-level muxes. It also includes a FSM for instruction
--  sequencing and control
--
--  Packages included are:
--   CUConstants - constants for control signal values
--
--  Entities included are:
--   CU - control unit    
--
--  Revision History:
--     18 April 2025    Garrett Knuf    Initial revision.
--     20 April 2025    Garrett Knuf    Add autogen markers for instruction decoding.
--     24 April 2025    Garrett Knuf    Add FSM.
--     12 May 2025      Garrett Knuf    Fix bugs in decoding.
--     15 May 2025      Garrett Knuf    Optimize logic.
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
    constant RegA1SelCmd_Rn  : integer range RegA1SelCmd_CNT-1 downto 0 := 0;   -- generic register
    constant RegA1SelCmd_Rm  : integer range RegA1SelCmd_CNT-1 downto 0 := 1;   -- generic register
    constant RegA1SelCmd_R0  : integer range RegA1SelCmd_CNT-1 downto 0 := 2;   -- R0
    constant RegA1SelCmd_R15 : integer range RegA1SelCmd_CNT-1 downto 0 := 3;   -- R15

    -- RegAxInSelCmd - select what RegA1 outputs
    constant RegAxInSelCmd_CNT : integer := 4;
    constant RegAxInSelCmd_Rn  : integer range RegAxInSelCmd_CNT-1 downto 0 := 0;   -- generic register
    constant RegAxInSelCmd_Rm  : integer range RegAxInSelCmd_CNT-1 downto 0 := 1;   -- generic register
    constant RegAxInSelCmd_R0  : integer range RegAxInSelCmd_CNT-1 downto 0 := 2;   -- R0
    constant RegAxInSelCmd_R15 : integer range RegAxInSelCmd_CNT-1 downto 0 := 3;   -- R15

    -- DBOutSel - select output of databus
    constant DBOUTSEL_CNT    : integer := 6;
    constant DBOutSel_Result : integer range DBOUTSEL_CNT-1 downto 0 := 0;  -- ALU result
    constant DBOutSel_SR     : integer range DBOUTSEL_CNT-1 downto 0 := 1;  -- status reg
    constant DBOutSel_GBR    : integer range DBOUTSEL_CNT-1 downto 0 := 2;  -- GBR
    constant DBOutSel_VBR    : integer range DBOUTSEL_CNT-1 downto 0 := 3;  -- VBR
    constant DBOutSel_PR     : integer range DBOUTSEL_CNT-1 downto 0 := 4;  -- PR
    constant DBOutSel_PC     : integer range DBOUTSEL_CNT-1 downto 0 := 5;  -- PC

    -- ABSel - select output of address bus
    constant ABOutSel_Prog : integer range 1 downto 0 := 0; -- PAU address
    constant ABOutSel_Data : integer range 1 downto 0 := 1; -- DAU address

    -- TempRegSel - select value to put into temporary register
    constant TempRegSel_CNT      : integer := 5;
    constant TempRegSel_Offset8  : integer range TempRegSel_CNT-1 downto 0 := 0;
    constant TempRegSel_Offset12 : integer range TempRegSel_CNT-1 downto 0 := 1;
    constant TempRegSel_RegB     : integer range TempRegSel_CNT-1 downto 0 := 2;
    constant TempRegSel_Result   : integer range TempRegSel_CNT-1 downto 0 := 3;
    constant TempRegSel_DataBus  : integer range TempRegSel_CNT-1 downto 0 := 4;

    -- Bit indices of SR
    constant StatusReg_Tbit     : integer := 0; -- T bit
    constant StatusReg_Sbit     : integer := 1; -- S bit
    constant StatusReg_I0bit    : integer := 4; -- Interrupt mask I0
    constant StatusReg_I1bit    : integer := 5; -- Interrupt mask I1
    constant StatusReg_I2bit    : integer := 6; -- Interrupt mask I2
    constant StatusReg_I3bit    : integer := 7; -- Interrupt mask I3
    constant StatusReg_Qbit     : integer := 8; -- Q bit
    constant StatusReg_Mbit     : integer := 9; -- M bit

    -- SRSel - select value to load into SR
    constant SRSEL_CNT  : integer := 4;
    constant SRSel_Tbit : integer range SRSEL_CNT-1 downto 0 := 0;
    constant SRSel_DB   : integer range SRSEL_CNT-1 downto 0 := 1;
    constant SRSel_Reg  : integer range SRSEL_CNT-1 downto 0 := 2;
    constant SRSel_Tmp2 : integer range SRSEL_CNT-1 downto 0 := 3;

end package;


--
-- This architecture implements the finite state machine (FSM) and instruction
-- decoding logic for the SH-2 control unit. It generates approprate
-- control signals for:
--  ALU operation selection and operand routing
--  Program address updates via the PAU
--  Data addres updates via the DAU
--  Register access and storage
--  Memory and I/O control
--  Special handling for T-bit and SR register operations
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
        PAU_IncDecSel   : out   std_logic;                                  -- select inc/dec
        PAU_IncDecBit   : out   integer range 2 downto 0;                   -- select inc/dec bit
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


end CU;

architecture behavioral of CU is

    -- Finite-state machine (FSM) states
    constant Normal             : integer := 0; -- fetch next instruction while executing current
    constant WaitForFetch       : integer := 1; -- one clock wait to fetch next instruction
    constant BranchSlot         : integer := 2; -- branch slot to reg+offset
    constant BranchSlotRet      : integer := 3; -- branch slot when returning from function call
    constant BranchSlotDirect   : integer := 4; -- branch slot to offset
    constant BootReadSP         : integer := 5; -- read stack pointer from vec table on boot
    constant BootWaitForFetch   : integer := 6; -- fetch first instruction to run after boot sequence
    constant WriteBack          : integer := 7; -- write a value from temp reg back to memory
    constant WaitForFetch_R_TRAPA: integer := 8;
    constant WaitForFetch2_W     : integer := 9;
    constant WaitForFetch3       : integer := 10;
    constant BranchSlotRTE       : integer := 11;
    constant WaitForFetch_R_RTE  : integer := 12;
    constant WaitForFetch2_R_RTE : integer := 13;
    constant Sleep               : integer := 14;   -- idle (no code executing)
    constant STATE_CNT           : integer := 15;   -- total number of states

    signal NextState : integer range STATE_CNT-1 downto 0;      -- state to transition to on next clock
    signal CurrentState : integer range STATE_CNT-1 downto 0;   -- current state being executed

    -- CU internal control signals
    signal UpdateIR : std_logic;                                        -- control signal to update IR or not
    signal UpdateSR : std_logic;                                        -- control signal to update SR or not
    signal SRSel : integer range SRSEL_CNT-1 downto 0;                  -- select input to status register

    signal RegInSelCmd : integer range REGARRAY_RegCnt-1 downto 0;      -- select register for RegArray input
    signal RegASelCmd : integer range REGARRAY_RegCnt-1 downto 0;       -- select register for RegArray RegA
    signal RegBSelCmd : integer range REGARRAY_RegCnt-1 downto 0;       -- select register for RegArray RegB
    signal RegAxInSelCmd : integer range REGARRAY_RegCnt-1 downto 0;    -- select register for RegArray address input 
    signal RegA1SelCmd : integer range REGARRAY_RegCnt-1 downto 0;      -- select register for RegArray RegA1

    signal UpdateTempReg : std_logic;                                   -- control signal to update TempReg or not
    signal TempRegMuxOut : std_logic_vector(REG_SIZE-1 downto 0);       -- select input to TempReg
    signal UpdateTempReg2 : std_logic;                                  -- update secondary temporary register
    signal TempReg2     : std_logic_vector(REG_SIZE-1 downto 0);        -- secondary temporary register
    
begin

    -- Signal to set temporary register 1 to
    TempRegMuxOut <= (31 downto 9 => IR(7)) & IR(7 downto 0) & '0' when TempRegSel = TempRegSel_Offset8 else
                    (31 downto 13 => IR(11)) & IR(11 downto 0) & '0' when TempRegSel = TempRegSel_Offset12 else
                    RegB when TempRegSel = TempRegSel_RegB else
                    Result when TempRegSel = TempRegSel_Result else
                    DB when TempRegSel = TempRegSel_DataBus else
                    (others => 'X');

    -- Select registers to access in register array
    RegInSel <= to_integer(unsigned(IR(11 downto 8)))   when RegInSelCmd = RegInSelCmd_Rn else
                R15                                     when RegInSelCmd = RegInSelCmd_R15 else
                R0                                      when RegInSelCmd = RegInSelCmd_R0;

    RegASel <= to_integer(unsigned(IR(11 downto 8)))    when RegASelCmd = RegASelCmd_Rn else R0;

    RegBSel <= to_integer(unsigned(IR(7 downto 4)))     when RegBSelCmd = RegBSelCmd_Rm else
               to_integer(unsigned(IR(11 downto 8)))    when RegBSelCmd = RegBSelCmd_Rn else R0;

    RegA1Sel <= to_integer(unsigned(IR(11 downto 8)))   when RegA1SelCmd = RegA1SelCmd_Rn else
                to_integer(unsigned(IR(7 downto 4)))    when RegA1SelCmd = RegA1SelCmd_Rm else
                R15                                     when RegA1SelCmd = RegA1SelCmd_R15 else
                R0;

    RegAxInSel <= to_integer(unsigned(IR(11 downto 8))) when RegAxInSelCmd = RegAxInSelCmd_Rn else
                  to_integer(unsigned(IR(7 downto 4)))  when RegAxInSelCmd = RegAxInSelCmd_Rm else
                  R15                                   when RegA1SelCmd = RegA1SelCmd_R15 else
                  R0;

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

                -- Update status register accordingly
                if UpdateSR = '1' then
                    SR <= (31 downto 1 => '0') & Tbit  when SRSel = SRSel_Tbit else
                          DB    when SRSel = SRSel_DB   else
                          RegB   when SRSel = SRSel_Reg  else
                          TempReg2 when SRSel = SRSel_Tmp2  else
                          (others => 'X');
                end if;

                -- Update temporary register 1
                TempReg <= TempRegMuxOut when UpdateTempReg = '1' else TempReg;

                -- Update temporary register 2
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
