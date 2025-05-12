----------------------------------------------------------------------------
--
--  SH-2 Opcodes
--
--  This is an implementation of 
--
--  Entities included are:
--    
--  Revision History:
--     18 April 2025    Garrett Knuf    Initial revision.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the opcdoes.
--

library ieee;
use ieee.std_logic_1164.all;
use work.GenericConstants.all;

package OpcodeConstants is

    constant OPCODE_SIZE : integer := 16;

    -- Data Transfer Instructions (Table 5.3)
    constant OpMOV_Imm_To_Rn          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "1110------------";
    constant OpMOVW_At_Disp_PC_To_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "1001------------";
    constant OpMOVL_At_Disp_PC_To_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "1101------------";
    constant OpMOV_Rm_To_Rn           : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0011";
    constant OpMOVB_Rm_To_At_Rn       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------0000";
    constant OpMOVW_Rm_To_At_Rn       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------0001";
    constant OpMOVL_Rm_To_At_Rn       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------0010";
    constant OpMOVB_At_Rm_To_Rn       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0000";
    constant OpMOVW_At_Rm_To_Rn       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0001";
    constant OpMOVL_At_Rm_Rn          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0010";
    constant OpMOVB_Rm_To_At_Dec_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------0100";
    constant OpMOVW_Rm_To_At_Dec_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------0101";
    constant OpMOVL_Rm_To_At_Dec_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------0110";
    constant OpMOVB_At_Rm_Inc_To_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0100";
    constant OpMOVW_At_Rm_Inc_To_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0101";
    constant OpMOVL_At_Rm_Inc_To_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0110";
    constant OpMOVB_R0_To_At_Disp_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10000000--------";
    constant OpMOVW_R0_To_At_Disp_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10000001--------";
    constant OpMOVL_R0_To_At_Disp_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0001------------";
    constant OpMOVB_At_Disp_Rm_To_R0  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10000100--------";
    constant OpMOVW_At_Disp_Rm_To_R0  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10000101--------";
    constant OpMOVL_At_Disp_Rm_To_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0101------------";
    constant OpMOVB_Rm_To_At_R0_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000--------0100";
    constant OpMOVW_Rm_To_At_R0_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000--------0101";
    constant OpMOVL_Rm_To_At_R0_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000--------0110";
    constant OpMOVB_At_R0_Rm_To_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000--------1100";
    constant OpMOVW_At_R0_Rm_To_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000--------1101";
    constant OpMOVL_At_R0_Rm_To_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000--------1110";
    constant OpMOVB_R0_To_At_Disp_GBR : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000000--------";
    constant OpMOVW_R0_To_At_Disp_GBR : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000001--------";
    constant OpMOVL_R0_To_At_Disp_GBR : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000010--------";
    constant OpMOVB_At_Disp_GBR_To_R0 : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000100--------";
    constant OpMOVW_At_Disp_GBR_To_R0 : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000101--------";
    constant OpMOVL_At_Disp_GBR_To_R0 : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000110--------";
    constant OpMOVA                   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000111--------";
    constant OpMOVT                   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00101001";
    constant OpSwapB                  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1000";
    constant OpSwapW                  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1001";
    constant OpXTRCT                  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------1101";

    -- Arithmetic Instructions (Table 5.4)
    constant OpADD_Rm_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------1100";
    constant OpADD_Imm_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0111------------";
    constant OpADDC         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------1110";
    constant OpADDV         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------1111";
    constant OpCMP_EQ_Imm   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10001000--------";
    constant OpCMP_EQ_RmRn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------0000";
    constant OpCMP_HS       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------0010";
    constant OpCMP_GE       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------0011";
    constant OpCMP_HI       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------0110";
    constant OpCMP_GT       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------0111";
    constant OpCMP_PL       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00010101";
    constant OpCMP_PZ       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00010001";
    constant OpCMP_STR      : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------1100";
    -- TODO: DIV1
    -- TODO: DIV0S
    -- TODO: DIV0U
    -- TODO: DMULS.L
    -- TODO: DMULU.L
    constant OpDT           : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00010000";
    constant OpEXTS_B       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1110";
    constant OpEXTS_W       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1111";
    constant OpEXTU_B       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1100";
    constant OpEXTU_W       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1101";
    -- TODO: MAC.L
    -- TODO: MAC.W
    -- TODO: MUL.L
    -- TODO: MULS.W
    -- TODO: MULU.W
    constant OpNEG          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1011";
    constant OpNEGC         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------1010";
    constant OpSUB          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------1000";
    constant OpSUBC         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------1010";
    constant OpSUBV         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0011--------1011";

    -- Logic Operation Instructions (Table 5.5)
    constant OpAND_Rm_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------1001";
    constant OpAND_Imm_Rn   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001001--------";
    constant OpAND_Imm_B    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001101--------";
    constant OpNOT          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0110--------0111";
    constant OpOR_Rm_Rn     : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------1011";
    constant OpOR_Imm       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001011--------";
    constant OpOR_Imm_B     : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001111--------";
    constant OpTAS_B        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00011011";
    constant OpTST_Rm_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------1000";
    constant OpTST_Imm      : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001000--------";
    constant OpTST_Imm_B    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001100--------";
    constant OpXOR_Rm_Rn    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0010--------1010";
    constant OpXOR_Imm      : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001010--------";
    constant OpXOR_Imm_B    : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11001110--------";

    -- Shift Instructions (Table 5.6)
    constant OpROTL         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00000100";
    constant OpROTR         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00000101";
    constant OpROTCL        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100100";
    constant OpROTCR        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100101";
    constant OpSHAL         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100000";
    constant OpSHAR         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100001";
    constant OpSHLL         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00000000";
    constant OpSHLR         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00000001";
    constant OpSHLL2        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00001000";
    constant OpSHLR2        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00001001";
    constant OpSHLL8        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00011000";
    constant OpSHLR8        : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00011001";
    constant OpSHLL16       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00101000";
    constant OpSHLR16       : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00101001";

    -- Branch Instructions (Table 5.7)
    constant OpBF           : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10001011--------";
    constant OpBFS          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10001111--------";
    constant OpBT           : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10001001--------";
    constant OpBTS          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "10001101--------";
    constant OpBRA          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "1010------------";
    constant OpBRAF         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00100011";
    constant OpBSR          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "1011------------";
    constant OpBSRF         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00000011";
    constant OpJMP          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00101011";
    constant OpJSR          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00001011";
    constant OpRTS          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000001011";

    -- System Control Instructions (Table 5.8)
    constant OpCLRT                  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000001000";
    -- TODO: CLRMAC
    constant OpLDC_Rm_To_SR          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00001110";
    constant OpLDC_Rm_To_GBR         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00011110";
    constant OpLDC_Rm_To_VBR         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00101110";
    constant OpLDCL_At_Rm_Inc_To_SR  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00000111";
    constant OpLDCL_At_Rm_Inc_To_GBR : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00010111";
    constant OpLDCL_At_Rm_Inc_To_VBR : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100111";
    -- TODO: LDS Rm, MACH
    -- TODO: LDS Rm, MACL
    constant OpLDS_Rm_To_PR          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00101010";
    -- TODO: LDS.L @Rm+, MACH
    -- TODO: LDS.L @Rm+, MACL
    constant OpLDSL_At_Rm_Inc_To_PR  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100110";
    constant OpNOP                   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000001001";
    constant OpRTE                   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000101011";
    constant OpSETT                  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000011000";
    constant OpSLEEP                 : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000011011";
    constant OpSTC_SR_To_Rn          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00000010";
    constant OpSTC_GBR_To_Rn         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00010010";
    constant OpSTC_VBR_To_Rn         : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00100010";
    constant OpSTCL_SR_To_At_Dec_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00000011";
    constant OpSTCL_GBR_To_At_Dec_Rn : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00010011";
    constant OpSTCL_VBR_To_At_Dec_Rn : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100011";
    -- TODO: STS MACH, Rn
    -- TODO: STS MACL, Rn
    -- TODO: STS MACH, Rn
    constant OpSTS_PR_To_Rn          : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000----00101010";
    -- TODO: STSL MACH, @-Rn
    -- TODO: STSL MACL, @-Rn
    constant OpSTSL_PR_To_At_Dec_Rn  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0100----00100010";
    constant OpTRAPA                 : std_logic_vector(OPCODE_SIZE-1 downto 0) := "11000011--------";
    
    constant OpBoot                  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "0000000000000000";

end package;