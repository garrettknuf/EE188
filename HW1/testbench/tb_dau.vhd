------------------------------------------------------------------------------
--
--  Test Bench for SH-2 Data Memory Access Unit (DAU).
--
--  Tests:
--   Setting GBR
--   Addressing @(disp,PC) for byte, word, and longword
--   Addressing @(disp,Rn) for byte, word, and longword
--   Addressing @(R0, Rn)
--   Addressing @(disp,GBR) for byte, word, and longword
--   Addressing @(R0,GBR)
--   Address @Rn with pre/post increment/decrement for byte, word, and longword
--
--  Revision History:
--     17 April 2025    Garrett Knuf    Initial revision.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.MemUnitConstants.all;
use work.DAUConstants.all;

library osvvm;
use osvvm.AlertLogPkg.all;

entity tb_dau is
end tb_dau;

architecture TB_ARCHITECTURE of tb_dau is

    -- Component declaration of the tested unit
    component DAU
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

    -- Stimulus signals
    signal SrcSel       : integer range DAU_SRC_CNT - 1 downto 0;
    signal OffsetSel    : integer range DAU_OFFSET_CNT - 1 downto 0;
    signal Offset4      : std_logic_vector(3 downto 0);
    signal Offset8      : std_logic_vector(7 downto 0);
    signal Rn           : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal R0           : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PC           : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal LoadGBR      : std_logic;
    signal IncDecSel    : std_logic;
    signal IncDecBit    : integer range 2 downto 0;
    signal PrePostSel   : std_logic;
    signal CLK          : std_logic;

    -- Observed signals
    signal AddrIDOut   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal DataAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal GBR         : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : DAU
        port map(
            SrcSel => SrcSel,
            OffsetSel => OffsetSel,
            Offset4 => Offset4,
            Offset8 => Offset8,
            Rn => Rn,
            R0 => R0,
            PC => PC,
            LoadGBR => LoadGBR,
            IncDecSel => IncDecSel,
            IncDecBit => IncDecBit,
            PrePostSel => PrePostSel,
            CLK => CLK,
            AddrIDOut => AddrIDOut,
            DataAddr => DataAddr,
            GBR => GBR
        );

    -- Main test loop
    main: process
    begin

        wait until CLK = '0';

        -- Set initial value of GBR
        LoadGBR <= '1';
        Rn <= std_logic_vector(to_unsigned(1000, Rn'length));
        wait until CLK = '0';
        LoadGBR <= '0';
        AlertIf(GBR /= std_logic_vector(to_unsigned(1000, GBR'length)), "Fail GBR");

        -- .W @(disp,PC)
        -- DataAddr = PC + disp8 x 2
        SrcSel <= DAU_AddrPC;
        OffsetSel <= DAU_Offset8x2;
        Offset4 <= (others => 'X');
        Offset8 <= std_logic_vector(to_unsigned(43, Offset8'length));
        Rn <= (others => 'X');
        R0 <= (others => 'X');
        PC <= std_logic_vector(to_signed(100, PC'length));
        LoadGBR <= '0';
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(186, DataAddr'length)), "Fail");

        -- .L @(disp,PC)
        -- DataAddr = PC + disp8 x 4
        SrcSel <= DAU_AddrPC_LW;
        OffsetSel <= DAU_Offset8x4;
        Offset4 <= (others => 'X');
        Offset8 <= std_logic_vector(to_unsigned(8, Offset8'length));
        Rn <= (others => 'X');
        R0 <= (others => 'X');
        PC <= std_logic_vector(to_signed(203, PC'length));
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(232, DataAddr'length)), "Fail");

        -- DataAddr = Rn
        SrcSel <= DAU_AddrRn;
        OffsetSel <= DAU_OffsetZero;
        Offset4 <= (others => 'X');
        Offset8 <= (others => 'X');
        Rn <= std_logic_vector(to_unsigned(200546, Rn'length));
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200546, DataAddr'length)), "Fail");

        -- .B @(disp,Rn)
        -- DataAddr = Rn + disp4 x 1
        SrcSel <= DAU_AddrRn;
        OffsetSel <= DAU_Offset4x1;
        Offset4 <= std_logic_vector(to_unsigned(7, Offset4'length));
        Offset8 <= (others => 'X');
        Rn <= std_logic_vector(to_unsigned(2000, Rn'length));
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(2007, DataAddr'length)), "Fail");

        -- .W @(disp,Rn)
        -- DataAddr = Rn + disp4 x 2
        SrcSel <= DAU_AddrRn;
        OffsetSel <= DAU_Offset4x2;
        Offset4 <= std_logic_vector(to_unsigned(13, Offset4'length));
        Offset8 <= (others => 'X');
        Rn <= std_logic_vector(to_unsigned(12345, Rn'length));
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(12371, DataAddr'length)), "Fail");

        -- .L @(disp,Rn)
        -- DataAddr = Rn + disp4 x 4
        SrcSel <= DAU_AddrRn;
        OffsetSel <= DAU_Offset4x4;
        Offset4 <= std_logic_vector(to_unsigned(14, Offset4'length));
        Offset8 <= (others => 'X');
        Rn <= std_logic_vector(to_unsigned(17, Rn'length));
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(73, DataAddr'length)), "Fail");

        -- DataAddr = R0 + Rn
        SrcSel <= DAU_AddrRn;
        OffsetSel <= DAU_OffsetR0;
        Offset4 <= (others => 'X');
        Offset8 <= (others => 'X');
        Rn <= std_logic_vector(to_unsigned(1019, Rn'length));
        R0 <= std_logic_vector(to_unsigned(2021, Rn'length));
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(3040, DataAddr'length)), "Fail");

        -- DataAddr = GBR + disp8
        SrcSel <= DAU_AddrGBR;
        OffsetSel <= DAU_Offset8x1;
        Offset4 <= (others => 'X');
        Offset8 <= std_logic_vector(to_unsigned(47, Offset8'length));
        Rn <= (others => 'X');
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(1047, DataAddr'length)), "Fail");

        -- DataAddr = GBR + disp8 x 2
        SrcSel <= DAU_AddrGBR;
        OffsetSel <= DAU_Offset8x2;
        Offset4 <= (others => 'X');
        Offset8 <= std_logic_vector(to_unsigned(13, Offset8'length));
        Rn <= (others => 'X');
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(1026, DataAddr'length)), "Fail");

        -- DataAddr = GBR + disp8 x 4
        SrcSel <= DAU_AddrGBR;
        OffsetSel <= DAU_Offset8x4;
        Offset4 <= (others => 'X');
        Offset8 <= std_logic_vector(to_unsigned(96, Offset8'length));
        Rn <= (others => 'X');
        R0 <= (others => 'X');
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(1384, DataAddr'length)), "Fail");

        -- DataAddr = GBR + R0
        SrcSel <= DAU_AddrGBR;
        OffsetSel <= DAU_OffsetR0;
        Offset4 <= (others => 'X');
        Offset8 <= (others => 'X');
        Rn <= (others => 'X');
        R0 <= std_logic_vector(to_unsigned(10001, R0'length));
        PC <= (others => 'X');
        IncDecSel <= 'X';
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(11001, DataAddr'length)), "Fail");

        ------------------------------------------------------------------------
        -- Test Pre/Post Inc/Dec 1/2/4
        ------------------------------------------------------------------------
        SrcSel <= DAU_AddrRn;
        OffsetSel <= DAU_OffsetZero;
        Offset4 <= (others => 'X');
        Offset8 <= (others => 'X');
        Rn <= std_logic_vector(to_unsigned(200, Rn'length));

        -- Pre-decrement Rn by 1
        IncDecSel <= MemUnit_DEC;
        IncDecBit <= 0;
        PrePostSel <= MemUnit_PRE;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(199, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(199, AddrIDOut'length)), "Fail");

        -- Pre-decrement Rn by 2
        IncDecSel <= MemUnit_DEC;
        IncDecBit <= 1;
        PrePostSel <= MemUnit_PRE;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(198, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(198, AddrIDOut'length)), "Fail");

        -- Pre-decrement Rn by 4
        IncDecSel <= MemUnit_DEC;
        IncDecBit <= 2;
        PrePostSel <= MemUnit_PRE;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(196, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(196, AddrIDOut'length)), "Fail");

        -- Post-decrement Rn by 1
        IncDecSel <= MemUnit_DEC;
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(199, AddrIDOut'length)), "Fail");

        -- Post-decrement Rn by 2
        IncDecSel <= MemUnit_DEC;
        IncDecBit <= 1;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(198, AddrIDOut'length)), "Fail");

        -- Post-decrement Rn by 4
        IncDecSel <= MemUnit_DEC;
        IncDecBit <= 2;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(196, AddrIDOut'length)), "Fail");

        -- Pre-increment Rn by 1
        IncDecSel <= MemUnit_INC;
        IncDecBit <= 0;
        PrePostSel <= MemUnit_PRE;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(201, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(201, AddrIDOut'length)), "Fail");

        -- Pre-increment Rn by 2
        IncDecSel <= MemUnit_INC;
        IncDecBit <= 1;
        PrePostSel <= MemUnit_PRE;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(202, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(202, AddrIDOut'length)), "Fail");

        -- Pre-increment Rn by 4
        IncDecSel <= MemUnit_INC;
        IncDecBit <= 2;
        PrePostSel <= MemUnit_PRE;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(204, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(204, AddrIDOut'length)), "Fail");

        -- Post-increment Rn by 1
        IncDecSel <= MemUnit_INC;
        IncDecBit <= 0;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(201, AddrIDOut'length)), "Fail");

        -- Post-increment Rn by 2
        IncDecSel <= MemUnit_INC;
        IncDecBit <= 1;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(202, AddrIDOut'length)), "Fail");

        -- Post-increment Rn by 4
        IncDecSel <= MemUnit_INC;
        IncDecBit <= 2;
        PrePostSel <= MemUnit_POST;
        wait until CLK = '0';
        AlertIf(DataAddr /= std_logic_vector(to_signed(200, DataAddr'length)), "Fail");
        AlertIf(AddrIDOut /= std_logic_vector(to_signed(204, AddrIDOut'length)), "Fail");

        
        wait for 10 ns;

        -- End of testbench reached
        END_SIM <= '1';
        Log("Testbench executed");

        wait;
    end process;

    -- Clock generation
    clock: process
    begin
        if END_SIM = '0' then
            CLK <= '0';
            wait for 10 ns;
        else
            wait;
        end if;

        if END_SIM = '0' then
            CLK <= '1';
            wait for 10 ns;
        else
            wait;
        end if;
    end process;

end TB_ARCHITECTURE;