library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity SPI_MASTER is
    generic (
        G_DATA_WIDTH : integer := 16; -- number of data bits per SPI transaction
    );
    port (
        I_CLK   : in  std_logic;
        I_RESET : in  std_logic;

        I_MISO : in  std_logic; -- data input from slave
        O_MOSI : in  std_logic; -- data output to slave
        O_SCLK : out std_logic; -- serial clock to slave (1/2 clock frequency of input clock)
        O_CSn  : out std_logic; -- active-low chip select signal

        I_DATA : in  std_logic_vector(G_DATA_WIDTH-1 downto 0); -- data to be transmitted to the slave
        O_DATA : out std_logic_vector(G_DATA_WIDTH-1 downto 0); -- data received from the slave, valid when O_DONE is high
        I_START : in  std_logic; -- signal to start transmission
        O_DONE  : out std_logic  -- signal that indicates when the state machine has finished receiving
    );
end entity SPI_MASTER;

architecture RTL of SPI_MASTER is

    ----------------------------------------------------------------------------
    -- Type Definitions
    ----------------------------------------------------------------------------
    type t_state is (S_IDLE, S_SETUP, S_HOLD);

    ----------------------------------------------------------------------------
    -- Signal Declarations
    ----------------------------------------------------------------------------
    signal q_state,   n_state   : t_state;
    signal q_tx_data, n_tx_data : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal q_rx_data, n_rx_data : std_logic_vector(G_DATA_WIDTH-1 downto 0);
    signal q_start,   n_start   : std_logic;
    signal q_done,    n_done    : std_logic;
    signal q_bit_cnt, n_bit_cnt : unsigned(7 downto 0); -- this is probably better as a generic, but never going to exceed 255 bits

    signal w_sclk : std_logic;
    signal w_mosi : std_logic;
    signal w_csn  : std_logic;

begin

    ----------------------------------------------------------------------------
    -- Output Signal Assignments
    ----------------------------------------------------------------------------
    O_MOSI <= w_mosi;
    O_SCLK <= w_sclk;
    O_CSn  <= w_csn;

    O_DATA <= q_rx_data;
    O_DONE <= q_done;

    ----------------------------------------------------------------------------
    -- Concurrent Signal Assignments
    ----------------------------------------------------------------------------
    n_start <= I_START;

    n_tx_data <= I_DATA when I_START = '1' and q_start = '0' else -- save transmit data on rising edge of start signal
                 q_tx_data;

    ----------------------------------------------------------------------------
    -- Asynchronous Processes
    ----------------------------------------------------------------------------
    SM_PROC : process(q_state, q_tx_data, q_rx_data, q_start, q_done, q_bit_cnt, I_MISO, I_START)
    begin

        n_state   <= q_state;
        n_rx_data <= q_rx_data;
        n_bit_cnt <= q_bit_cnt;
        n_done    <= q_done;

        w_mosi <= '0';
        w_sclk <= '0';
        w_csn  <= '1';

        case (q_state) is

            when S_IDLE =>
                if q_start = '0' and I_START = '1' then
                    n_done <= '0';

                    n_state <= S_SETUP;
                end if;

            when S_SETUP =>
                w_csn  <= '0';
                w_mosi <= q_tx_data(to_integer(q_bit_cnt));
                w_sclk <= '0';

                n_state <= S_HOLD;

            when S_HOLD =>
                w_csn  <= '0';
                w_mosi <= q_tx_data(to_integer(q_bit_cnt));
                w_sclk <= '1';

                n_rx_data(to_integer(q_bit_cnt)) <= I_MISO;

                if q_bit_cnt = G_DATA_WIDTH - 1 then
                    n_bit_cnt <= '0';
                    n_done    <= '1';

                    n_state   <= S_IDLE;
                else
                    n_bit_cnt <= q_bit_cnt + 1;
                end if;

            when others =>
                n_state <= S_IDLE;

        end case;

    end process SM_PROC;

    ----------------------------------------------------------------------------
    -- Synchronous Processes
    ----------------------------------------------------------------------------
    SYNC_PROC : process(I_CLK, I_RESET)
    begin

        if I_RESET = '1' then
            q_state   <= S_IDLE;
            q_rx_data <= (others => '0');
            q_tx_data <= (others => '0');
            q_start   <= '0';
            q_done    <= '0';
            q_bit_cnt <= (others => '0');
        elsif rising_edge(I_CLK) then
            q_state   <= n_state;
            q_rx_data <= n_rx_data;
            q_tx_data <= n_tx_data;
            q_start   <= n_start;
            q_done    <= n_done;
            q_bit_cnt <= n_bit_cnt;
        end if;

    end process SYNC_PROC;

end architecture RTL;