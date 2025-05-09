//
// sdram.v
//
// sdram controller implementation for the Tang Nano 20k
// 
// Copyright (c) 2023 Till Harbaum <till@harbaum.org> 
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module sdram (
   // cpu/chipset interface
   input		  clk_i, // sdram is accessed at 80MHz
   input		  reset_n_i, // init signal after FPGA config to initialize RAM

   output		  ready_o, // ram is ready and has been initialized
   input		  refresh_i, // chipset requests a refresh cycle
   input [31:0]	  din, // data input from chipset/cpu
   output reg [31:0] dout,
   output  dout_valid_o,
   output  dout_valid_tgl_o, // toggle signal for data-valid inication
   output  cmd_ready_o,   // FSM is ready for an command
   input [20:0] addr_i,   // 21 bit word address
   input [3:0]  ds_i,     // upper/lower data strobe
   input cs_i,            // cpu/chipset requests read/write
   input we_i,            // cpu/chipset requests write
   input read_burst_i,
   // SDRAM interface
	output		  sd_clk, // sd clock
	output		  sd_cke, // clock enable
	inout reg [31:0]  sd_data, // 32 bit bidirectional data bus
`ifdef VERILATOR
	input [31:0]	  sd_data_in,
`endif
	output reg [12:0] sd_addr, // 11 bit multiplexed address bus
	output     [3:0]  sd_dqm, // two byte masks
	output reg [1:0]  sd_ba, // two banks
	output		  sd_cs, // a single chip select
	output		  sd_we, // write enable
	output		  sd_ras, // row address select
	output		  sd_cas // columns address select
);

//assign sd_clk = ~clk;
assign sd_clk = clk_i;
assign sd_cke = 1'b1;  
   
localparam RASCAS_DELAY   = 3'd2;   // tRCD=15ns -> 2 cycles@80MHz
localparam BURST_LENGTH   = 3'b000; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd2;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write
localparam RFSH_BUSY      = 2'd3;   // Number of busy cycles after Regressh command (tRFC)

localparam MODE = { 1'b0, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

// ---------------------------------------------------------------------
// ------------------------ cycle state machine ------------------------
// ---------------------------------------------------------------------

// The state machine runs at 40Mhz synchronous to the sync signal.
localparam STATE_IDLE      = 3'd0;   // first state in cycle
localparam STATE_CMD_CONT  = STATE_IDLE + RASCAS_DELAY; // command can be continued -> 1
localparam STATE_READ      = STATE_CMD_CONT + CAS_LATENCY + 3'd1;  // -> 4
localparam STATE_LAST      = 3'd6;  // last state in cycle -> 
   
// ---------------------------------------------------------------------
// --------------------------- startup/reset ---------------------------
// ---------------------------------------------------------------------

reg [2:0] state;
reg [4:0] init_state;


// wait 1ms (32 8Mhz cycles) after FPGA config is done before going
// into normal operation. Initialize the ram in the last 16 reset cycles (cycles 15-0)
assign ready_o = !(|init_state);
   
// ---------------------------------------------------------------------
// ------------------ generate ram control signals ---------------------
// ---------------------------------------------------------------------

// all possible commands
localparam CMD_INHIBIT         = 4'b1111;
localparam CMD_NOP             = 4'b0111;
localparam CMD_ACTIVE          = 4'b0011;
localparam CMD_READ            = 4'b0101;
localparam CMD_WRITE           = 4'b0100;
localparam CMD_BURST_TERMINATE = 4'b0110;
localparam CMD_PRECHARGE       = 4'b0010;
localparam CMD_AUTO_REFRESH    = 4'b0001;
localparam CMD_LOAD_MODE       = 4'b0000;

reg [3:0] sd_cmd;   // current command sent to sd ram
// drive control signals according to current command
assign sd_cs  = sd_cmd[3];
assign sd_ras = sd_cmd[2];
assign sd_cas = sd_cmd[1];
assign sd_we  = sd_cmd[0];

reg [31:0] sd_data_reg;
//assign sd_data = (cs && we) ? { din, din } : 32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz;
assign sd_data = (!sd_cs && we_i) ? { sd_data_reg } : 32'bzzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz_zzzz;

//assign sd_dqm = (!cs_i || !we_i)?4'b0000:~ds_i;
assign sd_dqm = ~ds_i;
reg csD;   
reg debug1;
reg dout_valid_reg;
reg dout_valid_tgl_reg;
reg [1:0] busy_count;
reg [3:0] burst_count;
reg [1:0] cas_pipe;

assign is_idle          = (state == STATE_IDLE)?1'b1:1'b0;
assign cmd_ready_o      = is_idle && ready_o && ((busy_count==0)?1'b1:1'b0);
assign dout_valid_o     = dout_valid_reg;
assign dout_valid_tgl_o = dout_valid_tgl_reg;

always @(posedge clk_i) begin

   sd_cmd <= CMD_INHIBIT;  // default: idle

   // init state machines runs once reset ends
   if(!reset_n_i) begin
      init_state         <= 5'h1f;
      state              <= STATE_IDLE;
      debug1             <= 1'b0;
      burst_count        <= 4'h0;
      cas_pipe           <= 2'b11;
      dout_valid_reg     <= 1'b0;
      dout_valid_tgl_reg <= 1'b0;
      sd_data_reg        <= 32'd0;
      busy_count         <= 2'b0;
   end else begin
      if(init_state != 0)
        state <= state + 3'd1;
      
      if((state == STATE_LAST) && (init_state != 0))
        init_state <= init_state - 5'd1;
      end
   
   if(init_state != 0) begin
      csD <= 1'b0;     
      
      // initialization takes place at the end of the reset
      if(state == STATE_IDLE) begin
         if(init_state == 13) begin
            sd_cmd      <= CMD_PRECHARGE;
            sd_addr[10] <= 1'b1;      // precharge all banks
         end

         if(init_state == 2) begin
            sd_cmd <= CMD_LOAD_MODE;
            sd_addr <= MODE;
         end
      end
   end else begin
      csD            <= cs_i;
      cas_pipe[0]    <= sd_cas;
      cas_pipe[1]    <= cas_pipe[0];
      dout_valid_reg <= 1'b0;
      if(busy_count!=0) begin
         busy_count     <= busy_count -1;
      end

      
      // normal operation, start on ... 
      if(state == STATE_IDLE) begin
        // ... rising edge of cs
         if (cs_i && !csD) begin
            if(!refresh_i) begin
               // RAS phase
               sd_cmd      <= CMD_ACTIVE;
               sd_addr     <= addr_i[18:8];
               sd_ba       <= addr_i[20:19];
               state       <= 3'd1;
               burst_count <= 4'd0;
               sd_data_reg <= din;
            end else begin
               sd_cmd     <= CMD_AUTO_REFRESH;  // 1
               busy_count <= RFSH_BUSY;
            end
         end
      end else begin
        // always advance state unless we are in idle state
        state <= state + 3'd1;

        // -------------------  cpu/chipset read/write ----------------------

        // CAS phase 
         if(state == STATE_CMD_CONT) begin
            sd_cmd  <= we_i?CMD_WRITE:CMD_READ;   // CAS is sd_cmd[1]
            sd_addr <= { 3'b100, addr_i[7:0] };
            if (read_burst_i && !we_i) begin
               sd_addr     <= { 3'b100, addr_i[7:0] + burst_count};
               if (burst_count < 7) begin
                  state       <= state;   // keep state until burst is finished
                  burst_count <= burst_count + 4'd1;
               end
            end
         end

         if(state > STATE_CMD_CONT && state < STATE_READ)
            sd_cmd <= CMD_NOP;
      
         if(state == STATE_READ) begin
            state <= 3'b0;
         end
        // read phase
        if (!cas_pipe[1] && !we_i) begin
         
               debug1             <= ~debug1;
               dout_valid_reg     <= 1'b1;
               dout_valid_tgl_reg <= !dout_valid_tgl_reg;
`ifdef VERILATOR
               //dout <= addr[0]?sd_data_in[15:0]:sd_data_in[31:16];
               dout <= sd_data_in;
`else
               //dout <= addr[0]?sd_data[15:0]:sd_data[31:16];
               dout <= sd_data;
`endif
//            end
        end
      end
   end
end
   
endmodule
