
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity position_display is
    port (
        position_y : in  unsigned(8 downto 0);

        digit0 : out std_logic_vector(3 downto 0);
        digit1 : out std_logic_vector(3 downto 0);
        digit2 : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of position_display is

begin

    process(position_y)

        variable bcd : unsigned(11 downto 0);

    begin

        bcd := (others => '0');

        -- Conversao binario para BCD.
        for i in 8 downto 0 loop

            -- Ajuste dos tres digitos.
            for j in 0 to 2 loop

                if bcd(j * 4 + 3 downto j * 4) > 4 then

                    bcd(j * 4 + 3 downto j * 4) :=
                        bcd(j * 4 + 3 downto j * 4) + 3;

                end if;

            end loop;

            -- Deslocamento e insercao do proximo bit.
            bcd := bcd(10 downto 0) & position_y(i);

        end loop;

        digit0 <= std_logic_vector(bcd(3 downto 0));
        digit1 <= std_logic_vector(bcd(7 downto 4));
        digit2 <= std_logic_vector(bcd(11 downto 8));

    end process;

end architecture;
