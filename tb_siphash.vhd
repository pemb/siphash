library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.siphash_package.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity tb_siphash is
end entity;

architecture testbench of tb_siphash is

  signal m : std_logic_vector(BLOCK_WIDTH-1 downto 0) := (others => '0');
  signal b : std_logic_vector(BYTES_WIDTH-1 downto 0) := (others => '0');

  signal rst_n: std_logic := '0';
  signal clk : std_logic := '0';
  signal init : std_logic := '0';
  signal load_k :  std_logic := '0';

  signal init_ready, hash_ready : std_logic;
  signal hash : std_logic_vector(HASH_WIDTH-1 downto 0);
  signal counter : integer := 0;
  signal test_finished : boolean := false;

  signal key_m : std_logic_vector(BLOCK_WIDTH-1 downto 0);
  signal blk_m : std_logic_vector(BLOCK_WIDTH-1 downto 0);

begin

  m <= key_m when load_k = '1' else blk_m;

  hash_core: siphash
    port map(m, b, rst_n, clk, init, load_k, init_ready, hash_ready, hash);

  reset: process
  begin
    wait for 1 ns;
    rst_n <= '1';
    wait;
  end process;

  clock: process
  begin
    wait for 2 ns;
    clk <= not clk;
    if clk = '0' and test_finished then
      wait;
    end if;
  end process;

  -- uncomment this process to get clock by clock debug info

  --print: process (clk)
  --  variable s: line;
  --begin
  --  if rising_edge(clk) then
  --    counter <= counter + 1;
  --    write (s, String'(lf & "clock edge "));
  --    write (s, counter);
  --    write (s, String'(lf & "m: "));
  --    hwrite (s, m);
  --    write (s, String'(lf & "b: "));
  --    hwrite (s, b);
  --    write (s, String'(lf & "rst_n: "));
  --    write (s, rst_n);
  --    write (s, String'(lf & "init: "));
  --    write (s, init);
  --    write (s, String'(lf & "load_k: "));
  --    write (s, load_k);
  --    write (s, String'(lf & "init_ready: "));
  --    write (s, init_ready);
  --    write (s, String'(lf & "hash_ready: "));
  --    write (s, hash_ready);
  --    write (s, String'(lf & "hash: "));
  --    hwrite (s, hash);
  --    writeline (output, s);
  --  end if;
  --end process;

  key: process
  begin
    wait until rst_n = '1';
    load_k <= '1';
    key_m <= x"0706050403020100";
    wait until clk = '1';
    key_m <= x"0f0e0d0c0b0a0908";
    wait until clk = '1';
    load_k <= '0';
    wait;
  end process;

  data: process
    variable bytes: integer;
    variable l : line;
    variable real_hash : std_logic_vector(HASH_WIDTH-1 downto 0);
    variable success : boolean := true;
  begin
    wait until load_k = '0';
    for i in 0 to 63 loop
      init <= '1';
      for blocks in 0 to i/8 loop
        if (blocks+1) * 8 < i then
          bytes := 8;
        else
          bytes := i-(blocks*8);
        end if;
        b <= std_logic_vector(to_unsigned(bytes,BYTES_WIDTH));
        blk_m <= (others => '0');
        for count in 0 to bytes-1 loop
          blk_m(count*8+7 downto count*8) <=
            std_logic_vector(to_unsigned(count+blocks*8,8));
        end loop;
        wait until clk = '1';
        init <= '0';
      end loop;
      b <= "0000";
      wait until hash_ready = '1';
      readline(input, l);
      hread(l, real_hash);
      assert hash = real_hash report
        "test vector failed for " & integer'image(i) & " bytes"
        severity error;
      success := hash = real_hash and success;
    end loop;
    test_finished <= true;
    if success then
      write (l, String'("test vector ok"));
      writeline(output, l);
    end if;
    wait;
  end process;

end testbench;

