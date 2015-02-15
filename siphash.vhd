library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sipround_package.all;

entity siphash is
  port (
    m : in std_logic_vector (63 downto 0);
    b : in std_logic_vector (3 downto 0);

    rst_n  : in std_logic;
    clk    : in std_logic;
    init   : in std_logic;
    load_k : in std_logic;

    init_ready : buffer std_logic;
    hash_ready : out    std_logic;
    hash       : out    std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of siphash is
  constant c   : integer := 2;
  type state_t is (idle, compression, last_block, finalization);
  signal state : state_t;

  signal total_bytes : std_logic_vector(7 downto 0);

  type v_array is array (integer range <>) of std_logic_vector(63 downto 0);
  signal v0, v1, v2, v3 : v_array(c downto 0);
  signal k              : v_array(1 downto 0);

  signal block_counter : integer range 0 to 31;

  signal this_m, last_m : std_logic_vector(63 downto 0);
begin

  siprounds : for i in 0 to c-1 generate
    round : sipround
      port map (v0(i), v1(i), v2(i), v3(i),
                v0(i+1), v1(i+1), v2(i+1), v3(i+1));
  end generate;

  total_bytes(7 downto 3) <= (others => '0') when init = '1' else
                             std_logic_vector(to_unsigned(block_counter, 5));

  total_bytes(2 downto 0) <= b(2 downto 0);

  process(m, b, total_bytes)
  begin
    this_m               <= (others => '0');
    this_m(63 downto 56) <= total_bytes;
    this_m(8*to_integer(unsigned(b))-1 downto 0)
      <= m(8*to_integer(unsigned(b))-1 downto 0);
  end process;

  process(rst_n, clk)
  begin

    if rst_n = '0' then
      k <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if load_k = '1' then
        k(1) <= m;
        k(0) <= k(1);
      end if;
    end if;
  end process;

  process (rst_n, clk, init)
  begin

    if rst_n = '0' then

      v0(0)         <= (others => '0');
      v1(0)         <= (others => '0');
      v2(0)         <= (others => '0');
      v3(0)         <= (others => '0');
      last_m        <= (others => '0');
      block_counter <= 0;
      hash_ready    <= '0';
      init_ready    <= '0';
      hash          <= (others => '0');

    elsif rising_edge(clk) then

      last_m        <= this_m;
      block_counter <= 0;
      init_ready    <= '0';

      v0(0) <= v0(c);
      v1(0) <= v1(c);
      v2(0) <= v2(c);
      v3(0) <= v3(c);

      case state is

        when idle =>

          init_ready <= '1';

        when compression =>

          v0(0)         <= v0(c) xor last_m;
          v3(0)         <= v3(c) xor this_m;
          block_counter <= block_counter + 1;
          hash_ready    <= '0';

        when last_block =>

          v0(0)      <= v0(c) xor last_m;
          v2(0)      <= v2(c) xor x"ff";
          hash_ready <= '0';

        when finalization =>

          if init_ready = '1' then
            hash       <= v0(c) xor v1(c) xor v2(c) xor v3(c);
            hash_ready <= '1';
          end if;

          init_ready <= '1';

      end case;

      if init = '1' then
        v0(0)         <= k(0) xor x"736f6d6570736575";
        v1(0)         <= k(1) xor x"646f72616e646f6d";
        v2(0)         <= k(0) xor x"6c7967656e657261";
        v3(0)         <= k(1) xor x"7465646279746573" xor this_m;
        block_counter <= 1;
        init_ready    <= '0';
      end if;

    end if;
  end process;

  process (rst_n, clk)
  begin
    if rst_n = '0' then
      state <= idle;
    elsif rising_edge(clk) then
      if init = '1' or state = compression then
        if b(3) = '1' then
          state <= compression;
        else
          state <= last_block;
        end if;
      elsif state = last_block then
        state <= finalization;
      elsif state = finalization and init_ready = '1' then
        state <= idle;
      end if;
    end if;
  end process;

end rtl;

