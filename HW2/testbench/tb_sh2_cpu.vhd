------------------------------------------------------------------------------
--
--  Test Bench for SH-2 CPU.
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

entity tb_sh2_cpu is
end tb_sh2_cpu;

architecture TB_ARCHITECTURE of tb_sh2_cpu is

    -- Component declaration of the tested unit
    component SH2_CPU

        port (
            CLK     : in    std_logic;
            DB      : inout std_logic_vector(15 downto 0);
            AB      : out   std_logic_vector(31 downto 0);
            RD      : out   std_logic;
            WR      : out   std_logic
        );

    end component;

    -- Stimulus signals
    signal DB   : std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
    signal CLK  : std_logic;

    -- Observed signals
    signal AB  : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
    signal RD  : std_logic;
    signal WR  : std_logic;

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : SH2_CPU
        port map(
            CLK     => CLK,
            DB      => DB,
            AB      => AB,
            RD      => RD,
            WR      => WR
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