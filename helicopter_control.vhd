
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity helicopter_control is
    port (
        clk      : in  std_logic;
        reset  : in  std_logic;
        y_data   : in  signed(15 downto 0);

        move_up   : out std_logic;
        move_idle : out std_logic;
        move_down : out std_logic
    );
end entity;

architecture rtl of helicopter_control is

    constant DEAD_ZONE : signed(15 downto 0) := to_signed(45, 16);

    signal move_up_reg   : std_logic := '0';
    signal move_idle_reg : std_logic := '1';
    signal move_down_reg : std_logic := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then

            move_up_reg   <= '0';
            move_idle_reg <= '1';
            move_down_reg <= '0';

        elsif rising_edge(clk) then

            if y_data > DEAD_ZONE then

                move_up_reg   <= '1';
                move_idle_reg <= '0';
                move_down_reg <= '0';

            elsif y_data < -DEAD_ZONE then

                move_up_reg   <= '0';
                move_idle_reg <= '0';
                move_down_reg <= '1';

            else

                move_up_reg   <= '0';
                move_idle_reg <= '1';
                move_down_reg <= '0';

            end if;

        end if;
    end process;

    move_up   <= move_up_reg;
    move_idle <= move_idle_reg;
    move_down <= move_down_reg;

end architecture;
