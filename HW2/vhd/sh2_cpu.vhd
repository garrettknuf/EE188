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
use work.StatusRegConstants.all;
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
            TempReg     : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            UpdatePC    : in    std_logic;
            PRSel       : in    integer range PRSEL_CNT-1 downto 0;
            IncDecBit   : in    integer range 2 downto 0;
            PrePostSel  : in    std_logic;
            DB          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
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
            DB          : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
            IncDecSel   : in    std_logic;
            IncDecBit   : in    integer range 2 downto 0;
            PrePostSel  : in    std_logic;
            GBRSel      : in    integer range GBRSEL_CNT-1 downto 0;
            VBRSel      : in    integer range GBRSEL_CNT-1 downto 0;
            CLK         : in    std_logic;
            RST         : in    std_logic;
            AddrIDOut   : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            DataAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   
            GBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
            VBR         : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)
        );
    end component;

    component StatusReg is
        port (
            Tbit        : in    std_logic;
            UpdateSR    : in    std_logic;
            DB          : in    std_logic_vector(31 downto 0);
            Reg         : in    std_logic_vector(31 downto 0);
            SRSel       : in    integer range 2 downto 0;
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

            -- CU Registers
            IR      : out    std_logic_vector(INST_SIZE - 1 downto 0);

            -- ALU Control Signals
            ALUOpASel   : out     integer range 2 downto 0;
            ALUOpBSel   : out     integer range 5 downto 0;
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
            PAU_IncDecBit   : out    integer range 2 downto 0;
            PAU_PrePostSel  : out    std_logic;

            -- DAU Control Signals
            DAU_SrcSel      : out   integer range DAU_SRC_CNT - 1 downto 0;
            DAU_OffsetSel   : out   integer range DAU_OFFSET_CNT - 1 downto 0;
            DAU_IncDecSel   : out   std_logic;
            DAU_IncDecBit   : out   integer range 2 downto 0;
            DAU_PrePostSel  : out   std_logic;
            DAU_GBRSel      : out   integer range GBRSEL_CNT-1 downto 0;
            DAU_VBRSel      : out   integer range VBRSEL_CNT-1 downto 0;

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
    end component;

    -- ALU Signals
    signal ALUOpASel : integer range 2 downto 0;
    signal ALUOpBSel : integer range 5 downto 0;
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
    signal PAU_PRSel       : integer range PRSEL_CNT-1 downto 0;
    signal PAU_IncDecBit   : integer range 2 downto 0;
    signal PAU_PrePostSel  : std_logic;
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
    signal DAU_GBRSel        : integer range GBRSEL_CNT-1 downto 0;
    signal DAU_VBRSel        : integer range VBRSEL_CNT-1 downto 0;
    signal DAU_AddrIDOut      : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_DataAddr       : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_GBR            : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DAU_VBR            : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- StatusReg Signals
    signal SR_UpdateSR     : std_logic;
    signal SR             : std_logic_vector(REG_SIZE - 1 downto 0);

    signal ALUOpA : std_logic_vector(LONG_SIZE-1 downto 0);
    signal ALUOpB : std_logic_vector(LONG_SIZE-1 downto 0);

    signal DBOutSel : integer range 5 downto 0;
    signal DBOut : std_logic_vector(DATA_BUS_SIZE-1 downto 0);

    signal ABOutSel : integer range 1 downto 0;

    signal IR : std_logic_vector(INST_SIZE-1 downto 0);

    signal DataAccessMode : integer range 2 downto 0;

    signal RegInSelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegASelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxInSelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegA1SelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegA2SelCmd : integer  range REGARRAY_RegCnt - 1 downto 0;

    signal RegAxDataInSel  : integer  range REGAXDATAIN_CNT-1 downto 0;


    signal SRSel : integer range SRSEL_CNT-1 downto 0;

    signal WE : std_logic_vector(3 downto 0);
    signal RE : std_logic_vector(3 downto 0);

    signal WR : std_logic;
    signal RD : std_logic;

    signal MemAccessBits : std_logic_vector(3 downto 0);

    signal DBInMode : integer range 1 downto 0;

    signal DBIn : std_logic_vector(31 downto 0);

    signal DBSignExtBit : std_logic;

    signal TempReg : std_logic_vector(31 downto 0);
    signal TempRegSel : integer range 4 downto 0;

begin

    process (clock)
    begin
        if falling_edge(clock) then
            WE3 <= WE(3);
            WE2 <= WE(2);
            WE1 <= WE(1);
            WE0 <= WE(0);

            RE3 <= RD;
            RE2 <= RD;
            RE1 <= RD;
            RE0 <= RD;
        else
            WE3 <= '1';
            WE2 <= '1';
            WE1 <= '1';
            WE0 <= '1';
            RE3 <= '1';
            RE2 <= '1';
            RE1 <= '1';
            RE0 <= '1';
        end if;
    end process;

    -- DAU inputs (non-control signals)
    DAU_Offset4 <= IR(3 downto 0);
    DAU_Offset8 <= IR(7 downto 0);
    DAU_Rn <= RegA1;
    DAU_R0 <= RegA;
    DAU_PC <= PAU_PC;

    -- ALU inputs (non-control signals)
    ALUOpA <= RegA    when ALUOpASel = ALUOpASel_RegA else
              DBIn    when ALUOpASel = ALUOpASel_DB else
              (others => '0') when ALUOpASel = ALUOpASel_Zero else
              (others => 'X');
    ALUOpB <= RegB  when ALUOpBSel = ALUOpBSel_RegB else
              (31 downto 8 => '0') & IR(7 downto 0) when ALUOpBSel = ALUOpBSel_Imm_Unsigned else
              (31 downto 8 => IR(7)) & IR(7 downto 0) when ALUOpBSel = ALUOpBSel_Imm_Signed else
              (31 downto 1 => '0') & SR(0) when ALUOpBSel = ALUOpBSel_Tbit else
              (others => 'X');
    ALU_Cin <= SR(0);

    -- PAU inputs (non-control signals)
    PAU_Offset8 <= IR(7 downto 0);
    PAU_Offset12 <= IR(11 downto 0);
    PAU_OffsetReg <= RegA1;

    -- RegArray inputs (non-control signals)
    RegIn <= ALU_Result;
    RegAxIn <= DAU_AddrIDOut when RegAxDataInSel = RegAxDataIn_AddrIDOut else 
               DAU_DataAddr when RegAxDataInSel = RegAxDataIn_DataAddr else
               SR when RegAxDataInSel = RegAxDataIn_SR else
               DAU_GBR when RegAxDataInSel = RegAxDataIn_GBR else
               DAU_VBR when RegAxDataInSel = RegAxDataIn_VBR else
               PAU_PR  when RegAxDataInSel = RegAxDataIn_PR else
               (others => 'X');

    RegInSel <= to_integer(unsigned(IR(11 downto 8))) when RegInSelCmd = RegInSelCmd_Rn else
                15 when RegInSelCmd = RegInSelCmd_R15 else 0;
    RegASel <= to_integer(unsigned(IR(11 downto 8))) when RegASelCmd = RegASelCmd_Rn else 0;
    RegBSel <= to_integer(unsigned(IR(7 downto 4))) when RegBSelCmd = RegBSelCmd_Rm else
               to_integer(unsigned(IR(11 downto 8))) when RegBSelCmd = RegBSelCmd_Rn else 0;

    RegA1Sel <= to_integer(unsigned(IR(11 downto 8))) when RegA1SelCmd = RegA1SelCmd_Rn else
                to_integer(unsigned(IR(7 downto 4))) when RegA1SelCmd = RegA1SelCmd_Rm else
                0;
    RegAxInSel <= to_integer(unsigned(IR(11 downto 8))) when RegAxInSelCmd = RegAxInSelCmd_Rn else
                  to_integer(unsigned(IR(7 downto 4))) when RegAxInSelCmd = RegAxInSelCmd_Rm else
                  0;

    AB <= PAU_ProgAddr when ABOutSel = ABOutSel_Prog else
        DAU_DataAddr when ABOutSel = ABOutSel_Data else
        (others => 'X');

    PAU_Offset8 <= IR(7 downto 0);
    PAU_Offset12 <= IR(11 downto 0);

    DB <= DBOut when WR = '0' else (others => 'Z');

    process(all)
    begin
        if WR = '0' then
            WE <= MemAccessBits;
            RE <= "1111";
        elsif RD = '0' then
            RE <= MemAccessBits;
            WE <= "1111";
        end if;
    end process;

    process(all)
    begin
        if (DBOutSel = DBOutSel_Result) then
            case DataAccessMode is
                when DataAccessMode_Byte =>

                    -- Select position of byte to output on data bus
                    if (AB(1 downto 0) = "11") then
                        DBOut(7 downto 0) <= ALU_Result(7 downto 0);    -- byte 3
                        DBIn(7 downto 0) <= DB(7 downto 0);
                        DBSignExtBit <= DB(7);
                        MemAccessBits <= "1110";
                    elsif (AB(1 downto 0) = "10") then 
                        DBOut(15 downto 8) <= ALU_Result(7 downto 0);   -- byte 2
                        DBIn(7 downto 0) <= DB(15 downto 8);
                        DBSignExtBit <= DB(15);
                        MemAccessBits <= "1101";
                    elsif (AB(1 downto 0) = "01") then
                        DBOut(23 downto 16) <= ALU_Result(7 downto 0);  -- byte 1
                        DBIn(7 downto 0) <= DB(23 downto 16);
                        DBSignExtBit <= DB(23);
                        MemAccessBits <= "1011";
                    elsif (AB(1 downto 0) = "00") then 
                        DBOut(31 downto 24) <= ALU_Result(7 downto 0);  -- byte 0
                        DBIn(7 downto 0) <= DB(31 downto 24);
                        DBSignExtBit <= DB(31);
                        MemAccessBits <= "0111";
                    else
                        DBOut(7 downto 0) <= (others => 'X');   -- invalid addr
                        DBIn(7 downto 0) <= (others => 'X');
                        MemAccessBits <= "1111";
                    end if;

                    DBIn(31 downto 8) <= (31 downto 8 => '0') when DBInMode = DBInMode_Unsigned else
                                        (31 downto 8 => DBSignExtBit) when DBInMode = DBInMode_Signed else
                                        (31 downto 8 => 'X');

                when DataAccessMode_Word =>

                    -- Select position of word output on data bus
                    if AB(1 downto 0) = "10" then
                        -- Address on low word (higher address)
                        DBOut(15 downto 0) <= ALU_Result(15 downto 0);
                        DBIn(15 downto 0) <= DB(15 downto 0);
                        DBSignExtBit <= DB(15);
                        MemAccessBits <= "1100";
                    elsif AB(1 downto 0) = "00" then
                        -- Address on high word (lower address)
                        DBOut(31 downto 16) <= ALU_Result(15 downto 0);
                        DBIn(15 downto 0) <= DB(31 downto 16);
                        DBSignExtBit <= DB(31);
                        MemAccessBits <= "0011";
                    else
                        -- Invalid address access for long
                        DBOut <= (others => 'X');
                        MemAccessBits <= "1111";
                    end if;

                    DBIn(31 downto 16) <= (31 downto 16 => '0') when DBInMode = DBInMode_Unsigned else
                                        (31 downto 16 => DBSignExtBit) when DBInMode = DBInMode_Signed else
                                        (31 downto 16 => 'X');

                when DataAccessMode_Long =>
                    -- Check that address accessed is a valid multiple of 4
                    if (AB(1 downto 0) = "00") then
                        DBOut <= ALU_Result;
                        DBIn <= DB(31 downto 0);
                        MemAccessBits <= "0000";
                    else
                        DBOut <= (others => 'X');
                        MemAccessBits <= "1111";
                    end if;
                when others =>
                    DBOut <= (others => 'X');
            end case;
        elsif (DBOutSel = DBOutSel_GBR) then
            DBOut <= DAU_GBR;
            MemAccessBits <= "0000";
        elsif (DBOutSel = DBOutSel_VBR) then
            DBOut <= DAU_VBR;
            MemAccessBits <= "0000";
        elsif (DBOutSel = DBOutSel_SR) then
            DBOut <= SR;
            MemAccessBits <= "0000";
        elsif (DBOutSel = DBOutSel_PR) then
            DBOut <= PAU_PR;
            MemAccessBits <= "0000";
        else
            DBOut <= (others => 'Z');
        end if;

    end process;

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
            TempReg    => TempReg,
            IncDecBit  => PAU_IncDecBit,
            PrePostSel => PAU_PrePostSel,
            DB         => DB,
            UpdatePC   => PAU_UpdatePC,
            PRSel      => PAU_PRSel,
            CLK        => clock,
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
            GBR        => DAU_GBR,
            VBR        => DAU_VBR
        );

    -- Status Register (SR)
    SH2_SR : StatusReg
        port map (
            Tbit        => ALU_Tbit,
            UpdateSR  => SR_UpdateSR,
            DB          => DB,
            Reg         => RegA,
            SRSel       => SRSel,
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
            UpdateSR    => SR_UpdateSR,
            SRSel       => SRSel,

            -- PAU Control Signals
            PAU_SrcSel      => PAU_SrcSel,
            PAU_OffsetSel   => PAU_OffsetSel,
            PAU_UpdatePC    => PAU_UpdatePC,
            PAU_PRSel       => PAU_PRSel,
            PAU_IncDecBit   => PAU_IncDecBit,
            PAU_PrePostSel  => PAU_PrePostSel,

            -- DAU Control Signals
            DAU_SrcSel      => DAU_SrcSel,
            DAU_OffsetSel   => DAU_OffsetSel,
            DAU_IncDecSel   => DAU_IncDecSel,
            DAU_IncDecBit   => DAU_IncDecBit,
            DAU_PrePostSel  => DAU_PrePostSel,
            DAU_GBRSel      => DAU_GBRSel,
            DAU_VBRSel      => DAU_VBRSel,

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
            RegAxDataInSel => RegAxDataInSel,

            -- IO Control signals
            RD => RD,
            WR => WR,
            DataAccessMode => DataAccessMode,
            DBInMode => DBInMode,

            TempReg => TempReg,
            TempRegSel => TempRegSel,
            RegB => RegB
        );

end structural;
