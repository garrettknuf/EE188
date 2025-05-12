----------------------------------------------------------------------------
--
--  Arithmetic Logic Unit (ALU)
--
--  This is a implementation of an ALU for the SH-2 processor. It can perform
--  all of the standard logic and arithmetic operations. These include Boolean
--  operations, shifts and rotates, bit functions, addition, subtraction, and
--  comparison. These operands may be registers or immediate values (from the
--  instruction). It does not include a multiplier, MAC, divider, or barrel shifter.
--  It implements the GenericALU for general ALU ops and provides an interface
--  specific for the SH2.
--
--  Packages included are:
--     TbitConstants - constants for the Tbit control
--
--  Entities included are:
--     ALU - arithmetic logic unit
--
--  Revision History:
--     17 Apr 2025  Garrett Knuf    Initial Revision.
--
----------------------------------------------------------------------------

--
-- Package containing constants for modifying the T-bit.
--

library ieee;
use ieee.std_logic_1164.all;

package TbitConstants is

    constant Tbit_Carry     : std_logic_vector(3 downto 0) := "0000";     -- set to carry flag
    constant Tbit_Borrow    : std_logic_vector(3 downto 0) := "0001";     -- set to borrow flag (not carry)
    constant Tbit_Overflow  : std_logic_vector(3 downto 0) := "0010";     -- set to overflow flag
    constant Tbit_Zero      : std_logic_vector(3 downto 0) := "0011";     -- set to zero flag
    constant Tbit_Sign      : std_logic_vector(3 downto 0) := "0100";     -- set to sign flag
    constant Tbit_GEQ       : std_logic_vector(3 downto 0) := "0101";     -- set when A >= B (signed)
    constant Tbit_GT        : std_logic_vector(3 downto 0) := "0110";     -- set when A > B (signed)
    constant Tbit_HI        : std_logic_vector(3 downto 0) := "0111";     -- set when A > B (unsigned)
    constant Tbit_STR       : std_logic_vector(3 downto 0) := "1000";     -- set when A and B have same byte
    constant Tbit_PL        : std_logic_vector(3 downto 0) := "1001";     -- set when A > 0
    constant Tbit_PZ        : std_logic_vector(3 downto 0) := "1010";    -- set when A >= 0
    constant Tbit_TAS       : std_logic_vector(3 downto 0) := "1011";

end package;

--
-- ALU
--
-- This is an implementation of an ALU for the SH-2 processor. It uses the
-- GenericALU module and consolidates the flags into a T-bit.
--
--  Inputs:
--    ALUOpA   - first operand
--    ALUOpB   - second operand
--    Cin      - carry in (from status register)
--    FCmd     - F-Block operation to perform (4 bits)
--    CinCmd   - adder carry in operation for carry in (2 bits)
--    SCmd     - shift operation to perform (3 bits)
--    ALUCmd   - ALU operation to perform - selects result (2 bits)
--    TbitOp   - select how T-bit is calculated
--
--  Outputs:
--    Result   - ALU result
--    T-bit    - condition checking bit
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.GenericConstants.all;
use work.ALUConstants.all;
use work.TbitConstants.all;

entity ALU is

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

end ALU;


architecture behavioral of ALU is

    component GenericALU is
        generic (
            wordsize : integer
        );
    
        port(
            ALUOpA   : in      std_logic_vector(wordsize - 1 downto 0);   -- first operand
            ALUOpB   : in      std_logic_vector(wordsize - 1 downto 0);   -- second operand
            Cin      : in      std_logic;                                 -- carry in
            FCmd     : in      std_logic_vector(3 downto 0);              -- F-Block operation
            CinCmd   : in      std_logic_vector(1 downto 0);              -- carry in operation
            SCmd     : in      std_logic_vector(3 downto 0);              -- shift operation
            ALUCmd   : in      std_logic_vector(1 downto 0);              -- ALU result select
            Result   : buffer  std_logic_vector(wordsize - 1 downto 0);   -- ALU result
            Cout     : out     std_logic;                                 -- carry out
            HalfCout : out     std_logic;                                 -- half carry out
            Overflow : out     std_logic;                                 -- signed overflow
            Zero     : out     std_logic;                                 -- result is zero
            Sign     : out     std_logic                                  -- sign of result
        );
    end component;

    -- Flags
    signal Cout     : std_logic;
    signal HalfCout : std_logic;
    signal Overflow : std_logic;
    signal Zero     : std_logic;
    signal Sign     : std_logic;

    -- T-bit intermediate calcuations
    signal GEQ  : std_logic;    -- greater than or equal
    signal GT   : std_logic;    -- greater than
    signal STR  : std_logic;    -- if Rn and Rm have equivalent byte
    signal PL   : std_logic;    -- if Rn > 0
    signal PZ   : std_logic;    -- if Rn >= 0
    signal TASZero : std_logic;

begin

    -- T-bit intermediate calculations
    GEQ <= not (Sign xor Overflow);
    GT <= GEQ and not Zero;
    STR <= '1' when ALUOpA(7 downto 0) = ALUOpB(7 downto 0) or
                    ALUOpA(15 downto 8) = ALUOpB(15 downto 8) or
                    ALUOpA(23 downto 16) = ALUOpB(23 downto 16) or 
                    ALUOpA(31 downto 24) = ALUOpB(31 downto 24) else '0';
    PZ <= not Sign;
    PL <= not Sign and not Zero;

    TASZero <= '1' when ALUOpA(7 downto 0) = "00000000" else '0';

    -- Mux to determine value of T-bit
    Tbit <= Cout        when TbitOp = Tbit_Carry     else
            not Cout    when TbitOp = Tbit_Borrow    else
            Overflow    when TbitOp = Tbit_Overflow  else
            Zero        when TbitOp = Tbit_Zero      else
            Sign        when TbitOp = Tbit_Sign      else
            GEQ         when TbitOp = Tbit_GEQ       else
            GT          when TbitOp = Tbit_GT        else
            STR         when TbitOp = Tbit_STR       else
            PL          when TbitOp = Tbit_PL        else
            PZ          when TbitOp = Tbit_PZ        else
            TASZero     when TbitOp = Tbit_TAS       else
            'X';         

    -- Instantiate generic memory unit
    Generic_ALU : GenericALU
        generic map (
            wordsize => LONG_SIZE
        )
        port map (
            ALUOpA => ALUOpA,
            ALUOpB => ALUOpB,
            Cin => Cin,
            FCmd => FCmd,
            CinCmd => CinCmd,
            SCmd => SCmd,
            ALUCmd => ALUCmd,
            Result => Result,
            Cout => Cout,
            HalfCout => HalfCout,
            Overflow => Overflow,
            Zero => Zero,
            Sign => Sign
        );

end behavioral;











