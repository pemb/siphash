library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.siphash_package.all;

entity sipround is
  port (
    v0_in, v1_in, v2_in, v3_in     : in  std_logic_vector(V_WIDTH-1 downto 0);
    v0_out, v1_out, v2_out, v3_out : out std_logic_vector(V_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of sipround is
begin
  process(v0_in, v1_in, v2_in, v3_in)
    variable v0, v1, v2, v3 : unsigned(V_WIDTH-1 downto 0);
  begin
    v0 := unsigned(v0_in);
    v1 := unsigned(v1_in);
    v2 := unsigned(v2_in);
    v3 := unsigned(v3_in);

    v0 := v0 + v1;
    v2 := v2 + v3;
    v1 := rotate_left(v1, 13);
    v3 := rotate_left(v3, 16);

    v1 := v1 xor v0;
    v3 := v3 xor v2;
    v0 := rotate_left(v0, 32);

    v0 := v0 + v3;
    v2 := v2 + v1;
    v1 := rotate_left(v1, 17);
    v3 := rotate_left(v3, 21);

    v1 := v1 xor v2;
    v3 := v3 xor v0;
    v2 := rotate_left(v2, 32);

    v0_out <= std_logic_vector(v0);
    v1_out <= std_logic_vector(v1);
    v2_out <= std_logic_vector(v2);
    v3_out <= std_logic_vector(v3);
  end process;
end;

