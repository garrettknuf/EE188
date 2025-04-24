----------------------------------------------------------------------------
--
--  Program Memory Access Unit (PAU)
--
--  This is an implementation of a program memory access unit for the SH-2 CPU.
--  The program memory is addressed as 16-bit words with 32-bits of address. The
--  interface is read only. The program counter (PC) is incremented by the word
--  size on each instruction fetch. Some instruction (conditional branches) have
--  the ability to set the PC or add a signed value to it. The address of an
--  instruction must be even.
--
--  Packages included are:
--     PAUConstants - constants for the program access unit
--
--  Entities included are:
--     PAU - program memory access unit
--
--  Revision History:
--     16 Apr 2025  Garrett Knuf    Initial Revision.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the PAU.
--

library ieee;
use ieee.std_logic_1164.all;

package PAUConstants is

    constant PAU_SRC_CNT    : integer := 2;     -- number of PAU address sources
    constant PAU_OFFSET_CNT : integer := 6;     -- number of PAU offset sources

    -- Address source mux select
    constant PAU_AddrZero   : integer := 0;     -- zero
    constant PAU_AddrPC     : integer := 1;     -- PC

    -- Offset source mux select
    constant PAU_OffsetZero : integer := 0;     -- zero
    constant PAU_OffsetWord : integer := 1;     -- wordsize (2)
    constant PAU_Offset8    : integer := 2;     -- 8-bit offset (sign ext.)
    constant PAU_Offset12   : integer := 3;     -- 12-bit offset (sign ext.)
    constant PAU_OffsetReg  : integer := 4;     -- register value
    constant PAU_OffsetPR   : integer := 5;     -- PR

end package;


--
-- PAU
--
-- This is an implementation of the program access memory unit for the SH-2 CPU.
-- It uses the generic MemUnit to handle many of the program address
-- calculations.
--
-- Inputs:
--  SrcSel      - mux select for address source
--  OffsetSel   - mux select for offset source 
--  Offset8     - 8-bit offset value
--  Offset12    - 12-bit offset value
--  OffsetReg   - register value to use as offset
--  UpdatePC    - change PC value (1) or hold (0)
--  UpdatePR    - change PR value (1) or hold (0)
--  CLK         - clock
--
-- Outputs:
--  ProgAddr    - program address bus
--  PC          - program counter register
--  PR          - procedure register
--

library ieee;
use ieee.std_logic_1164.all;
use work.array_type_pkg.all;
use work.GenericConstants.all;
use work.MemUnitConstants.all;
use work.PAUConstants.all;

entity PAU is

    port (
        SrcSel      : in    integer range PAU_SRC_CNT - 1 downto 0;
        OffsetSel   : in    integer range PAU_OFFSET_CNT - 1 downto 0;
        Offset8     : in    std_logic_vector(7 downto 0);
        Offset12    : in    std_logic_vector(11 downto 0);
        OffsetReg   : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        UpdatePC    : in    std_logic;
        UpdatePR    : in    std_logic;
        CLK         : in    std_logic;
        RST         : in    std_logic;
        ProgAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        PC          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        PR          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)
    );

end PAU;


architecture behavioral of PAU is

    component MemUnit is
        generic (
            srcCnt       : integer;
            offsetCnt    : integer;
            maxIncDecBit : integer;
            wordsize     : integer
        );
        port(
            AddrSrc    : in      std_logic_array(srccnt - 1 downto 0)(wordsize - 1 downto 0);
            SrcSel     : in      integer  range srccnt - 1 downto 0;
            AddrOff    : in      std_logic_array(offsetcnt - 1 downto 0)(wordsize - 1 downto 0);
            OffsetSel  : in      integer  range offsetcnt - 1 downto 0;
            IncDecSel  : in      std_logic;
            IncDecBit  : in      integer  range maxIncDecBit downto 0;
            PrePostSel : in      std_logic;
            Address    : out     std_logic_vector(wordsize - 1 downto 0);
            AddrSrcOut : buffer  std_logic_vector(wordsize - 1 downto 0)
        );
    end component;
    
    -- Address mux sources
    signal AddrSrc  : std_logic_array(PAU_SRC_CNT - 1 downto 0)(ADDR_BUS_SIZE - 1 downto 0);

    -- Address offset mux sources
    signal AddrOff  : std_logic_array(PAU_OFFSET_CNT - 1 downto 0)(ADDR_BUS_SIZE - 1 downto 0);

    -- Incrementer/decrementer controls
    signal IncDecSel    : std_logic;                -- not used
    signal IncDecBit    : integer range 0 downto 0; -- not used
    signal PrePostSel   : std_logic;                -- mux select for pre/post
    signal AddrSrcOut   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0); -- not used

    constant PC_INIT_VALUE : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0) := (others => '0');

begin

    -- Inputs to address source mux
    AddrSrc(PAU_AddrZero) <= (others => '0');   -- Zero
    AddrSrc(PAU_AddrPC) <= PC;                  -- PC

    -- Inputs to offset mux
    AddrOff(PAU_OffsetZero) <= (others => '0');                                 -- Zero
    AddrOff(PAU_OffsetWord) <= (31 downto 2 => '0') & "10";                     -- Two (offset to next word)
    AddrOff(PAU_Offset8) <= (31 downto 9 => Offset8(7)) & Offset8 & '0';        -- disp8 x 2 (sign-extended)
    AddrOff(PAU_Offset12) <= (31 downto 13 => Offset12(11)) & Offset12 & '0';   -- disp12 x 2 (sign-extended)
    AddrOff(PAU_OffsetReg) <= OffsetReg;                                        -- register value
    AddrOff(PAU_OffsetPR) <= PR;                                                -- procedure register

    -- Incrementer/decrement controls
    IncDecSel <= MemUnit_INC;   -- not used (preventing undefined value)
    IncDecBit <= 0;             -- not used (preventing undefined value)
    PrePostSel <= MemUnit_POST; -- use post value to ignore inc/dec

    -- Update registors of PAU
    PAU_registers : process (CLK)
    begin
        if rising_edge(CLK) then

            if RST = '1' then
                -- Update PC
                PC <= ProgAddr when UpdatePC = '1' else PC;
            else
                PC <= PC_INIT_VALUE;
            end if;

            -- Update PR
            PR <= ProgAddr when UpdatePR = '1' else PR;
        end if;
    end process;

    -- Instantiate generic memory unit
    Generic_PAU : MemUnit
        generic map (
            srcCnt => PAU_SRC_CNT,          -- number of address sources
            offsetCnt => PAU_OFFSET_CNT,    -- number of offset sources
            maxIncDecBit => 0,              -- no inc/dec
            wordsize => ADDR_BUS_SIZE       -- 32-bit addressing
        )
        port map (
            AddrSrc => AddrSrc,         -- address source
            SrcSel => SrcSel,           -- address source mux select
            AddrOff => AddrOff,         -- offset source
            OffsetSel => OffsetSel,     -- offset source mux select
            IncDecSel => IncDecSel,     -- not used
            IncDecBit => IncDecBit,     -- not used
            PrePostSel => PrePostSel,   -- always post
            Address => ProgAddr,        -- address bus
            AddrSrcOut => AddrSrcOut    -- inc/dec source
        );

end behavioral;
