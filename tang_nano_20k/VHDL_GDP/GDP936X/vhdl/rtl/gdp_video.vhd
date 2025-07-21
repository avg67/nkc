--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - Video Unit
-- File        : GDP_video.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2007 by Andreas Voggeneder
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gdp_global.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;


entity gdp_video is
  port(reset_n_i  : in  std_ulogic;
       clk_en_i   : in  std_ulogic;
       clk_i      : in  std_ulogic;
       clk_2x_i   : in  std_ulogic; -- SDR clock
       -----------------------------
       -- interface to VRAM
       -----------------------------
       rd_req_o        : out std_ulogic;
       rd_addr_o       : out std_ulogic_vector(15 downto 0);
       rd_data_valid_i : in std_ulogic;
       rd_data_i       : in  std_ulogic_vector(31 downto 0);
       rd_ack_i        : in  std_ulogic;
       rd_busy_i       : in  std_ulogic;
       -----------------------------
       scroll_i      : in  std_ulogic_vector(6 downto 0);
       color_mode_i  : in  std_ulogic :='0';
       enable_i      : in  std_ulogic;
       fifo_ur_o     : out  std_ulogic;   -- fifo_underrun
       -----------------------------
       clut_we_i     : in  std_ulogic;
       clut_addr_i   : in  std_ulogic_vector(7 downto 0);
       clut_data_i   : in  std_ulogic_vector(8 downto 0);
       -----------------------------
       pixel_red_o   : out std_ulogic_vector(2 downto 0);
       pixel_green_o : out std_ulogic_vector(2 downto 0);
       pixel_blue_o  : out std_ulogic_vector(2 downto 0);
       Hsync_o       : out std_ulogic;
       Vsync_o       : out std_ulogic;
       blank_o       : out std_ulogic;
       vreset_o      : out std_ulogic;
      ------------------------------------------------------------------------
       -- Hardware-Cursor (to VIDEO section)
       ------------------------------------------------------------------------
      hwcuren_i      : in std_ulogic; -- hardware cursor enable ( CTRL2.6)
      curcol_i       : in std_ulogic_vector(7 downto 0); -- current FG color
      cx1_i          : in std_ulogic_vector(11 downto 0);
      cx2_i          : in std_ulogic_vector(11 downto 0);
      cy1_i          : in std_ulogic_vector(11 downto 0);
       cy2_i         : in std_ulogic_vector(11 downto 0)
            
       --------------------------
       -- Monitoring (Debug) signals
       --------------------------
--       monitoring_o: out std_ulogic_vector(7 downto 0)
     );
end gdp_video;

architecture rtl of gdp_video is
  constant Stages_c          : natural := 11;
  constant HFRONT_PORCH_c    : natural := 40;
  constant HBACK_PORCH_c     : natural := 88;
  constant HSYNC_c           : natural := 128;
  constant HMAX_c            : natural := HFRONT_PORCH_c+HSYNC_c+HBACK_PORCH_c+800; -- 40 + 128 + 88 + 800 = 1056
  constant VFRONT_PORCH_c    : natural := 1;
  constant VBACK_PORCH_c     : natural := 23;
  constant VSYNC_c           : natural := 4;
  constant VMAX_c            : natural := VFRONT_PORCH_c+VSYNC_c+VBACK_PORCH_c+600; -- 1 + 4 + 23 + 600 = 628
  constant LINE_MAX_c        : natural := (512/4) - RD_BURST_SIZE_c;
  
  type rd_state_t is(idle_e, wait_ack_e, s1_e, s1a_e, s2_e);
  type mem_rd_state_t is(mem_idle_e, mem_dly_e, mem_s1_e, mem_wait_ack_e);
  
  signal q                   : unsigned(Stages_c-1 downto 0); -- Pixel-Takt-Zähler
  signal Line                : unsigned(Stages_c-1 downto 0);
  signal HSYNC, VSYNC, VidEn : std_ulogic;
  signal VidEn1              : std_ulogic;
  signal blank,valid_line    : std_ulogic;
  signal Pixel               : std_ulogic_vector(7 downto 0);
  signal delay               : natural range 0 to 100;
  signal run                 : std_ulogic;
--  signal Pixel_count         : unsigned(2 downto 0);
--  signal next_Pixel_count    : unsigned(2 downto 0);
  signal rd_data,next_rd_data: std_ulogic_vector(31 downto 0);
  signal set_rd_data         : std_ulogic; 
  signal color_mode_reg      : std_ulogic; 
  signal scroll_reg          : std_ulogic_vector(scroll_i'range);

  signal rd_state,next_rd_state         : rd_state_t;
  signal next_rd_addr                   : std_ulogic_vector(rd_addr_o'range);
--  signal wait_not_busy                  : std_ulogic;
  --signal rd_req, next_rd_req            : std_ulogic;
  signal next_rd_req                    : std_ulogic;
  signal frame_start                    : std_ulogic;
  signal vreset,vreset_done             : std_ulogic;
  signal rgb_pixel                      : std_ulogic_vector(8 downto 0);
  signal Hsync_s                        : std_ulogic;
  signal Vsync_s                        : std_ulogic;
  signal vreset_s                       : std_ulogic;
  signal clut_q                         : std_ulogic_vector(8 downto 0);
  --
  signal mem_rd_state,next_mem_rd_state : mem_rd_state_t;
  signal next_rd_address,rd_address     : unsigned(15 downto 0);
  
  signal isCursor : std_ulogic;
  signal reset       : std_ulogic;
  signal fifo_rden   : std_ulogic;
  signal fifo_ae     : std_ulogic;
  signal fifo_empty  : std_ulogic;
  signal fifo_full   : std_ulogic;
  signal fifo_dout   : std_logic_vector(31 downto 0);
-- pragma translate_off
  signal debug1      : std_ulogic;
  signal debug2      : unsigned(6 downto 0);                -- Column
  signal debug3      : unsigned(rd_address'high downto 7);  -- Row
  signal debug4      : unsigned(rd_address'range);
  signal debug_wordcnt : natural;
-- pragma translate_on
begin
-- pragma translate_off
   assert (512 mod RD_BURST_SIZE_c)=0 report "Invalid burst size configuration" severity error;
-- pragma translate_on
   reset <= not reset_n_i;

--   vid_fifo_inst: entity work.video_fifo
--      port map (
--         Clk           => clk_i,
--         Reset         => reset,
--         Data          => std_logic_vector(rd_data_i),
--         WrEn          => rd_data_valid_i,
--         RdEn          => fifo_rden,
--
--         AlmostEmptyTh => "10000",
--         Almost_Empty  => fifo_ae,
--         Q             => fifo_dout,
--         Empty         => fifo_empty,
--         Full          => fifo_full
--      );

vid_fifo_inst: entity work.dual_video_fifo
   port map (
      WrReset       => reset,
      WrClk         => clk_2x_i,
      WrEn          => rd_data_valid_i,
      Data          => std_logic_vector(rd_data_i),
      
      RdReset       => reset,
      RdClk         => clk_i,
      RdEn          => fifo_rden,
      AlmostEmptyTh => "10000",
      Almost_Empty  => fifo_ae,
      Q             => fifo_dout,
      Empty         => fifo_empty,
      Full          => fifo_full
   );


   fifo_ur_o <= fifo_empty and fifo_rden;

  -- http://info.electronicwerkstatt.de/bereiche/monitortechnik/vga/Standard-Timing/
  -- 40 MHz (VGA2)
  -- Horizontal (Pixel):
  -- Front Porch 40
  -- Sync 128
  -- Back Porch 88
  -- Vorlauf 144
  -- Aktiv 512
  -- Nachlauf 144
  -- Gesamt 1056
  -- 
  -- Vertikal (Linien):
  -- Front Porch 1
  -- Sync 4
  -- Back Porch 23
  -- Vorlauf 44
  -- Aktiv 512
  -- Nachlauf 44
  -- Gesamt 628
  
  --             0           512       656   696  824   912       1056         
  --                                    S  40   128  88
  -- Horizontal: ---- 512 ----|---144---| HFP | HS | HBP |---144---| 
  --             0           512       556  557   561   584       628
  --                                               fs
  --                                    S   1   4     23
  -- Vertical:   ---- 512 ----|---44----| VFP | VS | VBP |---44----|
  
  valid_line <= '1' when  Line < 512 else
                '0';
  VidEn <= '1' when q < 512 and valid_line='1' else
           '0';
  VidEn1 <= '1' when (q = to_unsigned(HMAX_c-1, Stages_c) or q < 511) and valid_line='1' else
            '0'; 
  -- blank generation 
  -- blank_o <= '1' when (Line > 515 and Line < VMAX_c - 2) or (q > 515 and q < HMAX_c - 2) else '0';
  --blank_o <= '1' when (Line > 513 and Line < 627) or (q > 513 and q < 1055) else '0';
  blank <= '1' when (Line > 556 and Line < 561) else 
           '0';
  --blank_o <= '1' when (q > 513 and q < 1050) else '0';
  blank_o <= blank;
  
  
  
  vid : process(clk_i, reset_n_i,cx1_i,cx2_i,cy1_i,cy2_i,hwcuren_i)                 -- Generierung von VSync, HSync etc.
  begin
    if reset_n_i = '0' then
      HSYNC          <= '0'; 
      Line           <= to_unsigned(512 + 44 + VFRONT_PORCH_c-1, Stages_c);
      VSYNC          <= '0';
      q              <= (others => '0');
      frame_start    <= '0';
      vreset_done    <= '0';
      run            <= '0';
      delay          <= 100;
      color_mode_reg <= '0';
      scroll_reg     <= (others => '0');
--      line_start  <= '0'; 
    elsif rising_edge(clk_i) then
      if clk_en_i = '1' then
         frame_start <= '0';
         vreset      <= '0';
         if run='0' then
            if delay/=0 then
               delay <= delay - 1;
               if delay=10 then
                  vreset      <= '1';
               end if;
            else
               run         <= '1';
            end if;
         else
     --      line_start  <= '0'; 
           q           <= q + 1;                      -- Pixel-Zähler mit jedem Clock eins weiter
               
         -- detect hardware cursor:       
            if(hwcuren_i = '1') then      
               if(std_logic_vector(q) >= std_logic_vector(cx1_i(10 downto 0))) then
                if(std_logic_vector(q) < std_logic_vector(cx2_i(10 downto 0))) then
                 if(std_logic_vector(Line) >= std_logic_vector(cy1_i(10 downto 0))) then
                  if(std_logic_vector(Line) < std_logic_vector(cy2_i(10 downto 0))) then
                     isCursor <= '1';
                   else
                     isCursor <='0';
                   end if;
                  else
                    isCursor <='0';
                  end if;
                 else
                    isCursor <='0';
                 end if;
                else
                   isCursor <='0';
                end if;
            else
               isCursor <='0';
            end if;        
           
         
           if q = to_unsigned(HMAX_c-1, Stages_c) then         -- und nach Zeilen-Ende wieder auf 0
             q    <= (others => '0');
             if (Line = to_unsigned(VMAX_c-1, Stages_c) and vreset_done='0') then
                  vreset      <= '1';
                  vreset_done <= '1';
               end if;
     --      elsif q = to_unsigned(HSYNC_c-1, Stages) then
           elsif q = to_unsigned(512 + 144 + HFRONT_PORCH_c-1, Stages_c) then
             HSYNC <= '1'; -- activate HSync             -- HSync setzen und Zeile um 1 erhöhen
             Line       <= Line + 1;
     --        line_start <= '1';
     --        if Line = to_unsigned(VMAX_c-VSYNC_c-1, Stages) then
             if Line = to_unsigned(512 + 44 + VFRONT_PORCH_c-1, Stages_c) then
               VSYNC <= '1'; -- activate VSync              -- VSync setzen
             elsif Line = to_unsigned(512 + 44 + VFRONT_PORCH_c + VSYNC_c -1, Stages_c) then
               VSYNC          <= '0';                       -- nach VSyncPhase VSync löschen und frame_start setzen              
               frame_start    <= '1';
               color_mode_reg <= color_mode_i;
               scroll_reg     <= scroll_i;
             elsif Line = to_unsigned(VMAX_c-1, Stages_c) then
               Line <= (others => '0');                  -- Am Bildende Line wieder auf 0
             end if;
             
           elsif q = to_unsigned(512 + 144 + HFRONT_PORCH_c + HSYNC_c -1, Stages_c) then
             HSYNC <= '0';                            -- nach HSyncPhase HSync wieder auf 0
           end if;
         end if;
      
      end if;
    end if;
  end process vid;
  
-- pragma translate_off
   debug2 <=rd_address(6 downto 0);
   debug3 <=rd_address(rd_address'high downto 7);

   --process(debug2, viden, viden1)
   --begin
   --   if (viden1 and not viden)='1' then
   --      assert debug2=48 report "Address error" severity warning;
   --   end if;
   --end process;
   
   process(rd_data_valid_i)
      variable re: time;
      variable re_detected : boolean:=false;
   begin
      if rising_edge(rd_data_valid_i) then
         re_detected := true;
         re := now;
      elsif falling_edge(rd_data_valid_i) then
         --assert re_detected=false or (now = re) or (now - re) >=200ns report "Invalid fifo write detected" severity error;
         assert re_detected=false or (now = re) or (now - re) >=100ns report "Invalid fifo write detected" severity error;
         re_detected := false;
      end if;
   end process;
-- pragma translate_on

  MEM_RD_FSM_COMB: process(mem_rd_state, enable_i, frame_start, Line, color_mode_reg,
                           HSYNC,VSYNC,q,fifo_ae,rd_busy_i,rd_address,VidEn)
  begin 
    next_mem_rd_state <= mem_rd_state;
    next_rd_address   <= rd_address;
    next_rd_req       <= '0';
-- pragma translate_off
    debug1 <= '0';
-- pragma translate_on
    
    case mem_rd_state is
      when mem_idle_e =>
        if (frame_start='1') then
            next_mem_rd_state <= mem_dly_e;
            if not color_support_c then
               next_rd_address     <= to_unsigned(255*512/(32),next_rd_address'length); -- last line
            elsif color_mode_reg = '0' then
               -- 4 bit / Pixel (256x512)
               next_rd_address     <= to_unsigned(255*512/4,next_rd_address'length); -- last line
            else
                  -- 8 bit / Pixel (512x512)
               next_rd_address     <= to_unsigned(511*512/4,next_rd_address'length); -- last line
            end if;
        end if;
        
      when mem_dly_e =>
        next_rd_req       <= '1';
        next_mem_rd_state <= mem_wait_ack_e;
        
      when mem_wait_ack_e =>
         if rd_busy_i='0' then
            next_mem_rd_state    <= mem_s1_e;
            if unsigned(rd_address(6 downto 0)) = LINE_MAX_c then
               next_rd_address(6 downto 0) <= "0000000";
               if color_mode_reg = '1' or Line(0) = '1' then
                  next_rd_address(rd_address'high downto 7) <= rd_address(rd_address'high downto 7) - 1;
-- pragma translate_off
                  debug4 <= (others => '0');
                  debug4(rd_address'high downto 7) <= rd_address(rd_address'high downto 7) - 1;
-- pragma translate_on
                  if unsigned(rd_address(rd_address'high downto 7)) = 0 then
                     next_mem_rd_state    <= mem_idle_e;
                  end if;
               end if;
-- pragma translate_off
               debug1 <= '1';
-- pragma translate_on
            else
               next_rd_address(6 downto 0) <= rd_address(6 downto 0) + RD_BURST_SIZE_c;
            end if;
         end if;
            

--        end if;
      when mem_s1_e =>
        if (fifo_ae = '1') then
            next_rd_req       <= '1';
            next_mem_rd_state <= mem_wait_ack_e;
        end if;
      when others =>
        next_mem_rd_state <= mem_idle_e;
    end case;

    if enable_i='0' then
      next_mem_rd_state <= mem_idle_e;
    end if;    
  end process;

  process(clk_i,reset_n_i)
  begin
    if reset_n_i ='0' then
      mem_rd_state       <= mem_idle_e;
    elsif rising_edge(clk_i) then
      if clk_en_i = '1' then
         mem_rd_state       <= next_mem_rd_state;
      end if;
-- pragma translate_off
      if (viden1 and not viden)='1' then
         debug_wordcnt<= 0;
      elsif fifo_rden='1' then
         debug_wordcnt <= debug_wordcnt+1;
      end if;
-- pragma translate_on
    end if;
  end process;

  RD_FSM_COMB: process(rd_state,fifo_dout,rd_address, rd_data, Line, fifo_empty,
                       rd_ack_i,rd_busy_i, VidEn, VidEn1, q, frame_start, 
                       HSYNC,VSYNC,enable_i, color_mode_reg,fifo_empty,valid_line)
  begin
    next_rd_state       <= rd_state;
--    next_Pixel_count    <= Pixel_count;
    next_rd_data        <= (others => '-');
    set_rd_data         <= '0';
    fifo_rden           <= '0';
   
    case rd_state is       
      when idle_e =>
        -- currently no data available. do a prefetch
        -- empty fifo
        if fifo_empty='0' then
          fifo_rden  <= '1';
        end if;
        if frame_start = '1' then
          --next_rd_req   <= '1';
          next_rd_state <= s1_e;
        end if;

      when s1_e => 
        if VSYNC='1' then
            next_rd_state    <= idle_e;
        elsif fifo_empty='0' and valid_line='1' and HSYNC='1' then
            next_rd_state    <= s2_e;
            set_rd_data      <= '1';
            next_rd_data     <= std_ulogic_vector(fifo_dout);
            -- Debug
            --if Line(0) ='1' then
            --  next_rd_data(31 downto 24) <= (others => '1');
            --end if;
            fifo_rden        <= '1';
        end if;

      when s2_e =>  
        if VidEn ='1' then
        --if ((VidEn and not color_mode_i) or (VidEn1 and color_mode_i))='1' then
          if (not HSYNC and not VSYNC) = '1' then
            if not color_support_c then
                if unsigned(q(4 downto 0)) = 31 then
                    set_rd_data      <= '1';
                    next_rd_data     <= std_ulogic_vector(fifo_dout);
                    fifo_rden        <= '1';
                else
                    set_rd_data     <= '1';
                    next_rd_data    <= std_ulogic_vector(shift_left(unsigned(rd_data),1)); -- 8 pixel per byte 
                end if;
            else
               -- 8bit / Pixel
                if unsigned(q(1 downto 0))=3 then
                    if VidEn1='1' then
                      set_rd_data      <= '1';
                      next_rd_data     <= std_ulogic_vector(fifo_dout);
                      fifo_rden        <= '1';
                    else
                      next_rd_state   <= s1_e;
                    end if;
                else
                    set_rd_data               <= '1';
                    next_rd_data(31 downto 8) <= rd_data(23 downto 0); -- 4 pixel per Byte
                end if;
            end if;
          end if;
        --elsif color_mode_i='1' then
        --  next_rd_state    <= s1a_e;
        end if;     
        if VSYNC = '1' then
          next_rd_state   <= idle_e;
          fifo_rden       <= '0';
        end if;
                
      when others =>
        next_rd_state <= idle_e;
    end case;
    if enable_i='0' then
      next_rd_state <= idle_e;
      next_rd_data  <= (others => '0');
    end if;    
  end process;
  
  process(clk_i,reset_n_i,color_mode_reg)
  begin
    if reset_n_i ='0' then
      rd_state       <= idle_e;
      if not color_support_c then
        rd_address     <= to_unsigned(255*512/(32),rd_address'length); -- last line
--      elsif color_mode_reg = '1' then
--        -- 8 bit / Pixel (512x512)
--        rd_address     <= to_unsigned(511*512/4,rd_address'length); -- last line
      else
        -- 4 bit / Pixel (256x512)
        rd_address     <= to_unsigned(255*512/4,rd_address'length); -- last line
      end if;
      rd_data        <= (others => '0');
--      Pixel_count    <= (others => '0');
--      pixel          <= '0';
--      wait_not_busy  <= '0';
      --rd_req         <= '0';
    elsif rising_edge(clk_i) then
      if clk_en_i = '1' then
        rd_state       <= next_rd_state;
        --rd_req         <= next_rd_req;
        if set_rd_data = '1' then
          rd_data      <= next_rd_data;
        end if;
  --      pixel          <= next_pixel;
  --      Pixel_count    <= next_Pixel_count;
        if enable_i = '1' then
            rd_address <= next_rd_address;
        end if;
      end if;
    end if;
  end process;
  
  color_pixel: if color_support_c generate
  Pixel    <= "0000" & rd_data(31 downto 28) when isCursor = '0' and color_mode_reg = '0' else
              rd_data(31 downto 24) when isCursor = '0' and color_mode_reg = '1' else
              curcol_i;
  end generate;
  
  no_color_pixel: if not color_support_c generate
  Pixel    <= "0000000" & rd_data(31) when isCursor = '0' else
              "00000001";
  end generate;
           
  process(rd_address, scroll_reg, color_mode_reg)
    variable tmp_v : unsigned(rd_address'range);
  begin
    if color_support_c then
      tmp_v := rd_address + (unsigned(scroll_reg) & "00000000");
      if color_mode_reg='0' then
         tmp_v(rd_address'high downto 15):=(others => '0');
      end if;
    else
      tmp_v :=  "0000" & rd_address(12 downto 0) + (unsigned(scroll_reg) & "00000");
    end if;
    next_rd_addr <= std_ulogic_vector(tmp_v);
  end process;
  
  rd_req_o   <= next_rd_req;
  rd_addr_o  <= next_rd_addr;
  
   --process(clk_i)
   --begin
   --   if rising_edge(clk_i) then
   --      if clk_en_i = '1' then
   --         rd_req_o <= next_rd_req;
   --         rd_addr_o<= next_rd_addr;
   --      end if;
   --   end if;
   --end process;

  no_clut: if not use_clut_c or not color_support_c generate
    process(clk_i)
      function lookup(color : in std_ulogic_vector(3 downto 0)) return std_ulogic_vector is
        variable tmp : std_ulogic_vector(8 downto 0);
      begin
        tmp := (others => '0'); 
-- pragma translate_off
        if not is_x(color) then
-- pragma translate_on      
          case to_integer(unsigned(color)) is
            when 0  => tmp := "000000000"; -- 0  Schwarz        => 0   RGB 0,0,0
            when 1  => tmp := "111111111"; -- 1  Weiß           => 15  RGB 255,255,255
            when 2  => tmp := "111111000"; -- 2  Gelb           => 14  RGB 255,255,0
            when 3  => tmp := "000111000"; -- 3  Grün           => 10  RGB 0,255,0
            when 4  => tmp := "111000000"; -- 4  Rot            => 12  RGB 255,0,0
            when 5  => tmp := "000000111"; -- 5  Blau           => 9   RGB 0,0,255
            when 6  => tmp := "111000111"; -- 6  Violett        => 13  RGB 255,0,255
            when 7  => tmp := "000111111"; -- 7  Zyan           => 11  RGB 0,255,255
            when 8  => tmp := "001001001"; -- 8  Dunkelgrau     => 8   RGB 64,64,64
            when 9  => tmp := "100100100"; -- 9  Hellgrau       => 7   RGB 128,128,128
            when 10 => tmp := "011011000"; -- 10 Dunkelgelb     => 6   RGB 96,96,0
            when 11 => tmp := "000011000"; -- 11 Dunkelgrün     => 2   RGB 0,96,0
            when 12 => tmp := "011000000"; -- 12 Dunkelrot      => 4   RGB 96,0,0
            when 13 => tmp := "000000011"; -- 13 Dunkelblau     => 1   RGB 0,0,96
            when 14 => tmp := "011000011"; -- 14 Violett dunkel => 5   RGB 96,0,96
            when 15 => tmp := "000011011"; -- 15 Zyan dunkel    => 3   RGB 0,96,96
            when others => null;
          end case;
-- pragma translate_off
        end if;
-- pragma translate_on      
        return tmp;
      end;
    begin
      if rising_edge(clk_i) then
        if clk_en_i = '1' then
          if VidEn='1' then
            if color_mode_reg = '0' then
               rgb_pixel <= lookup(Pixel(3 downto 0));
            else
               rgb_pixel <= Pixel(7 downto 5) & Pixel(4 downto 3) & Pixel(3) & Pixel(2 downto 0);
            end if;
          else
            rgb_pixel <= (others => '0');
          end if;
          Hsync_o  <= HSYNC;
          Vsync_o  <= VSYNC;
          vreset_o <= vreset;
        end if;
      end if;
    end process;
  end generate;
  
   use_clut: if use_clut_c and color_support_c generate
      process(clk_i)
      begin
         if rising_edge(clk_i) then
            if clk_en_i = '1' then
               if (VidEn and enable_i)='1' then
                  --if color_mode_reg = '0' then
                     rgb_pixel <= std_ulogic_vector(clut_q);
                  --else
                  --   --           R                   G                   B
                  --   rgb_pixel <= Pixel(7 downto 5) & Pixel(4 downto 2) & Pixel(1 downto 0) & "0";
                  --   if Pixel(1 downto 0) ="11" then
                  --      rgb_pixel(0) <= '1';
                  --   end if;
                  --end if;
               else
                  rgb_pixel <= (others => '0');
               end if;
               Hsync_s  <= HSYNC;
               Vsync_s  <= VSYNC;
               vreset_s <= vreset;
            end if;
         end if;
      end process;

   clut_inst : entity work.gdp_clut_256
      port map(
        reset_n_i   => reset_n_i,
        clk_i       => clk_i,
        clk_en_i    => clk_en_i,
        WrAddress_i => clut_addr_i,
        Data_i      => clut_data_i,
        WE_i        => clut_we_i,
        RdAddress_i => Pixel,
        Data_o      => clut_q
      );
   end generate;  
  
  pixel_red_o    <= rgb_pixel(8 downto 6);
  pixel_green_o  <= rgb_pixel(5 downto 3);
  pixel_blue_o   <= rgb_pixel(2 downto 0);
  Hsync_o        <= Hsync_s;
  Vsync_o        <= Vsync_s;
  vreset_o       <= vreset_s;


-- pragma translate_off
   gdp_screen_dumper_inst: entity work.gdp_screen_dumper
      port map (
         reset_n_i     => reset_n_i,
         clk_en_i      => clk_en_i,
         clk_i         => clk_i,
         pixel_red_i   => rgb_pixel(8 downto 6),
         pixel_green_i => rgb_pixel(5 downto 3),
         pixel_blue_i  => rgb_pixel(2 downto 0),
         Hsync_i       => Hsync_s,
         Vsync_i       => Vsync_s,
         vid_en_i      => VidEn,
         line_i        => Line,
         column_i      => q
      );


-- pragma translate_on

  --with rd_state select
    --monitoring_o(1 downto 0) <= "00" when idle_e,
                                --"01" when wait_ack_e,
                                --"10" when s1_e,
                                --"11" when s2_e;
  --monitoring_o(2) <= VidEn;
  --monitoring_o(3) <= set_rd_data;
  --monitoring_o(4) <= wait_not_busy;
  --monitoring_o(5) <= enable_i;
  --monitoring_o(6) <= HSYNC;
  --monitoring_o(7) <= VSYNC;
  
end rtl;




