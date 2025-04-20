----------------------------------------------------------------------------
--
--  Status Register
--
--  This is a implementation of a status register for the Hitachi SH-2 CPU.
--  It is a 32-bit register which holds the resulting status from an ALU compare
--  operation (Tbit). It can also be set or cleared. Some instructions may not
--  require the Tbit to change in which case it is sticky.
--
--  Entities included are:
--     SR - status register
--
--  Revision History:
--     18 Apr 2025  Garrett Knuf    Initial Revision (only T-bit).
--
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package StatusRegConstants is

    constant StatusReg_Tbit     : integer := 0; -- T bit
    constant StatusReg_Sbit     : integer := 1; -- S bit
    constant StatusReg_I0bit    : integer := 4; -- Interrupt mask I0
    constant StatusReg_I1bit    : integer := 5; -- Interrupt mask I1
    constant StatusReg_I2bit    : integer := 6; -- Interrupt mask I2
    constant StatusReg_I3bit    : integer := 7; -- Interrupt mask I3
    constant StatusReg_Qbit     : integer := 8; -- Q bit
    constant StatusReg_Mbit     : integer := 9; -- M bit

end package;

--
-- SH2_SR
--
-- This is the status register for the SH2 CPU.
--
--  Inputs:
--    Tbit          - comparison output from ALU
--    UpdateTbit    - change Tbit (1) or not (0)
--    CLK           - system clock
--
--  Outputs:
--    SR            - 32-bit status register
--

library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;
use work.StatusRegConstants.all;

entity StatusReg is

    port (
        Tbit        : in    std_logic;
        UpdateTbit  : in    std_logic;
        CLK         : in    std_logic;
        SR          : out   std_logic_vector(REG_SIZE - 1 downto 0)
    );

end StatusReg;


architecture behavioral of StatusReg is
begin

    process (CLK)
    begin

        if rising_edge(CLK) then

            -- Change T bit if it should be updated
            SR(StatusReg_Tbit) <= Tbit when UpdateTbit = '1' else SR(StatusReg_Tbit);

        end if;

    end process;

end behavioral;











