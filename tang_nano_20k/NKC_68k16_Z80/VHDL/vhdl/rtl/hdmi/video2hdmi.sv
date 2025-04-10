// video2hdmi.v

// this also generates the 32 Mhz main system clock as the 
// hdmi need 5 times that

module video2hdmi (
	      input	       clk,      // 27 Mhz in
	      
	      output	   clk_40,   // 40 Mhz out
	      output	   pll_lock,

          // video control inputs
          input        vreset,   // top/left pixel reached
          input [1:0]  vvmode,   // Video Mode
          input        vwide,    // request display on wide (16:9) screen

	      input [2:0]  r,
	      input [2:0]  g,
	      input [2:0]  b,

          // audio is encoded into the video
          //input [15:0] audio[2],
          input [15:0] audio0,
          input [15:0] audio1,

	      // hdmi/tdms
	      output	   tmds_clk_n,
	      output	   tmds_clk_p,
	      output [2:0] tmds_d_n,
	      output [2:0] tmds_d_p  
);
   
wire clk_pixel_x5;   // 200 MHz HDMI clock
wire clk_pixel;      // at 800x600@60Hz the pixel clock is 40 MHz

assign clk_40 = clk_pixel;
    
//`define PIXEL_CLOCK 32000000
//pll_160m pll_hdmi (
//               .clkout(clk_pixel_x5),
//               .lock(pll_lock),
//               .clkin(clk)
//	       );
`define PIXEL_CLOCK 40000000
pll_200m pll_hdmi (
               .clkout(clk_pixel_x5),
               .lock(pll_lock),
               .clkin(clk)
	       );

   
Gowin_CLKDIV clk_div_5 (
        .hclkin(clk_pixel_x5), // input hclkin
        .resetn(pll_lock),     // input resetn
        .clkout(clk_pixel)     // output clkout
    );


/* -------------------- HDMI video and audio -------------------- */

// generate 48khz audio clock
reg clk_audio = 0;
reg [8:0] aclk_cnt;
always @(posedge clk_pixel) begin
    // divisor = pixel clock / 48000 / 2 - 1
    if(aclk_cnt < `PIXEL_CLOCK / 48000 / 2 -1)
        aclk_cnt <= aclk_cnt + 9'd1;
    else begin
        aclk_cnt <= 9'd0;
        clk_audio <= ~clk_audio;
    end
end

wire [2:0] tmds;
wire tmds_clock;
wire [15:0] temp[2];
assign temp = {audio0,audio1};
hdmi #(
    .AUDIO_RATE(48000), .AUDIO_BIT_WIDTH(16),
    .VENDOR_NAME( { "AVG", 16'd0} ),
    .PRODUCT_DESCRIPTION( {"NKC", 64'd0} )
) hdmi(
  .clk_pixel_x5(clk_pixel_x5),
  .clk_pixel(clk_pixel),
  .clk_audio(clk_audio),
  //.audio_sample_word( { audio[0], audio[1] } ),
  .audio_sample_word( temp ),
  .tmds(tmds),
  .tmds_clock(tmds_clock),

  // video input
  .stmode(vvmode),    // current video mode PAL/NTSC/MONO
  .wide(vwide),      // adopt to wide screen video
  .reset(vreset),    // signal to synchronize HDMI

  // NKC outputs 3 bits per color. and HDMI expects 8 bits per color
  .rgb( { r, 5'b00, g, 5'b00, b, 5'b00 } )
);

// differential output
ELVDS_OBUF tmds_bufds [3:0] (
        .I({tmds_clock, tmds}),
        .O({tmds_clk_p, tmds_d_p}),
        .OB({tmds_clk_n, tmds_d_n})
);

endmodule
