library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.siphash_package.all;

entity siphash is
  generic (c : integer := 2);
  port (
    m : in std_logic_vector (BLOCK_WIDTH-1 downto 0);
    b : in std_logic_vector (BYTES_WIDTH-1 downto 0);

    rst_n  : in std_logic;
    clk    : in std_logic;
    init   : in std_logic;
    load_k : in std_logic;

    init_ready, hash_ready : buffer std_logic;
    hash                   : out    std_logic_vector(HASH_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of siphash is
  type state_t is (idle, compression, last_block, finalization);
  signal state : state_t;

  signal total_bytes : std_logic_vector(LENGTH_WIDTH-1 downto 0);

  signal v0, v1, v2, v3 : v_array(c downto 0);

  signal k : std_logic_vector(KEY_WIDTH-1 downto 0);

  signal block_counter : unsigned(COUNT_WIDTH-1 downto 0);
  signal current_count : unsigned(COUNT_WIDTH-1 downto 0);

  signal this_m, last_m : std_logic_vector(BLOCK_WIDTH-1 downto 0);
begin

  siprounds : for i in 0 to c-1 generate
    round : sipround
      port map (v0(i), v1(i), v2(i), v3(i),
                v0(i+1), v1(i+1), v2(i+1), v3(i+1));
  end generate;

  current_count <= (others => '0') when init = '1' else block_counter;

  total_bytes <= std_logic_vector(current_count) & b(BYTES_WIDTH-2 downto 0);

  this_m <= m when b(BYTES_WIDTH-1) = '1' else
            total_bytes & m(BLOCK_WIDTH-LENGTH_WIDTH-1 downto 0);

  process(rst_n, clk)
  begin

    if rst_n = '0' then
      k <= (others => '0');
    elsif rising_edge(clk) then
      if load_k = '1' then
        k(KEY_WIDTH-1 downto BLOCK_WIDTH) <= m;
        k(BLOCK_WIDTH-1 downto 0)         <= k(KEY_WIDTH-1 downto BLOCK_WIDTH);
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
      block_counter <= (others => '0');
      hash_ready    <= '0';
      init_ready    <= '0';
      hash          <= (others => '0');

    elsif rising_edge(clk) then

      last_m        <= this_m;
      block_counter <= current_count + 1;
      init_ready    <= '0';
      hash_ready    <= '0';

      v0(0) <= v0(c);
      v1(0) <= v1(c);
      v2(0) <= v2(c);
      v3(0) <= v3(c);

      case state is

        when idle =>

          init_ready <= '1';
          hash_ready <= hash_ready;

        when compression =>

          v0(0) <= v0(c) xor last_m;
          v3(0) <= v3(c) xor this_m;

        when last_block =>

          v0(0) <= v0(c) xor last_m;
          v2(0) <= v2(c) xor V2_FINAL;

        when finalization =>

          if init_ready = '1' then
            hash       <= v0(c) xor v1(c) xor v2(c) xor v3(c);
            hash_ready <= '1';
          end if;

          init_ready <= '1';

      end case;

      if init = '1' then
        v0(0)      <= V0_INIT xor k(BLOCK_WIDTH-1 downto 0);
        v1(0)      <= V1_INIT xor k(KEY_WIDTH-1 downto BLOCK_WIDTH);
        v2(0)      <= V2_INIT xor k(BLOCK_WIDTH-1 downto 0);
        v3(0)      <= V3_INIT xor k(KEY_WIDTH-1 downto BLOCK_WIDTH) xor this_m;
        init_ready <= '0';
      end if;

    end if;
  end process;

  process (rst_n, clk)
  begin
    if rst_n = '0' then
      state <= idle;
    elsif rising_edge(clk) then
      if init = '1' or state = compression then
        if b(BYTES_WIDTH-1) = '1' then
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

