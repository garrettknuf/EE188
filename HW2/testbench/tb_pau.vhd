------------------------------------------------------------------------------
--
--  Test Bench for SH-2 Program Memory Access Unit (PAU).
--
--  Tests (not in order):
--   Setting PC (JMP)
--   Move to next instruction (PC + wordsize)
--   BF, BF/S, BT, BT/S, BRA, BRAF
--   BSR, BSRF (saving PR)
--   RTS (restoring PC from PR)
--
--  Revision History:
--     16 April 2025    Garrett Knuf    Initial revision.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.PAUConstants.all;

library osvvm;
use osvvm.AlertLogPkg.all;

entity tb_pau is
end tb_pau;

architecture TB_ARCHITECTURE of tb_pau is

    -- Component declaration of the tested unit
    component PAU

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

    -- Stimulus signals
    signal SrcSel      : integer range PAU_SRC_CNT - 1 downto 0;
    signal OffsetSel   : integer range PAU_OFFSET_CNT - 1 downto 0;
    signal Offset8     : std_logic_vector(7 downto 0);
    signal Offset12    : std_logic_vector(11 downto 0);
    signal OffsetReg   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal UpdatePC    : std_logic;
    signal UpdatePR    : std_logic;
    signal CLK         : std_logic;

    -- Observed signals
    signal ProgAddr    : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PC          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal PR          : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : PAU
        port map(
            SrcSel => SrcSel,
            OffsetSel => OffsetSel,
            Offset8 => Offset8,
            Offset12 => Offset12,
            OffsetReg => OffsetReg,
            UpdatePC => UpdatePC,
            UpdatePR => UpdatePR,
            CLK => CLK,
            ProgAddr => ProgAddr,
            PC => PC,
            PR => PR
        );

    -- Main test loop
    main: process
    begin

        wait until CLK = '0';

        -- Set initial value of PC (JMP)
        -- PC = 0
        SrcSel <= PAU_AddrZero;
        OffsetSel <= PAU_OffsetReg;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= (others => '0');
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';

        -- Move to next word (non-branching instruction)
        -- PC += 2
        SrcSel <= PAU_AddrPC;
        OffsetSel <= PAU_OffsetWord;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= (others => 'X');
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(2, PC'length)), "Fail");

        -- BF, BF/S, BT, BT/S
        -- PC += offset8 x 2
        SrcSel <= PAU_AddrPC;
        OffsetSel <= PAU_Offset8;
        Offset8 <= std_logic_vector(to_unsigned(73, Offset8'length));
        Offset12 <= (others => 'X');
        OffsetReg <= (others => 'X');
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(148, PC'length)), "Fail");

        -- BRA
        -- PC += offset12 x 2
        SrcSel <= PAU_AddrPC;
        OffsetSel <= PAU_Offset12;
        Offset8 <= (others => 'X');
        Offset12 <= std_logic_vector(to_unsigned(347, Offset12'length));
        OffsetReg <= (others => 'X');
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(842, PC'length)), "Fail");

        -- BRAF
        -- PC += Rm
        SrcSel <= PAU_AddrPC;
        OffsetSel <= PAU_OffsetReg;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= std_logic_vector(to_signed(-40, OffsetReg'length));
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(802, PC'length)), "Fail");

        -- BSR
        SrcSel <= PAU_AddrPC;
        OffsetSel <= PAU_Offset12;
        Offset8 <= (others => 'X');
        Offset12 <= std_logic_vector(to_signed(-123, Offset12'length));
        OffsetReg <= (others => 'X');
        UpdatePC <= '1';
        UpdatePR <= '1';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(556, PC'length)), "Fail");
        AlertIf(PR /= std_logic_vector(to_unsigned(556, PC'length)), "Fail");

        -- JMP
        SrcSel <= PAU_AddrZero;
        OffsetSel <= PAU_OffsetReg;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= std_logic_vector(to_signed(240, OffsetReg'length));
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(240, PC'length)), "Fail");
        AlertIf(PR /= std_logic_vector(to_unsigned(556, PC'length)), "Fail");

        -- RTS
        SrcSel <= PAU_AddrZero;
        OffsetSel <= PAU_OffsetPR;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= (others => 'X');
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(556, PC'length)), "Fail");

        -- BSRF
        SrcSel <= PAU_AddrPC;
        OffsetSel <= PAU_OffsetReg;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= std_logic_vector(to_signed(4000, OffsetReg'length));
        UpdatePC <= '1';
        UpdatePR <= '1';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(4556, PC'length)), "Fail");
        AlertIf(PR /= std_logic_vector(to_unsigned(4556, PC'length)), "Fail");

        -- JMP
        SrcSel <= PAU_AddrZero;
        OffsetSel <= PAU_OffsetReg;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= std_logic_vector(to_signed(16789, OffsetReg'length));
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(16789, PC'length)), "Fail");
        AlertIf(PR /= std_logic_vector(to_unsigned(4556, PC'length)), "Fail");

        -- RTS
        SrcSel <= PAU_AddrZero;
        OffsetSel <= PAU_OffsetPR;
        Offset8 <= (others => 'X');
        Offset12 <= (others => 'X');
        OffsetReg <= (others => 'X');
        UpdatePC <= '1';
        UpdatePR <= '0';

        wait until CLK = '0';
        AlertIf(PC /= std_logic_vector(to_unsigned(4556, PC'length)), "Fail");

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