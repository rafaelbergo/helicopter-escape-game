
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity y_axis_display is
    port (
        clk       : in  std_logic;
        reset_n   : in  std_logic;
        y_data    : in  signed(15 downto 0);

        digit0    : out std_logic_vector(3 downto 0);
        digit1    : out std_logic_vector(3 downto 0);
        digit2    : out std_logic_vector(3 downto 0);
        digit3    : out std_logic_vector(3 downto 0);
        digit4    : out std_logic_vector(3 downto 0);
        negative  : out std_logic
    );
end entity;

architecture rtl of y_axis_display is

    constant UPDATE_PERIOD : integer := 12_500_000;

    signal timer : integer range 0 to UPDATE_PERIOD - 1 := 0;

    signal digit0_reg : std_logic_vector(3 downto 0) := "0000";
    signal digit1_reg : std_logic_vector(3 downto 0) := "0000";
    signal digit2_reg : std_logic_vector(3 downto 0) := "0000";
    signal digit3_reg : std_logic_vector(3 downto 0) := "0000";
    signal digit4_reg : std_logic_vector(3 downto 0) := "0000";

    signal negative_reg : std_logic := '0';

    -- Converte um valor binario de 16 bits para 5 digitos BCD.
    function bin_to_bcd(
        bin : unsigned(15 downto 0)
    ) return std_logic_vector is

        variable bcd : unsigned(19 downto 0) := (others => '0');

    begin
        for i in 15 downto 0 loop

            for j in 0 to 4 loop
                if bcd(j * 4 + 3 downto j * 4) > 4 then
                    bcd(j * 4 + 3 downto j * 4) :=
                        bcd(j * 4 + 3 downto j * 4) + 3;
                end if;
            end loop;

            bcd := bcd(18 downto 0) & bin(i);

        end loop;

        return std_logic_vector(bcd);
    end function;

begin

    process(clk, reset_n)

        variable magnitude : unsigned(15 downto 0);
        variable bcd_value : std_logic_vector(19 downto 0);

    begin
        if reset_n = '0' then

            timer <= 0;

            digit0_reg <= "0000";
            digit1_reg <= "0000";
            digit2_reg <= "0000";
            digit3_reg <= "0000";
            digit4_reg <= "0000";

            negative_reg <= '0';

        elsif rising_edge(clk) then

            if timer = UPDATE_PERIOD - 1 then

                timer <= 0;

                -- Calcula o modulo sem overflow, inclusive para -32768.
                if y_data(15) = '1' then
                    magnitude := unsigned(not std_logic_vector(y_data)) + 1;
                    negative_reg <= '1';
                else
                    magnitude := unsigned(y_data);
                    negative_reg <= '0';
                end if;

                bcd_value := bin_to_bcd(magnitude);

                digit0_reg <= bcd_value(3 downto 0);
                digit1_reg <= bcd_value(7 downto 4);
                digit2_reg <= bcd_value(11 downto 8);
                digit3_reg <= bcd_value(15 downto 12);
                digit4_reg <= bcd_value(19 downto 16);

            else
                timer <= timer + 1;
            end if;

        end if;
    end process;

    digit0   <= digit0_reg;
    digit1   <= digit1_reg;
    digit2   <= digit2_reg;
    digit3   <= digit3_reg;
    digit4   <= digit4_reg;
    negative <= negative_reg;

end architecture;
