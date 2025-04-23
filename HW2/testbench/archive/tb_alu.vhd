------------------------------------------------------------------------------
--
--  Test Bench for SH-2 Arithmetic Logic Unit (ALU).
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
use work.GenericALUConstants.all;
use work.TbitConstants.all;

library osvvm;
use osvvm.AlertLogPkg.all;

entity tb_alu is
end tb_alu;

architecture TB_ARCHITECTURE of tb_alu is

    -- Component declaration of the tested unit
    component ALU

        port (
            ALUOpA   : in      std_logic_vector(LONG_SIZE - 1 downto 0);   -- first operand
            ALUOpB   : in      std_logic_vector(LONG_SIZE - 1 downto 0);   -- second operand
            Cin      : in      std_logic;                                 -- carry in
            FCmd     : in      std_logic_vector(3 downto 0);              -- F-Block operation
            CinCmd   : in      std_logic_vector(1 downto 0);              -- carry in operation
            SCmd     : in      std_logic_vector(2 downto 0);              -- shift operation
            ALUCmd   : in      std_logic_vector(1 downto 0);              -- ALU result select
            TbitOp   : in      integer range Tbit_Src_Cnt - 1 downto 0;   -- T-bit operation
            Result   : buffer  std_logic_vector(LONG_SIZE - 1 downto 0);   -- ALU result
            Tbit     : out     std_logic                                  -- T-bit result
        );

    end component;

    -- Stimulus signals
    signal ALUOpA   : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal ALUOpB   : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal Cin      : std_logic;
    signal FCmd     : std_logic_vector(3 downto 0);
    signal CinCmd   : std_logic_vector(1 downto 0);
    signal SCmd     : std_logic_vector(2 downto 0);
    signal ALUCmd   : std_logic_vector(1 downto 0);
    signal TbitOp   : integer range Tbit_Src_Cnt - 1 downto 0;
    signal CLK      : std_logic;

    -- Observed signals
    signal Result   : std_logic_vector(LONG_SIZE - 1 downto 0);
    signal Tbit     : std_logic;

    -- Signal used to stop clock signal generators
    signal END_SIM  : std_logic   := '0';

begin

    -- Unit Under Test port map
    UUT : ALU
        port map(
            ALUOpA => ALUOpA,
            ALUOpB => ALUOpB,
            Cin => Cin,
            FCmd => FCmd,
            CinCmd => CinCmd,
            SCmd => SCmd,
            ALUCmd => ALUCmd,
            TbitOp => TbitOp,
            Result => Result,
            Tbit => Tbit
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