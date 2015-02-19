library ieee;
use ieee.std_logic_1164.all;

package siphash_package is

  constant BYTES_WIDTH : integer := 4;
  constant BLOCK_WIDTH : integer := 2**(BYTES_WIDTH-1)*8;

  constant V_WIDTH     : integer := BLOCK_WIDTH;
  constant HASH_WIDTH  : integer := BLOCK_WIDTH;
  constant KEY_WIDTH   : integer := 2*BLOCK_WIDTH;
  constant COUNT_WIDTH : integer := 8-(BYTES_WIDTH-1);

  constant LENGTH_WIDTH : integer := COUNT_WIDTH + BYTES_WIDTH - 1;

  constant V0_INIT : std_logic_vector := x"736f6d6570736575";
  constant V1_INIT : std_logic_vector := x"646f72616e646f6d";
  constant V2_INIT : std_logic_vector := x"6c7967656e657261";
  constant V3_INIT : std_logic_vector := x"7465646279746573";

  constant V2_FINAL : std_logic_vector := x"00000000000000ff";

  type v_array is array (integer range <>) of std_logic_vector(V_WIDTH-1 downto 0);

  component sipround is
    port (
      v0_in, v1_in, v2_in, v3_in     : in  std_logic_vector(V_WIDTH-1 downto 0);
      v0_out, v1_out, v2_out, v3_out : out std_logic_vector(V_WIDTH-1 downto 0)
      );
  end component;

  component siphash is
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
  end component;

end package;
