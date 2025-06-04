----------------------------------------------------------------------------
--
--  Program Memory Access Unit (PAU)
--
--  This is an implementation of a program memory access unit for the SH-2 CPU.
--  The program memory access unit generates the addresses for reads of the program
--  memory data. The program memory is addressed as 16-bit words with 32-bits of
--  address that must be accessed as even addresses only. It contains the program
--  counter register (PC) and the procedure register (PR). It supports various
--  address and offset sources, including immediate values and registers.
--  The PC is incremented by the word size (2 bytes) during normal execution, and
--  can alsob explicitly modified (e.g., branches or procedure calls).
--
--  Packages included are:
--     PAUConstants - constants for the program access unit
--
--  Entities included are:
--     PAU - program memory access unit
--
--  Revision History:
--     16 Apr 2025  Garrett Knuf    Initial Revision.
--      9 May 2025  Garrett Knuf    Add procedure register.
--      2 Jun 2025  Garrett Knuf    Add PC_EX signal for pipelining.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the PAU.
--

library ieee;
use ieee.std_logic_1164.all;

package PAUConstants is

    constant PAU_SRC_CNT    : integer := 5;     -- number of PAU address sources
    constant PAU_OFFSET_CNT : integer := 7;     -- number of PAU offset sources

    -- Address source mux select
    constant PAU_AddrZero   : integer := 0;     -- zero
    constant PAU_AddrPC     : integer := 1;     -- PC
    constant PAU_AddrPR     : integer := 2;     -- PR
    constant PAU_AddrDB     : integer := 3;     -- DB
    constant PAU_AddrPC_EX  : integer := 4;     -- pipelined PC (delayed by 1 clock)

    -- Offset source mux select
    constant PAU_OffsetZero : integer := 0;     -- zero
    constant PAU_OffsetWord : integer := 1;     -- wordsize (2)
    constant PAU_OffsetLong : integer := 2;     -- wordsize (2)
    constant PAU_Offset8    : integer := 3;     -- 8-bit offset (sign ext.)
    constant PAU_Offset12   : integer := 4;     -- 12-bit offset (sign ext.)
    constant PAU_OffsetReg  : integer := 5;     -- register value
    constant PAU_TempReg    : integer := 6;     -- temporary register

    -- Procedure register (PR) source select
    constant PRSEL_CNT : integer := 4;
    constant PRSel_None : integer range PRSEL_CNT-1 downto 0 := 0;  -- no change
    constant PRSel_PC   : integer range PRSEL_CNT-1 downto 0 := 1;  -- program counter
    constant PRSel_Reg  : integer range PRSEL_CNT-1 downto 0 := 2;  -- generic register
    constant PRSel_DB   : integer range PRSEL_CNT-1 downto 0 := 3;  -- databus

end package;


--
-- PAU
--
-- This is an implementation of the program access memory unit for the SH-2 CPU.
-- It includes the program counter (PC) and procedure register (PR), and supports
-- a variety of address sources (PC, PR, DB, zero) and offset type (immediate,
-- register, etc.). Address calculation is handled using a generic MemUnit component.
--
-- Inputs:
--  SrcSel      - mux select for address source
--  OffsetSel   - mux select for offset source 
--  Offset8     - 8-bit offset value
--  Offset12    - 12-bit offset value
--  OffsetReg   - register value to use as offset
--  TempReg     - temporary register
--  UpdatePC    - change PC value or hold
--  PRSel       - select modification to PR
--  IncDecBit   - select bit for maximum inc/dec operations
--  PrePostSel  - select pre/post when inc/dec address output
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
        -- Control signals
        SrcSel      : in    integer range PAU_SRC_CNT - 1 downto 0;         -- source select
        OffsetSel   : in    integer range PAU_OFFSET_CNT - 1 downto 0;      -- offset select
        UpdatePC    : in    std_logic;                                      -- update PC or hold
        PRSel       : in    integer range PRSEL_CNT-1 downto 0;             -- select modify PR
        IncDecSel   : in    std_logic;                                      -- select inc/dec
        IncDecBit   : in    integer range 2 downto 0;                       -- select bit to inc/dec
        PrePostSel  : in    std_logic;                                      -- select decrement by 4

        -- Source inputs
        DB          : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- data bus
        PC_EX       : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- pipelined PC (delayed by 1 clock)

        -- Offset inputs
        Offset8     : in    std_logic_vector(7 downto 0);                   -- 8-bit offset
        Offset12    : in    std_logic_vector(11 downto 0);                  -- 12-bit offset
        OffsetReg   : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- register offest
        TempReg     : in    std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- temporary register offset

        -- System signal
        CLK         : in    std_logic;                                      -- clock
        RESET       : in    std_logic;                                      -- reset

        -- Output signals
        ProgAddr    : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program address
        PC          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0);   -- program counter
        PR          : out   std_logic_vector(ADDR_BUS_SIZE - 1 downto 0)    -- procedure register
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
    signal AddrSrcOut   : std_logic_vector(ADDR_BUS_SIZE - 1 downto 0); -- not used

begin

    -- Inputs to address source mux
    AddrSrc(PAU_AddrZero) <= (others => '0');   -- Zero
    AddrSrc(PAU_AddrPC) <= PC;                  -- PC
    AddrSrc(PAU_AddrPR) <= PR;                  -- PR
    AddrSrc(PAU_AddrDB) <= DB;                  -- DB
    AddrSrc(PAU_AddrPC_EX) <= PC_EX;

    -- Inputs to offset mux
    AddrOff(PAU_OffsetZero) <= (others => '0');                                 -- Zero
    AddrOff(PAU_OffsetWord) <= (31 downto 2 => '0') & "10";                     -- Two (offset to next word)
    AddrOff(PAU_OffsetLong) <= (31 downto 3 => '0') & "100";                    -- Four (offset to word after the next)
    AddrOff(PAU_Offset8) <= (31 downto 9 => Offset8(7)) & Offset8 & '0';        -- disp8 x 2 (sign-extended)
    AddrOff(PAU_Offset12) <= (31 downto 13 => Offset12(11)) & Offset12 & '0';   -- disp12 x 2 (sign-extended)
    AddrOff(PAU_OffsetReg) <= OffsetReg;                                        -- register value
    AddrOff(PAU_TempReg) <= TempReg;                                            -- temporary register

    -- Update registers of PAU
    PAU_registers : process (CLK)
    begin
        if rising_edge(CLK) then

            -- Update PC
            if (RESET = '0') then
                PC <= x"FFFFFFFE";
            else
                PC <= ProgAddr when UpdatePC = '1' else PC;
            end if;

            -- Update PR
            PR <= PC        when PRSel = PRSel_PC   else    -- program counter
                  OffsetReg when PRSel = PRSel_Reg  else    -- offset register
                  DB        when PRSel = PRSel_DB   else    -- databus
                  PR        when PRSel = PRSel_None else    -- no change
                  (others => 'Z');
        end if;
    end process;

    -- Instantiate generic memory unit
    Generic_PAU : MemUnit
        generic map (
            srcCnt => PAU_SRC_CNT,          -- number of address sources
            offsetCnt => PAU_OFFSET_CNT,    -- number of offset sources
            maxIncDecBit => 2,              -- always decrementing by 4 (log_2(4)=2)
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