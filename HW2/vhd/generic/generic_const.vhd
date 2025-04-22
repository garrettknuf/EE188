----------------------------------------------------------------------------
--
--  Generic Constants
--
--  This is package for general system constants.
--
--  Revision History:
--     17 Apr 25    Garrett Knuf    Initial revision.
--
----------------------------------------------------------------------------

--
--  Package containing the generic constants.
--

library ieee;
use ieee.std_logic_1164.all;

package  GenericConstants  is

    constant BYTE_SIZE : integer := 8;  -- byte num bits
    constant WORD_SIZE : integer := 16; -- word num bits
    constant LONG_SIZE : integer := 32; -- long word num bits

    constant ADDR_BUS_SIZE : integer := LONG_SIZE;  -- address bus num bits
    constant DATA_BUS_SIZE : integer := WORD_SIZE;  -- data bus num bits
    constant REG_SIZE      : integer := LONG_SIZE;   -- register size

    constant True   : std_logic := '1';
    constant False  : std_logic := '0';

end package;