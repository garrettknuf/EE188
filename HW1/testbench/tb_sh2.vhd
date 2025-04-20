------------------------------------------------------------------------------
--
--  Test Bench for SH-2.
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

library osvvm;
use osvvm.AlertLogPkg.all;

entity tb_sh2 is
end tb_sh2;

architecture TB_ARCHITECTURE of tb_sh2 is

    -- Component declaration of the tested unit
    component SH2

        port (
            DataBus     : in    std_logic_vector(15 downto 0);
            CLK         : in    std_logic;
            AddrBus     : out   std_logic_vector(31 downto 0)
        );

    end component;

    -- Stimulus signals
    signal DataBus  : std_logic_vector(15 downto 0);
    signal CLK      : std_logic;

    -- Observed signals
    signal AddrBus  : std_logic_vector(31 downto 0);

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : SH2
        port map(
            DataBus => DataBus,
            CLK     => CLK,
            AddrBus => AddrBus
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