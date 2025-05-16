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

    constant PAU_SRC_CNT    : integer := 4;     -- number of PAU address sources
    constant PAU_OFFSET_CNT : integer := 7;     -- number of PAU offset sources

    -- Address source mux select
    constant PAU_AddrZero   : integer := 0;     -- zero
    constant PAU_AddrPC     : integer := 1;     -- PC
    constant PAU_AddrPR     : integer := 2;     -- PR
    constant PAU_AddrDB     : integer := 3;     -- DB

    -- Offset source mux select
    constant PAU_OffsetZero : integer := 0;     -- zero
    constant PAU_OffsetWord : integer := 1;     -- wordsize (2)
    constant PAU_OffsetLong : integer := 2;     -- wordsize (2)
    constant PAU_Offset8    : integer := 3;     -- 8-bit offset (sign ext.)
    constant PAU_Offset12   : integer := 4;     -- 12-bit offset (sign ext.)
    constant PAU_OffsetReg  : integer := 5;     -- register value
    constant PAU_TempReg1   : integer := 6;     -- temporary register 1

    constant PRSEL_CNT : integer := 4;
    constant PRSel_None : integer range PRSEL_CNT-1 downto 0 := 0;
    constant PRSel_PC   : integer range PRSEL_CNT-1 downto 0 := 1;
    constant PRSel_Reg  : integer range PRSEL_CNT-1 downto 0 := 2;
    constant PRSel_DB   : integer range PRSEL_CNT-1 downto 0 := 3;

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
        TempReg1    : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        UpdatePC    : in    std_logic;
        PRSel       : in    integer range PRSEL_CNT-1 downto 0;
        IncDecBit   : in    integer range 2 downto 0;
        IncDecSel   : in    std_logic;
        PrePostSel  : in    std_logic;
        DB          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        CLK         : in    std_logic;
        ProgAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);
        PC          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0) := x"DEADBEEF";
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
    -- signal IncDecSel    : std_logic;                --
    -- signal IncDecBit    : integer range 0 downto 0; -- not used
    -- signal PrePostSel   : std_logic;                -- mux select for pre/post
    signal AddrSrcOut   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0); -- not used


begin

    -- Inputs to address source mux
    AddrSrc(PAU_AddrZero) <= (others => '0');   -- Zero
    AddrSrc(PAU_AddrPC) <= PC;                  -- PC
    AddrSrc(PAU_AddrPR) <= PR;
    AddrSrc(PAU_AddrDB) <= DB;

    -- Inputs to offset mux
    AddrOff(PAU_OffsetZero) <= (others => '0');                                 -- Zero
    AddrOff(PAU_OffsetWord) <= (31 downto 2 => '0') & "10";                     -- Two (offset to next word)
    AddrOff(PAU_OffsetLong) <= (31 downto 3 => '0') & "100";                    -- Four (offset to word after the next)
    AddrOff(PAU_Offset8) <= (31 downto 9 => Offset8(7)) & Offset8 & '0';        -- disp8 x 2 (sign-extended)
    AddrOff(PAU_Offset12) <= (31 downto 13 => Offset12(11)) & Offset12 & '0';   -- disp12 x 2 (sign-extended)
    AddrOff(PAU_OffsetReg) <= OffsetReg;                                        -- register value
    AddrOff(PAU_TempReg1) <= TempReg1;                                          -- temporary register

    -- Incrementer/decrement controls
    -- IncDecSel <= MemUnit_DEC;   -- not used (preventing undefined value)
    -- IncDecBit <= 0;             -- not used (preventing undefined value)
    -- PrePostSel <= MemUnit_POST; -- use post value to ignore inc/dec

    -- Update registors of PAU
    PAU_registers : process (CLK)
    begin
        if rising_edge(CLK) then

            PC <= ProgAddr when UpdatePC = '1' else PC;

            -- Update PR
            PR <= PC        when PRSel = PRSel_PC   else 
                  OffsetReg when PRSel = PRSel_Reg  else
                  DB        when PRSel = PRSel_DB   else
                  PR        when PRSel = PRSel_None else
                  (others => 'Z');
        end if;
    end process;

    -- Instantiate generic memory unit
    Generic_PAU : MemUnit
        generic map (
            srcCnt => PAU_SRC_CNT,          -- number of address sources
            offsetCnt => PAU_OFFSET_CNT,    -- number of offset sources
            maxIncDecBit => 2,              -- 
            wordsize => ADDR_BUS_SIZE       -- 32-bit addressing
        )
        port map (
            AddrSrc => AddrSrc,         -- address source
            SrcSel => SrcSel,           -- address source mux select
            AddrOff => AddrOff,         -- offset source
            OffsetSel => OffsetSel,     -- offset source mux select
            IncDecSel => IncDecSel,     --
            IncDecBit => IncDecBit,     --
            PrePostSel => PrePostSel,   -- always post
            Address => ProgAddr,        -- address bus
            AddrSrcOut => AddrSrcOut    -- inc/dec source
        );

end behavioral;
