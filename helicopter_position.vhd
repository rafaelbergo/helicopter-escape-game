
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity helicopter_position is
    port (
        clk         : in  std_logic;
        reset     : in  std_logic;

        sample_valid : in std_logic;

        move_up     : in  std_logic;
        move_down   : in  std_logic;

        position_y  : out unsigned(8 downto 0)
    );
end entity;

architecture rtl of helicopter_position is

    constant INITIAL_POSITION : unsigned(8 downto 0) :=
        to_unsigned(240, 9);

    constant MIN_POSITION : unsigned(8 downto 0) :=
        to_unsigned(0, 9);

    constant MAX_POSITION : unsigned(8 downto 0) :=
        to_unsigned(479, 9);

    signal position_reg : unsigned(8 downto 0) :=
        INITIAL_POSITION;

    signal sample_valid_d : std_logic := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then

            position_reg <= INITIAL_POSITION;
            sample_valid_d <= '0';

        elsif rising_edge(clk) then

            -- Atrasa o pulso para sincronizar com o controle.
            sample_valid_d <= sample_valid;

            if sample_valid_d = '1' then

                -- Subir: coordenada Y diminui.
                if move_up = '1' and move_down = '0' then

                    if position_reg > MIN_POSITION then
                        position_reg <= position_reg - 1;
                    end if;

                -- Descer: coordenada Y aumenta.
                elsif move_down = '1' and move_up = '0' then

                    if position_reg < MAX_POSITION then
                        position_reg <= position_reg + 1;
                    end if;

                end if;

            end if;

        end if;
    end process;

    position_y <= position_reg;

end architecture;
