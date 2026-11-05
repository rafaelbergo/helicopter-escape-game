
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_controller is
    generic (
        CLK_DIV : positive := 25
    );
    port (
        clk        : in  std_logic;
        reset    : in  std_logic;

        start      : in  std_logic;
        bit_count  : in  unsigned(6 downto 0);

        tx_data    : in  std_logic_vector(63 downto 0);
        rx_data    : out std_logic_vector(63 downto 0);

        busy       : out std_logic;
        done       : out std_logic;

        spi_cs_n   : out std_logic;
        spi_sclk   : out std_logic;
        spi_mosi   : out std_logic;
        spi_miso   : in  std_logic
    );
end spi_controller;

architecture Behavioral of spi_controller is

    type state_type is (IDLE, TRANSFER, FINISH);

    signal state : state_type := IDLE;

    signal tx_shift : std_logic_vector(63 downto 0)
        := (others => '0');

    signal rx_shift : std_logic_vector(63 downto 0)
        := (others => '0');

    signal rx_reg : std_logic_vector(63 downto 0)
        := (others => '0');

    signal bits_remaining : unsigned(6 downto 0)
        := (others => '0');

    signal div_counter : natural range 0 to CLK_DIV-1 := 0;

    signal cs_n_reg : std_logic := '1';
    signal sclk_reg : std_logic := '1';
    signal mosi_reg : std_logic := '0';

    signal busy_reg : std_logic := '0';
    signal done_reg : std_logic := '0';

begin

    process(clk, reset)

        variable rx_next : std_logic_vector(63 downto 0);

    begin

        if reset = '1' then

            state <= IDLE;

            tx_shift <= (others => '0');
            rx_shift <= (others => '0');
            rx_reg <= (others => '0');

            bits_remaining <= (others => '0');

            div_counter <= 0;

            cs_n_reg <= '1';
            sclk_reg <= '1';
            mosi_reg <= '0';

            busy_reg <= '0';
            done_reg <= '0';

        elsif rising_edge(clk) then

            done_reg <= '0';

            case state is

                when IDLE =>

                    cs_n_reg <= '1';
                    sclk_reg <= '1';
                    busy_reg <= '0';
                    div_counter <= 0;

                    if start = '1' then

                        if bit_count >= 1 and bit_count <= 64 then

                            tx_shift <= tx_data;
                            rx_shift <= (others => '0');

                            bits_remaining <= bit_count;

                            cs_n_reg <= '0';
                            busy_reg <= '1';

                            state <= TRANSFER;

                        end if;

                    end if;

                when TRANSFER =>

                    if div_counter = CLK_DIV-1 then

                        div_counter <= 0;

                        if sclk_reg = '1' then

                            -- Borda de descida:
                            -- Atualiza MOSI.

                            sclk_reg <= '0';
                            mosi_reg <= tx_shift(63);

                        else

                            -- Borda de subida:
                            -- Captura MISO.

                            sclk_reg <= '1';

                            rx_next :=
                                rx_shift(62 downto 0) & spi_miso;

                            rx_shift <= rx_next;

                            tx_shift <=
                                tx_shift(62 downto 0) & '0';

                            if bits_remaining = 1 then

                                rx_reg <= rx_next;

                                state <= FINISH;

                            else

                                bits_remaining <=
                                    bits_remaining - 1;

                            end if;

                        end if;

                    else

                        div_counter <= div_counter + 1;

                    end if;

                when FINISH =>

                    -- Mantem CS ativo por mais meio periodo.

                    if div_counter = CLK_DIV-1 then

                        div_counter <= 0;

                        cs_n_reg <= '1';
                        busy_reg <= '0';
                        done_reg <= '1';

                        state <= IDLE;

                    else

                        div_counter <= div_counter + 1;

                    end if;

            end case;

        end if;

    end process;

    rx_data <= rx_reg;

    busy <= busy_reg;
    done <= done_reg;

    spi_cs_n <= cs_n_reg;
    spi_sclk <= sclk_reg;
    spi_mosi <= mosi_reg;

end Behavioral;
