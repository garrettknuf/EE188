----------------------------------------------------------------------------
--
--  Hitachi SH-2 RISC Processor
--
--  This is an implementation of 
--
--  Entities included are:
--    
--
--  Revision History:
--     16 April 2025    Garrett Knuf    Initial revision.
--
----------------------------------------------------------------------------

--
--
--
--
library ieee;


entity SH2 is

    port (
        DataBus     : in    std_logic_vector(15 downto 0);
        CLK         : in    std_logic;
        AddrBus     : out   std_logic_vector(31 downto 0)
    );

end SH2;

architecture structural of SH2 is

    component ALU is
        port (
            ALUOpA   : in      std_logic_vector(LONG_SIZE - 1 downto 0);
            ALUOpB   : in      std_logic_vector(LONG_SIZE - 1 downto 0);
            Cin      : in      std_logic;                               
            FCmd     : in      std_logic_vector(3 downto 0);            
            CinCmd   : in      std_logic_vector(1 downto 0);            
            SCmd     : in      std_logic_vector(2 downto 0);            
            ALUCmd   : in      std_logic_vector(1 downto 0);            
            TbitOp   : in      integer range Tbit_Src_Cnt - 1 downto 0; 
            Result   : buffer  std_logic_vector(LONG_SIZE - 1 downto 0);
            Tbit     : out     std_logic                                
        );
    end component;

    component RegArray is
        generic (
            regcnt   : integer;
            wordsize : integer
        );
        port(
            RegIn      : in   std_logic_vector(wordsize - 1 downto 0);
            RegInSel   : in   integer  range regcnt - 1 downto 0;
            RegStore   : in   std_logic;
            RegASel    : in   integer  range regcnt - 1 downto 0;
            RegBSel    : in   integer  range regcnt - 1 downto 0;
            RegAxIn    : in   std_logic_vector(wordsize - 1 downto 0);
            RegAxInSel : in   integer  range regcnt - 1 downto 0;
            RegAxStore : in   std_logic;
            RegA1Sel   : in   integer  range regcnt - 1 downto 0;
            RegA2Sel   : in   integer  range regcnt - 1 downto 0;
            RegDIn     : in   std_logic_vector(2 * wordsize - 1 downto 0);
            RegDInSel  : in   integer  range regcnt/2 - 1 downto 0;
            RegDStore  : in   std_logic;
            RegDSel    : in   integer  range regcnt/2 - 1 downto 0;
            clock      : in   std_logic;
            RegA       : out  std_logic_vector(wordsize - 1 downto 0);
            RegB       : out  std_logic_vector(wordsize - 1 downto 0);
            RegA1      : out  std_logic_vector(wordsize - 1 downto 0);
            RegA2      : out  std_logic_vector(wordsize - 1 downto 0);
            RegD       : out  std_logic_vector(2 * wordsize - 1 downto 0)
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

begin

    -- Create 32-bit ALU for standard logic and arithmetic operations
    SH2_ALU : ALU
        generic map(
            wordsize => 32
        )
        port map (
            ALUOpA  => ALUOpA,
            ALUOpB  => ALUOpB,
            Cin     => Cin,
            FCmd    => FCmd,
            CinCmd  => CinCmd,
            SCmd    => SCmd,
            ALUCmd  => ALUCmd,
            TbitOp  => TbitOp,
            Result  => Result,
            Tbit    => Tbit
        );

    -- Create 32-bit register array with general purpose registers R0-R15
    SH2_RegArray : RegArray
        generic map(
            regcnt => REG_CNT
            wordsize => 32
        )
        port(
            RegInRegIn  => RegInRegIn,
            RegInSel    => RegInSel,
            RegStore    => RegStore,
            RegASel     => RegASel,
            RegBSel     => RegBSel,
            RegAxIn     => RegAxIn,
            RegAxInSel  => RegAxInSel,
            RegAxStore  => RegAxStore,
            RegA1Sel    => RegA1Sel,
            RegA2Sel    => RegA2Sel,
            RegDIn      => RegDIn,
            RegDInSel   => RegDInSel,
            RegDStore   => RegDStore,
            RegDSel     => RegDSel,
            clock       => clock,
            RegA        => RegA,
            RegB        => RegB,
            RegA1       => RegA1,
            RegA2       => RegA2,
            RegD        => RegD
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
            CLK        => CLK,
            ProgAddr   => ProgAddr,
            PC         => PC,
            PR         => PR
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
            PC         => PC,
            IncDecSel  => DAU_IncDecSel,
            IncDecBit  => DAU_IncDecBit,
            PrePostSel => DAU_PrePostSel,
            LoadGBR    => DAU_LoadGBR,
            CLK        => CLK,
            AddrIDOut  => AddrIDOut,
            DataAddr   => DataAddr,
            GBR        => GBR
        );

end structural;
