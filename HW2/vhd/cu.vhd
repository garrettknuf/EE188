----------------------------------------------------------------------------
--
--  SH-2 Control Unit
--
--  This is an implementation of 
--
--  Entities included are:
--    
--
--  Revision History:
--     18 April 2025    Garrett Knuf    Initial revision.
--
----------------------------------------------------------------------------

--
-- Package containing constants for the control unit.
--

library ieee;
use ieee.std_logic_1164.all;

package CUConstants is

end package;


--
--
--
--
library ieee;
use ieee.std_logic_1164.all;
use work.CUConstants.all;
use work.ALUConstants.all
use work.TbitConstants.all
use work.DAUConstants.all;
use work.PAUConstants.all;
use work.RegArrayConstants.all;
use work.StatusRegConstants.all

entity CU is

    port (
        -- CU Input Signals
        CLK     : in    std_logic;
        DB      : in    std_logic_vector(DATA_BUS_SIZE - 1 downto 0);
        SR      : in    std_logic_vector(REG_SIZE - 1 downto 0);

        -- ALU Control Signals
        ALUOpA   : out     std_logic_vector(LONG_SIZE - 1 downto 0);
        ALUOpB   : out     std_logic_vector(LONG_SIZE - 1 downto 0);
        Cin      : out     std_logic;                               
        FCmd     : out     std_logic_vector(3 downto 0);            
        CinCmd   : out     std_logic_vector(1 downto 0);            
        SCmd     : out     std_logic_vector(2 downto 0);            
        ALUCmd   : out     std_logic_vector(1 downto 0);            
        TbitOp   : out     integer range Tbit_Src_Cnt - 1 downto 0; 

        -- RegArray Control Signals
        RegInSel   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegStore   : out   std_logic;
        RegASel    : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegBSel    : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxInSel : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegAxStore : out   std_logic;
        RegA1Sel   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        RegA2Sel   : out   integer  range REGARRAY_RegCnt - 1 downto 0;
        
        -- DAU Control Signals
        DAU_SrcSel      : out   integer range DAU_SRC_CNT - 1 downto 0;
        DAU_OffsetSel   : out   integer range DAU_OFFSET_CNT - 1 downto 0;
        DAU_IncDecSel   : out   std_logic;
        DAU_IncDecBit   : out   integer range 2 downto 0;
        DAU_PrePostSel  : out   std_logic;
        DAU_LoadGBR     : out   std_logic;

        -- PAU Control Signals
        PAU_SrcSel      : out   integer range PAU_SRC_CNT - 1 downto 0;
        PAU_OffsetSel   : out   integer range PAU_OFFSET_CNT - 1 downto 0;
        PAU_UpdatePC    : out   std_logic;
        PAU_UpdatePR    : out   std_logic;

        -- StatusReg Control Signals
        Tbit        : out   std_logic;
        UpdateTbit  : out   std_logic;
    );

end CU;

architecture behavioral of CU is


begin


end behavioral;
