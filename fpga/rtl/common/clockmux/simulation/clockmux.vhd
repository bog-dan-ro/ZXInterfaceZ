-- clockmux.vhd

-- Generated using ACDS version 19.1 670

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clockmux is
	port (
		inclk1x   : in  std_logic := '0'; --  altclkctrl_input.inclk1x
		inclk0x   : in  std_logic := '0'; --                  .inclk0x
		clkselect : in  std_logic := '0'; --                  .clkselect
		outclk    : out std_logic         -- altclkctrl_output.outclk
	);
end entity clockmux;

architecture rtl of clockmux is
	component clockmux_altclkctrl_0 is
		port (
			inclk1x   : in  std_logic := 'X'; -- inclk1x
			inclk0x   : in  std_logic := 'X'; -- inclk0x
			clkselect : in  std_logic := 'X'; -- clkselect
			outclk    : out std_logic         -- outclk
		);
	end component clockmux_altclkctrl_0;

begin

	altclkctrl_0 : component clockmux_altclkctrl_0
		port map (
			inclk1x   => inclk1x,   --  altclkctrl_input.inclk1x
			inclk0x   => inclk0x,   --                  .inclk0x
			clkselect => clkselect, --                  .clkselect
			outclk    => outclk     -- altclkctrl_output.outclk
		);

end architecture rtl; -- of clockmux