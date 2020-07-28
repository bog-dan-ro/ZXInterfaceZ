LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY work;
use work.ahbpkg.all;
-- synthesis translate_off
use work.txt_util.all;
-- synthesis translate_on
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
entity psram is
  port (
    clk_i   : in std_logic;
    arst_i  : in std_logic;

    ahb_i   : in AHB_M2S;
    ahb_o   : out AHB_S2M;

    hp_ahb_i   : in AHB_M2S;
    hp_ahb_o   : out AHB_S2M;

    cs_n_o  : out std_logic := '1';
    clk_o   : out std_logic;
    d_i     : in std_logic_vector(3 downto 0);
    d_o     : out std_logic_vector(3 downto 0);
    oe_o    : out std_logic_vector(3 downto 0)
  );
end entity psram;

architecture beh of psram is

  type state_type is (
    STARTUP,
    INIT1,
    INIT2,
    INIT3,
    INIT4,
    INIT5,
    IDLE,
    CHIPSELECT,
    ADDRESS1,
    ADDRESS2,
    ADDRESS3,
    ADDRESS4,
    ADDRESS5,
    ADDRESS6,
    ADDRESS7,
    RDDLY,
    RDDATA1,
    RDDATA2,
    RDDATA3,
    WRDATA1,
    WRDATA2,
    WRDATA3,
    DESELECT,
    DESELECT_WAIT1,
    DESELECT_WAIT2,
    ABORT_SWITCH_TO_HP,
    ABORT_SWITCH_TO_HP2
  );

  signal clock_enable_s : std_logic;
  signal clock_enable_r : std_logic;
  signal bus_oe_s       : std_logic_vector(3 downto 0);
  signal data_out_r     : std_logic_vector(3 downto 0);
  signal d_neg_r        : std_logic_vector(3 downto 0);
  signal csn_r          : std_logic := '1';
  signal clkgen_s       : std_logic_vector(0 downto 0);
  signal state_r        : state_type;
  signal init_cnt_r     : unsigned(2 downto 0);
  signal std_addr_r         : std_logic_vector(23 downto 0);
  signal std_wrdata_r       : std_logic_vector(7 downto 0);
  signal hp_addr_r         : std_logic_vector(23 downto 0);
  signal hp_wrdata_r       : std_logic_vector(7 downto 0);
  signal data_capture_r : std_logic_vector(7 downto 0);
  signal std_wr_r           : std_logic;
  signal hp_wr_r            : std_logic;

  signal addr_s             : std_logic_vector(23 downto 0);
  signal wrdata_s           : std_logic_vector(7 downto 0);

  -- Enter quad mode: 0x35
  constant CMD_ENTERQUADMODE  : std_logic_vector(7 downto 0) := x"35";--x"35";
  constant CMD_QUADREAD       : std_logic_vector(7 downto 0) := x"EB";--x"35";
  constant CMD_QUADWRITE      : std_logic_vector(7 downto 0) := x"38";--x"35";

  signal clock_disable_s      : std_logic;
  signal master_r             : std_logic; -- '0': regular master, '1': high priority master
  signal hp_request           : std_logic;

  signal write_flag_s         : std_logic;
  signal need_resume_r        : std_logic; -- Last STD transaction was aborted.
  signal abort_transaction_s  : std_logic;
  signal test_ready           : boolean := false;
begin

  cs_n_o          <= csn_r;
  oe_o            <= bus_oe_s;
  d_o             <= data_out_r;
  clk_o           <= clkgen_s(0);
  test_ready      <= true after 2 us;
  clock_disable_s <= not clock_enable_r;

  write_flag_s    <= std_wr_r when master_r='0'     else hp_wr_r;
  addr_s          <= std_addr_r when master_r='0'   else hp_addr_r;
  wrdata_s        <= std_wrdata_r when master_r='0' else hp_wrdata_r;

  clk_inst : ALTDDIO_OUT
  GENERIC MAP (
    extend_oe_disable => "OFF",
    intended_device_family => "Cyclone IV E",
    invert_output => "ON",
    lpm_hint => "UNUSED",
    lpm_type => "altddio_out",
    oe_reg => "UNREGISTERED",
    power_up_high => "ON",
    width => 1
  )
  PORT MAP (
    aclr      => clock_disable_s,
    datain_h  => "1",
    datain_l  => "0",
    outclock  => clk_i,
    dataout   => clkgen_s,
    oe_out    => open
  );

  -- Generate clock enable signal
  process(state_r)
  begin
    clock_enable_s  <= '1';
    case state_r is
      when STARTUP =>
        clock_enable_s <= '0';
      when INIT3 | INIT4 | INIT5  =>
        clock_enable_s <= '0';
      when IDLE    =>
        clock_enable_s <= '0';
      when DESELECT_WAIT1 | DESELECT_WAIT2 =>
        clock_enable_s <= '0';
      when RDDATA2 =>
        clock_enable_s <= '0';
      when RDDATA3 =>
        clock_enable_s <= '0';
      when DESELECT =>
        clock_enable_s <= '0';
      when ABORT_SWITCH_TO_HP | ABORT_SWITCH_TO_HP2 =>
        clock_enable_s <= '0';
      when others   =>
    end case;
  end process;


  hp_request <= '1' when hp_ahb_i.HTRANS/=C_AHB_TRANS_IDLE else '0';

  abort_transaction_s <= '1' when master_r='0' and hp_request='1' else '0';

  process(state_r, hp_request)
  begin
    ahb_o.HREADY    <= '0';
    hp_ahb_o.HREADY    <= '0';
    case state_r is
      when STARTUP =>
      when INIT1   =>
      when INIT2   =>
      when INIT3 | INIT4 | INIT5  =>
      when IDLE    =>
        ahb_o.HREADY      <= not hp_request;
        hp_ahb_o.HREADY   <= '1';

      when WRDATA3 =>

      when DESELECT_WAIT1 =>
        ahb_o.HREADY      <= not master_r; -- ack only ours
        hp_ahb_o.HREADY   <= master_r; -- ack only ours
      when DESELECT_WAIT2 =>

      when RDDATA2 =>
      when RDDATA3 =>
      when DESELECT =>

      --when others   =>
      when CHIPSELECT =>
      when ADDRESS1 =>
      when ADDRESS2 =>
      when ADDRESS3 =>
      when ADDRESS4 =>
      when ADDRESS5 =>
      when ADDRESS6 =>
      when ADDRESS7 =>
      when RDDLY    =>
      when RDDATA1  =>
      when WRDATA1  =>
      when WRDATA2  =>
      when ABORT_SWITCH_TO_HP =>
        hp_ahb_o.HREADY   <= '1';
      when ABORT_SWITCH_TO_HP2 =>

    end case;
  end process;


  process(clk_i, arst_i)
  begin
    if arst_i='1' then
      state_r       <= STARTUP;
      bus_oe_s      <= (others => '0');
      csn_r         <= '1';
      std_addr_r    <= (others => 'X');
      hp_addr_r     <= (others => 'X');
      std_wrdata_r  <= (others => 'X');
      hp_wrdata_r   <= (others => 'X');
      hp_addr_r     <= (others => 'X');
      std_wr_r      <= 'X';
      hp_wr_r       <= 'X';
      need_resume_r <= '0';
      clock_enable_r<='0';

    elsif rising_edge(clk_i) then
      case state_r is
        when STARTUP =>
          if test_ready then
            state_r     <= INIT1;
            init_cnt_r  <= "111";
            clock_enable_r <= '1';
          end if;
        when INIT1 =>
          data_out_r(0)  <= CMD_ENTERQUADMODE( to_integer(init_cnt_r) );
          data_out_r(1)  <= '1';
          data_out_r(2)  <= '1';
          bus_oe_s    <= "0111"; -- Only MOSI/WP/HOLD
          csn_r      <= '0';
          if init_cnt_r=0 then
            state_r   <= INIT2;
           -- csn_r     <= '1';
          else
            init_cnt_r  <= init_cnt_r - 1;
          end if;
        when INIT2 =>
          state_r         <= INIT3;
          clock_enable_r  <='0';
        when INIT3  =>
          state_r         <= INIT4;
        when INIT4  =>
          csn_r           <= '1';
          state_r         <= INIT5;

        when INIT5 =>
          state_r <= IDLE;

        when IDLE =>
          need_resume_r <= '0';
          if ahb_i.HTRANS/=C_AHB_TRANS_IDLE then
            if ahb_i.HTRANS=C_AHB_TRANS_SEQ then
              std_wr_r        <= ahb_i.HWRITE;
              std_addr_r      <= ahb_i.HADDR(23 downto 0);
              std_wrdata_r    <= ahb_i.HWDATA(7 downto 0);

              state_r         <= CHIPSELECT;
              bus_oe_s        <= "1111";
              csn_r           <= '0';
              clock_enable_r  <= '1';
              master_r        <= '0';
            end if;
            -- Todo raise HRESP error
          end if;

          -- High priority
          if hp_ahb_i.HTRANS/=C_AHB_TRANS_IDLE then
              hp_wr_r         <= hp_ahb_i.HWRITE;
              hp_addr_r       <= hp_ahb_i.HADDR(23 downto 0);
              hp_wrdata_r     <= hp_ahb_i.HWDATA(7 downto 0);
              state_r         <= CHIPSELECT;
              bus_oe_s        <= "1111";
              csn_r           <= '0';
              clock_enable_r  <= '1';
              master_r        <= '1';
          end if;

        when CHIPSELECT =>
          if write_flag_s='1' then
            data_out_r(3 downto 0) <= CMD_QUADWRITE(7 downto 4);
          else
            data_out_r(3 downto 0) <= CMD_QUADREAD(7 downto 4);
          end if;

          state_r <= ADDRESS1;
          -- If HP master interrupted, deselect
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ABORT_SWITCH_TO_HP =>
          hp_wr_r         <= hp_ahb_i.HWRITE;
          hp_addr_r       <= hp_ahb_i.HADDR(23 downto 0);
          hp_wrdata_r     <= hp_ahb_i.HWDATA(7 downto 0);
          master_r        <= '1';
          need_resume_r   <= '1';
          csn_r           <= '1';
          state_r         <= ABORT_SWITCH_TO_HP2;

        when ABORT_SWITCH_TO_HP2 =>
          csn_r           <= '0';
          clock_enable_r  <= '1';
          state_r         <= CHIPSELECT;
          bus_oe_s        <= "1111";

        when ADDRESS1 =>
          state_r <= ADDRESS2;
          bus_oe_s    <= "1111";
          csn_r <= '0';
          if write_flag_s='1' then
            data_out_r(3 downto 0) <= CMD_QUADWRITE(3 downto 0);
          else
            data_out_r(3 downto 0) <= CMD_QUADREAD(3 downto 0);
          end if;
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ADDRESS2 =>
          state_r <= ADDRESS3;
          bus_oe_s    <= "1111";
          csn_r <= '0';
          data_out_r(3 downto 0) <= addr_s(23 downto 20);
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ADDRESS3 =>
          state_r <= ADDRESS4;
          bus_oe_s    <= "1111";
          csn_r <= '0';
          data_out_r(3 downto 0) <= addr_s(19 downto 16);
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ADDRESS4 =>
          state_r <= ADDRESS5;
          bus_oe_s    <= "1111";
          csn_r <= '0';
          data_out_r(3 downto 0) <= addr_s(15 downto 12);
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ADDRESS5 =>
          state_r <= ADDRESS6;
          bus_oe_s    <= "1111";
          csn_r <= '0';
          data_out_r(3 downto 0) <= addr_s(11 downto 8);
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ADDRESS6 =>
          state_r <= ADDRESS7;
          bus_oe_s    <= "1111";
          csn_r <= '0';
          data_out_r(3 downto 0) <= addr_s(7 downto 4);
          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when ADDRESS7 =>
          if write_flag_s='0' then
            state_r <= RDDLY;
          else
            state_r <= WRDATA1;
          end if;
          csn_r <= '0';
          bus_oe_s    <= "1111";
          data_out_r(3 downto 0) <= addr_s(3 downto 0);
          init_cnt_r  <= "110";

          if write_flag_s='0' then
            if abort_transaction_s='1' then
              state_r         <= ABORT_SWITCH_TO_HP;
              csn_r           <= '1';
              clock_enable_r  <= '0';
            end if;
          end if;


        when RDDLY =>
          bus_oe_s    <= "0000";
          if init_cnt_r=0 then
            state_r   <= RDDATA1;
           -- csn_r     <= '1';
          else
            init_cnt_r  <= init_cnt_r - 1;
          end if;

          if abort_transaction_s='1' then
            state_r         <= ABORT_SWITCH_TO_HP;
            csn_r           <= '1';
            clock_enable_r  <= '0';
          end if;

        when RDDATA1 =>
          bus_oe_s        <= "0000";
          state_r         <= RDDATA2;
          clock_enable_r  <='0';

        when RDDATA2 =>
          bus_oe_s    <= "0000";
          data_capture_r(3 downto 0) <= d_neg_r;
          state_r <= RDDATA3;--RDDATA3;

        when RDDATA3 =>
          bus_oe_s    <= "0000";
          csn_r <= '1'; -- Looks like early deselect - is not.
          data_capture_r(7 downto 4) <= d_neg_r;
          clock_enable_r <= '0';
          state_r <= DESELECT_WAIT1;

        when WRDATA1 =>
          bus_oe_s    <= "1111";
          data_out_r(3 downto 0) <= wrdata_s(3 downto 0);
          state_r <= WRDATA2;
        when WRDATA2 =>
          bus_oe_s    <= "1111";
          data_out_r(3 downto 0) <= wrdata_s(7 downto 4);
          state_r <= WRDATA3;

        when WRDATA3 =>
          bus_oe_s    <= "1111";
          data_out_r(3 downto 0) <= (others => 'X');--wrdata_r(7 downto 4);
          state_r <= DESELECT_WAIT1;
          clock_enable_r <= '0';

        when DESELECT_WAIT1 =>
          state_r <= DESELECT_WAIT2;

        when DESELECT_WAIT2 =>
          state_r <= DESELECT;

        when DESELECT =>
          if need_resume_r='1' then
            state_r         <= CHIPSELECT;
            master_r        <= '0';
            clock_enable_r  <= '1';
            csn_r           <= '0';
            bus_oe_s        <= "1111";

          else
            state_r <= IDLE;
            csn_r <= '1';
          end if;

          need_resume_r <= '0';
      when others =>
      end case;
          
    end if;
  end process;

  process(clk_i)
  begin
    if falling_edge(clk_i) then
      d_neg_r   <= d_i;
    end if;
  end process;

  ahb_o.HRDATA(7 downto 0)  <= data_capture_r;
  ahb_o.HRDATA(31 downto 8)  <= (others => '0');
  ahb_o.HRESP   <= '0';

  hp_ahb_o.HRDATA(7 downto 0)  <= data_capture_r;
  hp_ahb_o.HRDATA(31 downto 8)  <= (others => '0');
  hp_ahb_o.HRESP   <= '0';

-- synthesis translate_off
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if clock_enable_r/=clock_enable_s then
        report "ERROR clock enable " & str(clock_enable_r) & " expected " & str(clock_enable_s);-- severity failure;
      end if;
    end if;
  end process;
-- synthesis translate_on


end beh;


