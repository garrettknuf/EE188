------------------------------------------------------------------------------
--
--  Test Bench for SH-2 Register Array.
--
--  Tests: None. Just checking for compilation errors.
--
--  Revision History:
--     17 April 2025    Garrett Knuf    Initial revision.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.RegConstants.all;

library osvvm;
use osvvm.AlertLogPkg.all;

entity tb_reg is
end tb_reg;

architecture TB_ARCHITECTURE of tb_reg is

    -- Component declaration of the tested unit
    component RegArray

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
            CLK        : in   std_logic;
            RegA       : out  std_logic_vector(LONG_SIZE - 1 downto 0);
            RegB       : out  std_logic_vector(LONG_SIZE - 1 downto 0);
            RegA1      : out  std_logic_vector(LONG_SIZE - 1 downto 0);
            RegA2      : out  std_logic_vector(LONG_SIZE - 1 downto 0)
        );

    end component;

    -- Stimulus signals
    signal RegIn      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegInSel   : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegStore   : std_logic;
    signal RegASel    : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegBSel    : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxIn    : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegAxInSel : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegAxStore : std_logic;
    signal RegA1Sel   : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal RegA2Sel   : integer  range REGARRAY_RegCnt - 1 downto 0;
    signal CLK        : std_logic;


    -- Observed signals
    signal RegA       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegB       : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA1      : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal RegA2      : std_logic_vector(LONG_SIZE - 1 downto 0);

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : RegArray
        port map(
            RegIn => RegIn,
            RegInSel => RegInSel,
            RegStore => RegStore,
            RegASel => RegASel,
            RegBSel => RegBSel,
            RegAxIn => RegAxIn,
            RegAxInSel => RegAxInSel,
            RegAxStore => RegAxStore,
            RegA1Sel => RegA1Sel,
            RegA2Sel => RegA2Sel,
            CLK => CLK,
            RegA => RegA,
            RegB => RegB,
            RegA1 => RegA1,
            RegA2 => RegA2
        );

    -- Main test loop
    main: process
    begin

        wait for 10 ns;

        -- No tests. Just checking for compilation errors for now.

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