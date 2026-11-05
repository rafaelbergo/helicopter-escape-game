library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accelerometer_controller is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
		  
        spi_cs_n     : out std_logic;
        spi_sclk     : out std_logic;
        spi_mosi     : out std_logic;
        spi_miso     : in  std_logic;

        devid        : out std_logic_vector(7 downto 0);
        sensor_ready : out std_logic;
        data_valid   : out std_logic;

        x_data       : out signed(15 downto 0);
        y_data       : out signed(15 downto 0);
        z_data       : out signed(15 downto 0)
    );
end accelerometer_controller;

architecture Behavioral of accelerometer_controller is

    type state_type is (
        INIT_FORMAT_START,
        INIT_FORMAT_WAIT,

        INIT_RATE_START,
        INIT_RATE_WAIT,

        INIT_POWER_START,
        INIT_POWER_WAIT,

        READ_DEVID_START,
        READ_DEVID_WAIT,
        CHECK_DEVID,

        READ_XYZ_START,
        READ_XYZ_WAIT,

        SAMPLE_WAIT
    );

    signal state : state_type := INIT_FORMAT_START;
    
	 signal spi_start : std_logic := '0';
    signal spi_bit_count : unsigned(6 downto 0) := (others => '0');
    signal spi_tx_data : std_logic_vector(63 downto 0) := (others => '0');
    signal spi_rx_data : std_logic_vector(63 downto 0);
    signal spi_busy : std_logic;
    signal spi_done : std_logic;

    signal devid_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal ready_reg : std_logic := '0';
    signal valid_reg : std_logic := '0';
	 
    signal x_reg : signed(15 downto 0) := (others => '0');
    signal y_reg : signed(15 downto 0) := (others => '0');
    signal z_reg : signed(15 downto 0) := (others => '0');

    signal sample_counter : natural range 0 to 499999 := 0;
	 
begin

    SPI_INST : entity work.spi_controller
        generic map (
            CLK_DIV => 25
        )
        port map (
            clk       => clk,
            reset   => reset,

            start     => spi_start,
            bit_count => spi_bit_count,

            tx_data   => spi_tx_data,
            rx_data   => spi_rx_data,

            busy      => spi_busy,
            done      => spi_done,

            spi_cs_n  => spi_cs_n,
            spi_sclk  => spi_sclk,
            spi_mosi  => spi_mosi,
            spi_miso  => spi_miso
        );


    process(clk, reset)

    begin

        if reset = '1' then
		  
            state <= INIT_FORMAT_START;

            spi_start <= '0';
            spi_bit_count <= (others => '0');
            spi_tx_data <= (others => '0');

            devid_reg <= (others => '0');

            x_reg <= (others => '0');
            y_reg <= (others => '0');
            z_reg <= (others => '0');

            ready_reg <= '0';
            valid_reg <= '0';

            sample_counter <= 0;

        elsif rising_edge(clk) then
            spi_start <= '0';
            valid_reg <= '0';

            case state is

                -- DATA_FORMAT = 0x08
                when INIT_FORMAT_START =>

                    if spi_busy = '0' then

                        spi_tx_data <= x"3108000000000000";
                        spi_bit_count <= to_unsigned(16, 7);
                        spi_start <= '1';
                        state <= INIT_FORMAT_WAIT;

                    end if;


                when INIT_FORMAT_WAIT =>

                    if spi_done = '1' then
                        state <= INIT_RATE_START;
                    end if;

                -- BW_RATE = 0x09 (50 Hz)
                when INIT_RATE_START =>

                    if spi_busy = '0' then

                        spi_tx_data <= x"2C09000000000000";
                        spi_bit_count <= to_unsigned(16, 7);
                        spi_start <= '1';
                        state <= INIT_RATE_WAIT;

                    end if;


                when INIT_RATE_WAIT =>

                    if spi_done = '1' then
                        state <= INIT_POWER_START;
                    end if;


                -- POWER_CTL = 0x08
                when INIT_POWER_START =>

                    if spi_busy = '0' then

                        spi_tx_data <= x"2D08000000000000";
                        spi_bit_count <= to_unsigned(16, 7);
                        spi_start <= '1';
                        state <= INIT_POWER_WAIT;

                    end if;

                when INIT_POWER_WAIT =>

                    if spi_done = '1' then
                        state <= READ_DEVID_START;
                    end if;

					 -- Leitura ADXL345
                when READ_DEVID_START =>

                    if spi_busy = '0' then

                        spi_tx_data <= x"8000000000000000";
                        spi_bit_count <= to_unsigned(16, 7);
                        spi_start <= '1';
                        state <= READ_DEVID_WAIT;

                    end if;


                when READ_DEVID_WAIT =>

                    if spi_done = '1' then

                        devid_reg <= spi_rx_data(7 downto 0);
                        state <= CHECK_DEVID;

                    end if;


                when CHECK_DEVID =>

                    if devid_reg = x"E5" then
						  
                        ready_reg <= '1';
                        state <= READ_XYZ_START;

                    else

                        ready_reg <= '0';
                        state <= READ_DEVID_START;

                    end if;


					 -- Leitura dos eixos X,Y e Z
                when READ_XYZ_START =>

                    if spi_busy = '0' then

                        -- READ + MULTI-BYTE + endereco 0x32
                        spi_tx_data <= x"F200000000000000";
                        spi_bit_count <= to_unsigned(56, 7);
                        spi_start <= '1';
                        state <= READ_XYZ_WAIT;

                    end if;


                when READ_XYZ_WAIT =>

                    if spi_done = '1' then

                        -- X_L, X_H, Y_L, Y_H, Z_L, Z_H	
                        x_reg <= signed(
                            spi_rx_data(39 downto 32) &
                            spi_rx_data(47 downto 40)
                        );
                        y_reg <= signed(
                            spi_rx_data(23 downto 16) &
                            spi_rx_data(31 downto 24)
                        );
                        z_reg <= signed(
                            spi_rx_data(7 downto 0) &
                            spi_rx_data(15 downto 8)
                        );

                        valid_reg <= '1';
                        sample_counter <= 0;
                        state <= SAMPLE_WAIT;

                    end if;

                when SAMPLE_WAIT =>

                    if sample_counter = 499999 then
                        sample_counter <= 0;
                        state <= READ_XYZ_START;

                    else

                        sample_counter <= sample_counter + 1;

                    end if;


            end case;

        end if;

    end process;

    devid <= devid_reg;
    sensor_ready <= ready_reg;
    data_valid <= valid_reg;

    x_data <= x_reg;
    y_data <= y_reg;
    z_data <= z_reg;

end Behavioral;
