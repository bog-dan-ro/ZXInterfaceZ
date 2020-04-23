library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
-- synthesis translate_off
library work;
use work.txt_util.all;
-- synthesis translate_on

entity videogen_fifo is
  port (
    clk_i         : in std_logic;
    rst_i         : in std_logic;

    -- Video access
    vaddr_o       : out std_logic_vector(12 downto 0);
    ven_o         : out std_logic;
    vbusy_i       : in std_logic;
    vdata_i       : in std_logic_vector(7 downto 0); -- Bitmap data
--    vborder_i     : in std_logic_vector(2 downto 0);

    -- Fifo
    sync_i        : in std_logic;
    rd_i          : in std_logic;
    rclk_i        : in std_logic;
    pixel_o       : out std_logic_vector(7 downto 0);
    attr_o        : out std_logic_vector(7 downto 0)

  );
end entity videogen_fifo;

architecture beh of videogen_fifo is

  type state_type is (
    IDLE,
    FETCH_DATA,
    LATCH_DATA,
    FETCH_ATTR,
    LATCH_ATTR
  );

  constant PIXEL_BYTES: natural := 6144;

  function tovideoaddress(index: in unsigned(12 downto 0)) return std_logic_vector is
    variable v: unsigned(12 downto 0);
  begin
    v(4 downto 0) := index(4 downto 0);
    v(5) := index(8);
    v(6) := index(9);
    v(7) := index(10);
    v(8) := index(5);
    v(9) := index(6);
    v(10) := index(7);
    v(11) := index(11);
    v(12) := index(12);
    return std_logic_vector(v);
  end function;

  -- 0x5800 - 0x5C00
      -- from 010_1 1000 0000 0000
      -- to   010_1 1010 1111 1111

  function toattributeaddress(index: in unsigned(12 downto 0)) return std_logic_vector is
    variable v: unsigned(12 downto 0);
  begin
    v(4 downto 0)  := index(4 downto 0);
    v(9 downto 5) := index(12 downto 8);
    v(10) := '0';
    v(11) := '1';
    v(12) := '1';
    return std_logic_vector(v);
  end function;

  type regs_type is record
    counter : unsigned(12 downto 0); -- Counts from 1 to 6144
    state   : state_type;
    pixel   : std_logic_vector(7 downto 0);
  end record regs_type;

  signal sync_in_mainclk_s: std_logic;

  signal fifo_read_s  : std_logic_vector(15 downto 0);
  signal fifo_write_s : std_logic_vector(15 downto 0);
  signal fifo_full_s  : std_logic;
  signal fifo_rd_s    : std_logic;
  signal fifo_wr_s    : std_logic;

  signal r            : regs_type;

begin

  s_sync: entity work.sync generic map (RESET => '0')
      port map ( clk_i => clk_i, arst_i => rst_i, din_i => sync_i, dout_o => sync_in_mainclk_s );

  fifo_write_s  <= vdata_i & r.pixel;
  pixel_o       <= fifo_read_s(7 downto 0);
  attr_o        <= fifo_read_s(15 downto 8);
  fifo_rd_s     <= rd_i;

  vf_inst: entity work.gh_fifo_async_sr_wf
  generic map (
    add_width   => 2, -- 4 entries
    data_width   => 16
  )
  port map (
    clk_WR      => clk_i,
    clk_RD      => rclk_i,
    rst         => rst_i,
    srst        => sync_in_mainclk_s,
    wr          => fifo_wr_s,
    rd          => fifo_rd_s,
    D           => fifo_write_s,
    Q           => fifo_read_s,
    full        => fifo_full_s
  );



  process(r, vbusy_i, fifo_full_s, vdata_i, clk_i, rst_i)
    variable w: regs_type;
  begin
    w := r;

    fifo_wr_s <= '0';

    case r.state is
      when FETCH_DATA =>
        vaddr_o <= tovideoaddress(r.counter);  -- 0x4000
        ven_o   <= not fifo_full_s;
        if fifo_full_s='0' and vbusy_i='0' then
          w.state := LATCH_DATA;
        end if;
      when LATCH_DATA =>
        vaddr_o <= (others => '0');
        ven_o   <= '0';
        w.pixel := vdata_i;
        w.state := FETCH_ATTR;

      when FETCH_ATTR =>
        vaddr_o <= toattributeaddress(r.counter); -- 0x5800 - 0x5C00    -- 1 1000 00_00 0000 to 1 1100 0000 0000
        ven_o   <= not fifo_full_s;
        if fifo_full_s='0' and vbusy_i='0' then
          w.state := LATCH_ATTR;
        end if;

      when LATCH_ATTR =>
        vaddr_o <= (others => '0');
        ven_o   <= '0';
        fifo_wr_s   <= '1';
        if r.counter /= PIXEL_BYTES-1 then
          w.counter := r.counter + 1;
          w.state := FETCH_DATA;
        else
          w.state := IDLE;
        end if;

      when IDLE =>
        vaddr_o <= (others => '0');
        ven_o   <= '0';
        null;

      when others =>
    end case;

    if sync_in_mainclk_s='1' or rst_i='1' then
      w.state   := FETCH_DATA;
      w.counter := (others => '0');
      ven_o     <= '0';
    end if;

    if rising_edge(clk_i) then
      r<=w;
    end if;

  end process;


end beh;