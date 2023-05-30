// *-------------------------------------------------------------------------
// *
// *    mx29LV640T.v - 64M-BIT CMOS Single Voltage 3V only Flash Memory
// *
// *            COPYRIGHT 2003 BY Macronix International Corporation
// *
// *--------------------------------------------------------------------------
// *  Environment  : Verilog-XL V 3.0 above
// *  Creation Date: 2003/04/
// *  Description  : There are only one module in this file
// *                 module flash_32m -> behavior model for the 64M bit flash
// *--------------------------------------------------------------------------
`timescale 1ns / 1ns

`define CYC_TIME  90
`define A_BIT     22

module flash_64m( A, Q, CE_B, WE_B , BYTE_B,  RESET_B, OE_B, RYBY_B );
//---------------------------------------------------------------------
// Declaration of ports (input,output, inout)
//---------------------------------------------------------------------
input  CE_B,        //  Chip enable, low active
       WE_B,        //  Write enable, low active
       BYTE_B,      //  Word/Byte mode, high for Word, low for Byte
       RESET_B,     //  Hardware Reset Enable, low active
       OE_B;        //  Output enable, low active
input  [21:0] A;    //  Address bus
inout  [15:0] Q;    //  Bidirectional Data bus
output RYBY_B;      //  Ready/Busy Status, high for Ready, low for Budy 

//---------------------------------------------------------------------
// Declaration of parameter (parameter)
//---------------------------------------------------------------------
parameter tRP      = 500,   // RESET_B Pulse Width, table 13
          tDF      = 30,    // OE_B high to output floating, p.35
          tACC     = 90,    // Address stable to output delay, p.35
          tCE      = 90,    // CE_B low to data output delay, p.35
          tOE      = 35,    // OE_B low to data output delay, p.35
          tBUSY    = 90,    // Program valid to RYBY_B low, table 11
          tFLQZ    = 25,    // BYTE_E Low to Q[15:8] Z, Figure 25
          tFHQV    = 70,    // BYTE_E High to Q[15:8] active, Figure 25
          tWHWH1_W = 11000, // Program valid to RYBY_B low, table 12
          tWHWH1_B = 9000,  // Program valid to RYBY_B low, table 12
          tChip_ers= 115000_000_000, // Chip Erase Time
          tWHWH2   = 900_000_000;  // Erase Time, table 12
`protect
parameter A_bit  = 23,
          A_msb  = 21,
          SA_msb = 21,
          SA_lsb = 12,
          Q_msb  = 15;

parameter  flash_size = 1 << A_bit;  // 8M bytes

// Internal State Machine State
parameter  [4:0] cycle1 = 5'h0,
                 cyc2_w = 5'h1,
                 cyc2_b = 5'h2,
                 cyc3_w = 5'h3,
                 cyc3_b = 5'h4,
                 pgm4_w = 5'h5,
                 pgm4_b = 5'h6,
                 ers4_w = 5'h7,
                 ers4_b = 5'h8,
                 ers5_w = 5'h9,
                 ers5_b = 5'ha,
                 ers6_w = 5'hb,
                 ers6_b = 5'hc,
                 cfi_qu = 5'hd,
                 sec4_w = 5'he,
                 sec4_e = 5'hf,
                 ext4_w = 5'h10,
                 ext4_b = 5'h11;

// Command bus parameters
parameter  [21:0] cyc1_w_cmd = 22'h1_555_aa,
                  cyc1_b_cmd = 22'h0_aaa_aa,
                  cfi_wquery = 22'h1_055_98,
                  cfi_bquery = 22'h0_0aa_98,
                  cyc2_w_cmd = 22'h1_2aa_55,
                  cyc2_b_cmd = 22'h0_555_55,
                  ver3_w_cmd = 22'h1_555_90,
                  ver3_b_cmd = 22'h0_aaa_90,
                  sec3_w_cmd = 22'h1_555_88,
                  sec3_b_cmd = 22'h0_aaa_88,
                  ext3_w_cmd = 22'h1_555_90,
                  ext3_b_cmd = 22'h0_aaa_90,
                  pgm3_w_cmd = 22'h1_555_a0,
                  pgm3_b_cmd = 22'h0_aaa_a0,
                  ers3_w_cmd = 22'h1_555_80,
                  ers3_b_cmd = 22'h0_aaa_80,
                  ers4_w_cmd = 22'h1_555_aa,
                  ers4_b_cmd = 22'h0_aaa_aa,
                  ers5_w_cmd = 22'h1_2aa_55,
                  ers5_b_cmd = 22'h0_555_55,
                  ers6_w_cmd = 22'h1_555_10,
                  ers6_b_cmd = 22'h0_aaa_10;

parameter  [7:0] ers_suspend = 8'hb0,
                 ers_resume  = 8'h30;

// Internal counter parameter
parameter  cd_cyc    = 50,      // Internal clock cycle = 100ns
           pgw_count = tWHWH1_W / (cd_cyc*2),
           pgb_count = tWHWH1_B / (cd_cyc*2),
           erc_count = tChip_ers/ (cd_cyc*2),
           ers_count = tWHWH2   / (cd_cyc*2);

//---------------------------------------------------------------------
// Declaration of internal-register (reg)
//---------------------------------------------------------------------
reg    [7:0]  array[ 0: flash_size-1 ];  // Flash Array
reg    [Q_msb:0] Q_reg;      // Register to drive Q port
reg    [A_msb+1:0] latch_A;  // latched Address
reg    [Q_msb:0] latch_Q;    // latched Data
reg    [7:0]  pg_latch_Q;    // latched Data in program
reg    [7:0]  er_latch_Q;    // latched Data in erase
reg    [4:0]  state;         // Internal Finite State Machine
reg    during_cfi_mode;      // a flag to indicate in read ID state
reg    during_read_ID;       // a flag to indicate in read ID state
reg    during_program;       // a flag to indicate in Program state
reg    during_erase;         // a flag to indicate in Erase state
reg    during_susp_read;     // to indicate read in Erase Suspend state
reg    suspend_flag;
reg    resume_flag;
reg    RYBY_B;
reg    pgm_clk;              // internal clock register for program timer
reg    ers_clk;              // internal clock register for erase timer

wire   #(0, tRP) hw_reset_b   = RESET_B;  // Hardware Reset
wire   #(0, tCE) d_ce_b       = CE_B;     // Delayed Chip enable
wire   #(0, tOE) d_oe_b       = OE_B;     // Delayed Output enable
wire   #(tFHQV, tFLQZ) byte_b = BYTE_B;   // Delayed RYBY_B enable

wire   program = CE_B || WE_B || ( ~OE_B );
wire   o_dis   = ( d_ce_b || d_oe_b || hw_reset_b == 1'b0 );
wire   [20:0]  cmd_bus = { BYTE_B, A[11:0], Q[7:0] };

reg[A_msb+1:0] start_a, end_a;
integer i;

//---------------------------------------------------------------------
// Power-on State in finite state machine
//---------------------------------------------------------------------
initial begin
    RYBY_B           = 1'b1;
    state            = cycle1;
    during_read_ID   = 1'b0;
    during_program   = 1'b0;
    during_erase     = 1'b0;
    during_susp_read = 1'b0;
    suspend_flag     = 1'b0;
    resume_flag      = 1'b0;
    for( i = 0; i < flash_size; i = i+1 ) begin
        array[ i ] = 8'hff;   // Set Erase state
    end
end

//---------------------------------------------------------------------
// Prepare Q_Reg for Read Data
//---------------------------------------------------------------------
always @( A or Q[15] or negedge CE_B or
          during_read_ID or during_program or
          during_erase or during_susp_read ) begin

    if ( during_read_ID ) begin
        case ( A[1:0] )
            2'b00:   Q_reg <= #tACC 16'hc2;
            2'b01:   Q_reg <= #tACC 16'h22c9;
            default: Q_reg <= #tACC 16'bxxxxxxxxxxxxxxxx;
        endcase
    end
    else if ( during_cfi_mode ) begin
        Q_reg <= #tACC cfi_table( A[7:0] );
    end
    else if ( during_program ) begin
        pg_latch_Q = { pg_latch_Q[7], ~pg_latch_Q[6], 1'b0, 1'b0,
                              1'b0,    pg_latch_Q[2], 1'b0, 1'b0 };
        Q_reg[7:0] <= #tCE pg_latch_Q;
    end
    else if ( during_erase ) begin
        er_latch_Q = { 1'b0, ~er_latch_Q[6], 1'b0, 1'b0,
                       1'b1, ~er_latch_Q[2], 1'b0, 1'b0 };
        Q_reg[7:0] <= #tCE er_latch_Q;
    end
    else if ( during_susp_read && A >= (start_a >> 1) &&
                                  A <= (end_a   >> 1)) begin
        er_latch_Q = { 1'b1,  er_latch_Q[6], 1'b0, 1'b0,
                       1'b0, ~er_latch_Q[2], 1'b0, 1'b0 };
        Q_reg[7:0] <= #tCE er_latch_Q;
    end
    else begin
        Q_reg <= #tACC BYTE_B ? { array[A*2+1], array[A*2] } :
                                { 8'bxxxxxxxx,  array[{A,Q[15]}] };
    end
end

// Output (Read) Data if control signals do not disable
//-------------------------------------------------------
assign #(0, 0, tDF) Q[7:0]  = o_dis ? 8'bz : Q_reg[7:0];
assign #(0, 0, tDF) Q[15:8] = ( o_dis || byte_b == 1'b0 ) ?
                               8'bz : Q_reg[15:8];

//---------------------------------------------------------------------
// For write cycle, change State in finite state machine
//---------------------------------------------------------------------
always @( posedge program or negedge hw_reset_b )
begin
    during_read_ID = 0;
    if ( hw_reset_b == 1'b0 ) begin
        state = cycle1;  // next state = cycle1
    end
    else begin
        case ( state )
            cycle1: begin
                case ( cmd_bus )
                    cyc1_w_cmd: state = cyc2_w;
                    cyc1_b_cmd: state = cyc2_b;
                    cfi_wquery: begin
                                state = cfi_qu;
                                during_cfi_mode <= #1 1'b1;
                                $display($stime, " Enter CFI Query Mode ...");
                                end
                    cfi_bquery: begin
                                state = cfi_qu;
                                during_cfi_mode <= #1 1'b1;
                                end
                    default:    state = cycle1;
                endcase
            end
            cfi_qu: begin
                if ( Q[7:0] == 8'hf0 ) begin  // Reset Command
                    state = cycle1;
                    during_cfi_mode <= #1 1'b0;
                    $display($stime, " Exit CFI Query Mode ...");
                end
                else begin
                    state = cfi_qu;
                end
            end
            cyc2_w: begin
                case ( cmd_bus )
                    cyc2_w_cmd: state = cyc3_w;
                    default:    state = cycle1;
                endcase
            end
            cyc2_b: begin
                case ( cmd_bus )
                    cyc2_b_cmd: state = cyc3_b;
                    default:    state = cycle1;
                endcase
            end
            cyc3_w: begin
                case ( cmd_bus )
                    pgm3_w_cmd: state = pgm4_w;  // next state
                    ers3_w_cmd: state = ers4_w; // next state
                    sec3_w_cmd: begin
                        enter_sec_region;
                        state = cycle1;
                    end
                    ver3_w_cmd: begin
                        @( negedge CE_B )  // to enter cycle 4
                        if ( A[1] == 1'b0 ) begin
                            during_read_ID = 1'b1;
                        end
                        state = cycle1;
                    end
                    default: state = cycle1;
                endcase
            end
            cyc3_b: begin
                case ( cmd_bus )
                    pgm3_b_cmd: state = pgm4_b;  // next state
                    ers3_b_cmd: state = ers4_b; // next state
                    sec3_b_cmd: begin
                        enter_sec_region;
                        state = cycle1;
                    end
                    ver3_b_cmd: begin
                        @( negedge CE_B )  // to enter cycle 4
                        if ( A[1] == 1'b0 ) begin
                            during_read_ID = 1'b1;
                        end
                        state = cycle1;
                    end
                    default: state = cycle1;
                endcase
            end
            pgm4_w: begin
                latch_A = A;
                latch_Q = Q;
                pgw_count_down;
                state = cycle1;
            end
            pgm4_b: begin
                latch_A = { A, Q[15] };
                latch_Q = { Q[7:0] };
                pgb_count_down;
                state = cycle1;
            end
            ers4_w: begin
                case ( cmd_bus )
                    ers4_w_cmd: state = ers5_w;
                    default:    state = cycle1;
                endcase
            end
            ers4_b: begin
                case ( cmd_bus )
                    ers4_b_cmd: state = ers5_b;
                    default:    state = cycle1;
                endcase
            end
            ers5_w: begin
                case ( cmd_bus )
                    ers5_w_cmd: state = ers6_w;
                    default:    state = cycle1;
                endcase
            end
            ers5_b: begin
                case ( cmd_bus )
                    ers5_b_cmd: state = ers6_b;
                    default:    state = cycle1;
                endcase
            end
            ers6_w: begin
                if ( cmd_bus == ers6_w_cmd ) chip_erase;
                else if ( Q[7:0] == 8'h30 ) sec_erase( A[SA_msb:SA_lsb] );
                state = cycle1;
            end
            ers6_b: begin
                if ( cmd_bus == ers6_b_cmd ) chip_erase;
                else if ( Q[7:0] == 8'h30 ) sec_erase( A[SA_msb:SA_lsb] );
                state = cycle1;
            end
            default: begin
                state = cycle1;
            end
        endcase
    end
end

always @( posedge program )
begin
    suspend_flag = ( Q[7:0] == ers_suspend ) ? 1'b1 : 1'b0;
    resume_flag  = ( Q[7:0] == ers_resume  ) ? 1'b1 : 1'b0;
end

specify
    specparam tWC  = `CYC_TIME,
              tWP  = 35,
              tWPH = 30,
              tCS  = 0,
              tCH  = 0,
              tAS  = 0,
              tAH  = 45,
              tDS  = 45,
              tDH  = 0,
              tOES = 0;

    $period( posedge A,    tWC );
    $period( negedge A,    tWC );
    $width(  negedge WE_B, tWP );
    $width(  posedge WE_B, tWPH );
    $setup(  A, negedge WE_B, tAS );
    $hold(   negedge WE_B, A, tAH );
    $setup(  Q, posedge WE_B, tDS );
    $hold(   posedge WE_B, Q, tDH );

endspecify

// ---------------------------------------------------------------
//  Module Task Declaration
// ---------------------------------------------------------------

/*---------------------------------------------------------------*/
/*  Description: define a program counter for word command       */
/*---------------------------------------------------------------*/
task pgw_count_down;
integer    i;
reg [7:0]  ori_low, ori_hi;
begin

    ori_low      = array[2*A];
    ori_hi       = array[2*A+1];
    array[2*A]   = array[2*A]   & 8'bXXXXXXXX;  // Set unknown first
    array[2*A+1] = array[2*A+1] & 8'bXXXXXXXX;  // Set unknown first

    during_program = 1'b1;
    // Initailize Write Operation Status
    //---------------------------------------------
    pg_latch_Q[ 7 ] = ~latch_Q[7];  // Q7/
    pg_latch_Q[ 6 ] =  latch_Q[6];  // will be toggled
    pg_latch_Q[ 5 ] =  1'b0;
    pg_latch_Q[ 2 ] =  latch_Q[2];  // no toggle

    RYBY_B = 1'b0;
    $display($stime, " Program Word: Address %h - Data %h", latch_A, latch_Q);

    // Enter Program Operation 
    //---------------------------------------------
    fork
        pg_timer;
        begin
            #1;
            for( i = 0; i < pgw_count; i = i+1 ) begin
                @( posedge pgm_clk or negedge hw_reset_b );
                if ( hw_reset_b == 1'b0 ) i = pgw_count; // terminate
            end
            if ( hw_reset_b == 1'b1 ) begin // No Reset. Finish completly
                array[ 2*latch_A ]   = latch_Q[7:0] & ori_low;
                array[ 2*latch_A+1 ] = latch_Q[15:8]& ori_hi;
            end
            // else leave array [ A ] unknow
            disable pg_timer;
        end
    join

    RYBY_B = 1'b1;
    during_program = 1'b0;

end
endtask

/*---------------------------------------------------------------*/
/*  Description: define a program counter for byte command       */
/*---------------------------------------------------------------*/
task pgb_count_down;
integer i;
reg [7:0]  ori_low;
begin

    ori_low = array[ latch_A ];
    array[ latch_A ] = array[ latch_A ] & 8'bxxxxxxxx; // Set unknown first

    during_program = 1'b1;
    // Initailize Write Operation Status
    //---------------------------------------------
    pg_latch_Q[ 7 ] = ~latch_Q[7];  // Q7/
    pg_latch_Q[ 6 ] =  latch_Q[6];  // will be toggled
    pg_latch_Q[ 5 ] =  1'b0;
    pg_latch_Q[ 2 ] =  latch_Q[2];  // no toggle

    RYBY_B = 1'b0;
    $display($stime, " Program Byte: Address %h - Data %h",
                       latch_A, latch_Q[7:0]);

    // Enter Program Operation 
    //---------------------------------------------
    fork
        pg_timer;
        begin
            for( i = 0; i < pgb_count; i = i+1 ) begin
                @( posedge pgm_clk or negedge hw_reset_b );
                if ( hw_reset_b == 1'b0 ) i = pgb_count;  // terminate
            end
            if ( hw_reset_b == 1'b1 ) begin // No Reset. Finish completly
                array[ latch_A ] = latch_Q & ori_low;
            end
            // else leave array [ A ] unknow
            disable pg_timer;
        end
    join

    RYBY_B = 1'b1;
    during_program = 1'b0;

end
endtask

/*---------------------------------------------------------------*/
/*  Description: define a chip erase task                        */
/*---------------------------------------------------------------*/
task chip_erase;
integer i;

begin

    for( i = 0; i < flash_size; i = i+1 ) begin
        array[ i ] = 8'bxxxxxxxx;   // set unknown first
    end

    during_erase = 1'b1;
    // Initailize Erase Operation Status
    //---------------------------------------------
    er_latch_Q[ 7 ] = 1'b0;
    er_latch_Q[ 6 ] = latch_Q[6];  // will be toggled
    er_latch_Q[ 5 ] = 1'b0;
    er_latch_Q[ 3 ] = 1'b1;
    er_latch_Q[ 2 ] = latch_Q[2];  // will be toggled

    RYBY_B = 1'b0;
    $display($stime, " Chip Erase ...");

    // Enter Erase Operation 
    //---------------------------------------------
    fork
        er_timer;
        begin
            #1;
            for( i = 0; i < erc_count; i = i+1 ) begin
                @( posedge ers_clk or negedge hw_reset_b );
                if ( hw_reset_b == 1'b0 ) i = erc_count;  // terminate
            end
            if ( hw_reset_b == 1'b1 ) begin // No Reset. Finish completly
                for( i = 0; i < flash_size; i = i+1 ) begin
                    array[ i ] = 8'hff;    // erase
                end
            end
            // else leave array [ A ] unknow
            disable er_timer;
        end
    join

    RYBY_B = 1'b1;
    during_erase = 1'b0;

end
endtask

/*---------------------------------------------------------------*/
/*  Description: define a erase sector task                      */
/*---------------------------------------------------------------*/
task sec_erase;
input [SA_msb-SA_lsb:0] sector;  // A[SA_msb:SA_lsb] defines a sector
integer i;

begin

    // Implement sector table
    //------------------------------------------
    case( sector[SA_msb-SA_lsb:3] )
       7'b0000000: begin
           start_a = `A_BIT'h000000; end_a = `A_BIT'h00ffff;
       end
       7'b0000001: begin
           start_a = `A_BIT'h010000; end_a = `A_BIT'h01ffff;
       end
       7'b0000010: begin
           start_a = `A_BIT'h020000; end_a = `A_BIT'h02ffff;
       end
       7'b0000011: begin
           start_a = `A_BIT'h030000; end_a = `A_BIT'h03ffff;
       end
       7'b0000100: begin
           start_a = `A_BIT'h040000; end_a = `A_BIT'h04ffff;
       end
       7'b0000101: begin
           start_a = `A_BIT'h050000; end_a = `A_BIT'h05ffff;
       end
       7'b0000110: begin
           start_a = `A_BIT'h060000; end_a = `A_BIT'h06ffff;
       end
       7'b0000111: begin
           start_a = `A_BIT'h070000; end_a = `A_BIT'h07ffff;
       end
       7'b0001000: begin
           start_a = `A_BIT'h080000; end_a = `A_BIT'h08ffff;
       end
       7'b0001001: begin
           start_a = `A_BIT'h090000; end_a = `A_BIT'h09ffff;
       end
       7'b0001010: begin
           start_a = `A_BIT'h0a0000; end_a = `A_BIT'h0affff;
       end
       7'b0001011: begin
           start_a = `A_BIT'h0b0000; end_a = `A_BIT'h0bffff;
       end
       7'b0001100: begin
           start_a = `A_BIT'h0c0000; end_a = `A_BIT'h0cffff;
       end
       7'b0001101: begin
           start_a = `A_BIT'h0d0000; end_a = `A_BIT'h0dffff;
       end
       7'b0001110: begin
           start_a = `A_BIT'h0e0000; end_a = `A_BIT'h0effff;
       end
       7'b0001111: begin
           start_a = `A_BIT'h0f0000; end_a = `A_BIT'h0fffff;
       end
       7'b0010000: begin
           start_a = `A_BIT'h100000; end_a = `A_BIT'h10ffff;
       end
       7'b0010001: begin
           start_a = `A_BIT'h110000; end_a = `A_BIT'h11ffff;
       end
       7'b0010010: begin
           start_a = `A_BIT'h120000; end_a = `A_BIT'h12ffff;
       end
       7'b0010011: begin
           start_a = `A_BIT'h130000; end_a = `A_BIT'h13ffff;
       end
       7'b0010100: begin
           start_a = `A_BIT'h140000; end_a = `A_BIT'h14ffff;
       end
       7'b0010101: begin
           start_a = `A_BIT'h150000; end_a = `A_BIT'h15ffff;
       end
       7'b0010110: begin
           start_a = `A_BIT'h160000; end_a = `A_BIT'h16ffff;
       end
       7'b0010111: begin
           start_a = `A_BIT'h170000; end_a = `A_BIT'h17ffff;
       end
       7'b0011000: begin
           start_a = `A_BIT'h180000; end_a = `A_BIT'h18ffff;
       end
       7'b0011001: begin
           start_a = `A_BIT'h190000; end_a = `A_BIT'h19ffff;
       end
       7'b0011010: begin
           start_a = `A_BIT'h1a0000; end_a = `A_BIT'h1affff;
       end
       7'b0011011: begin
           start_a = `A_BIT'h1b0000; end_a = `A_BIT'h1bffff;
       end
       7'b0011100: begin
           start_a = `A_BIT'h1c0000; end_a = `A_BIT'h1cffff;
       end
       7'b0011101: begin
           start_a = `A_BIT'h1d0000; end_a = `A_BIT'h1dffff;
       end
       7'b0011110: begin
           start_a = `A_BIT'h1e0000; end_a = `A_BIT'h1effff;
       end
       7'b0011111: begin
           start_a = `A_BIT'h1f0000; end_a = `A_BIT'h1fffff;
       end
       7'b0100000: begin
           start_a = `A_BIT'h200000; end_a = `A_BIT'h20ffff;
       end
       7'b0100001: begin
           start_a = `A_BIT'h210000; end_a = `A_BIT'h21ffff;
       end
       7'b0100010: begin
           start_a = `A_BIT'h220000; end_a = `A_BIT'h22ffff;
       end
       7'b0100011: begin
           start_a = `A_BIT'h230000; end_a = `A_BIT'h23ffff;
       end
       7'b0100100: begin
           start_a = `A_BIT'h240000; end_a = `A_BIT'h24ffff;
       end
       7'b0100101: begin
           start_a = `A_BIT'h250000; end_a = `A_BIT'h25ffff;
       end
       7'b0100110: begin
           start_a = `A_BIT'h260000; end_a = `A_BIT'h26ffff;
       end
       7'b0100111: begin
           start_a = `A_BIT'h270000; end_a = `A_BIT'h27ffff;
       end
       7'b0101000: begin
           start_a = `A_BIT'h280000; end_a = `A_BIT'h28ffff;
       end
       7'b0101001: begin
           start_a = `A_BIT'h290000; end_a = `A_BIT'h29ffff;
       end
       7'b0101010: begin
           start_a = `A_BIT'h2a0000; end_a = `A_BIT'h2affff;
       end
       7'b0101011: begin
           start_a = `A_BIT'h2b0000; end_a = `A_BIT'h2bffff;
       end
       7'b0101100: begin
           start_a = `A_BIT'h2c0000; end_a = `A_BIT'h2cffff;
       end
       7'b0101101: begin
           start_a = `A_BIT'h2d0000; end_a = `A_BIT'h2dffff;
       end
       7'b0101110: begin
           start_a = `A_BIT'h2e0000; end_a = `A_BIT'h2effff;
       end
       7'b0101111: begin
           start_a = `A_BIT'h2f0000; end_a = `A_BIT'h2fffff;
       end
       7'b0110000: begin
           start_a = `A_BIT'h300000; end_a = `A_BIT'h30ffff;
       end
       7'b0110001: begin
           start_a = `A_BIT'h310000; end_a = `A_BIT'h31ffff;
       end
       7'b0110010: begin
           start_a = `A_BIT'h320000; end_a = `A_BIT'h32ffff;
       end
       7'b0110011: begin
           start_a = `A_BIT'h330000; end_a = `A_BIT'h33ffff;
       end
       7'b0110100: begin
           start_a = `A_BIT'h340000; end_a = `A_BIT'h34ffff;
       end
       7'b0110101: begin
           start_a = `A_BIT'h350000; end_a = `A_BIT'h35ffff;
       end
       7'b0110110: begin
           start_a = `A_BIT'h360000; end_a = `A_BIT'h36ffff;
       end
       7'b0110111: begin
           start_a = `A_BIT'h370000; end_a = `A_BIT'h37ffff;
       end
       7'b0111000: begin
           start_a = `A_BIT'h380000; end_a = `A_BIT'h38ffff;
       end
       7'b0111001: begin
           start_a = `A_BIT'h390000; end_a = `A_BIT'h39ffff;
       end
       7'b0111010: begin
           start_a = `A_BIT'h3a0000; end_a = `A_BIT'h3affff;
       end
       7'b0111011: begin
           start_a = `A_BIT'h3b0000; end_a = `A_BIT'h3bffff;
       end
       7'b0111100: begin
           start_a = `A_BIT'h3c0000; end_a = `A_BIT'h3cffff;
       end
       7'b0111101: begin
           start_a = `A_BIT'h3d0000; end_a = `A_BIT'h3dffff;
       end
       7'b0111110: begin
           start_a = `A_BIT'h3e0000; end_a = `A_BIT'h3effff;
       end
       7'b0111111: begin
           start_a = `A_BIT'h3f0000; end_a = `A_BIT'h3fffff;
       end
       7'b1000000: begin
           start_a = `A_BIT'h400000; end_a = `A_BIT'h40ffff;
       end
       7'b1000001: begin
           start_a = `A_BIT'h410000; end_a = `A_BIT'h41ffff;
       end
       7'b1000010: begin
           start_a = `A_BIT'h420000; end_a = `A_BIT'h42ffff;
       end
       7'b1000011: begin
           start_a = `A_BIT'h430000; end_a = `A_BIT'h43ffff;
       end
       7'b1000100: begin
           start_a = `A_BIT'h440000; end_a = `A_BIT'h44ffff;
       end
       7'b1000101: begin
           start_a = `A_BIT'h450000; end_a = `A_BIT'h45ffff;
       end
       7'b1000110: begin
           start_a = `A_BIT'h460000; end_a = `A_BIT'h46ffff;
       end
       7'b1000111: begin
           start_a = `A_BIT'h470000; end_a = `A_BIT'h47ffff;
       end
       7'b1001000: begin
           start_a = `A_BIT'h480000; end_a = `A_BIT'h48ffff;
       end
       7'b1001001: begin
           start_a = `A_BIT'h490000; end_a = `A_BIT'h49ffff;
       end
       7'b1001010: begin
           start_a = `A_BIT'h4a0000; end_a = `A_BIT'h4affff;
       end
       7'b1001011: begin
           start_a = `A_BIT'h4b0000; end_a = `A_BIT'h4bffff;
       end
       7'b1001100: begin
           start_a = `A_BIT'h4c0000; end_a = `A_BIT'h4cffff;
       end
       7'b1001101: begin
           start_a = `A_BIT'h4d0000; end_a = `A_BIT'h4dffff;
       end
       7'b1001110: begin
           start_a = `A_BIT'h4e0000; end_a = `A_BIT'h4effff;
       end
       7'b1001111: begin
           start_a = `A_BIT'h4f0000; end_a = `A_BIT'h4fffff;
       end
       7'b1010000: begin
           start_a = `A_BIT'h500000; end_a = `A_BIT'h50ffff;
       end
       7'b1010001: begin
           start_a = `A_BIT'h510000; end_a = `A_BIT'h51ffff;
       end
       7'b1010010: begin
           start_a = `A_BIT'h520000; end_a = `A_BIT'h52ffff;
       end
       7'b1010011: begin
           start_a = `A_BIT'h530000; end_a = `A_BIT'h53ffff;
       end
       7'b1010100: begin
           start_a = `A_BIT'h540000; end_a = `A_BIT'h54ffff;
       end
       7'b1010101: begin
           start_a = `A_BIT'h550000; end_a = `A_BIT'h55ffff;
       end
       7'b1010110: begin
           start_a = `A_BIT'h560000; end_a = `A_BIT'h56ffff;
       end
       7'b1010111: begin
           start_a = `A_BIT'h570000; end_a = `A_BIT'h57ffff;
       end
       7'b1011000: begin
           start_a = `A_BIT'h580000; end_a = `A_BIT'h58ffff;
       end
       7'b1011001: begin
           start_a = `A_BIT'h590000; end_a = `A_BIT'h59ffff;
       end
       7'b1011010: begin
           start_a = `A_BIT'h5a0000; end_a = `A_BIT'h5affff;
       end
       7'b1011011: begin
           start_a = `A_BIT'h5b0000; end_a = `A_BIT'h5bffff;
       end
       7'b1011100: begin
           start_a = `A_BIT'h5c0000; end_a = `A_BIT'h5cffff;
       end
       7'b1011101: begin
           start_a = `A_BIT'h5d0000; end_a = `A_BIT'h5dffff;
       end
       7'b1011110: begin
           start_a = `A_BIT'h5e0000; end_a = `A_BIT'h5effff;
       end
       7'b1011111: begin
           start_a = `A_BIT'h5f0000; end_a = `A_BIT'h5fffff;
       end
       7'b1100000: begin
           start_a = `A_BIT'h600000; end_a = `A_BIT'h60ffff;
       end
       7'b1100001: begin
           start_a = `A_BIT'h610000; end_a = `A_BIT'h61ffff;
       end
       7'b1100010: begin
           start_a = `A_BIT'h620000; end_a = `A_BIT'h62ffff;
       end
       7'b1100011: begin
           start_a = `A_BIT'h630000; end_a = `A_BIT'h63ffff;
       end
       7'b1100100: begin
           start_a = `A_BIT'h640000; end_a = `A_BIT'h64ffff;
       end
       7'b1100101: begin
           start_a = `A_BIT'h650000; end_a = `A_BIT'h65ffff;
       end
       7'b1100110: begin
           start_a = `A_BIT'h660000; end_a = `A_BIT'h66ffff;
       end
       7'b1100111: begin
           start_a = `A_BIT'h670000; end_a = `A_BIT'h67ffff;
       end
       7'b1101000: begin
           start_a = `A_BIT'h680000; end_a = `A_BIT'h68ffff;
       end
       7'b1101001: begin
           start_a = `A_BIT'h690000; end_a = `A_BIT'h69ffff;
       end
       7'b1101010: begin
           start_a = `A_BIT'h6a0000; end_a = `A_BIT'h6affff;
       end
       7'b1101011: begin
           start_a = `A_BIT'h6b0000; end_a = `A_BIT'h6bffff;
       end
       7'b1101100: begin
           start_a = `A_BIT'h6c0000; end_a = `A_BIT'h6cffff;
       end
       7'b1101101: begin
           start_a = `A_BIT'h6d0000; end_a = `A_BIT'h6dffff;
       end
       7'b1101110: begin
           start_a = `A_BIT'h6e0000; end_a = `A_BIT'h6effff;
       end
       7'b1101111: begin
           start_a = `A_BIT'h6f0000; end_a = `A_BIT'h6fffff;
       end
       7'b1110000: begin
           start_a = `A_BIT'h700000; end_a = `A_BIT'h70ffff;
       end
       7'b1110001: begin
           start_a = `A_BIT'h710000; end_a = `A_BIT'h71ffff;
       end
       7'b1110010: begin
           start_a = `A_BIT'h720000; end_a = `A_BIT'h72ffff;
       end
       7'b1110011: begin
           start_a = `A_BIT'h730000; end_a = `A_BIT'h73ffff;
       end
       7'b1110100: begin
           start_a = `A_BIT'h740000; end_a = `A_BIT'h74ffff;
       end
       7'b1110101: begin
           start_a = `A_BIT'h750000; end_a = `A_BIT'h75ffff;
       end
       7'b1110110: begin
           start_a = `A_BIT'h760000; end_a = `A_BIT'h76ffff;
       end
       7'b1110111: begin
           start_a = `A_BIT'h770000; end_a = `A_BIT'h77ffff;
       end
       7'b1111000: begin
           start_a = `A_BIT'h780000; end_a = `A_BIT'h78ffff;
       end
       7'b1111001: begin
           start_a = `A_BIT'h790000; end_a = `A_BIT'h79ffff;
       end
       7'b1111010: begin
           start_a = `A_BIT'h7a0000; end_a = `A_BIT'h7affff;
       end
       7'b1111011: begin
           start_a = `A_BIT'h7b0000; end_a = `A_BIT'h7bffff;
       end
       7'b1111100: begin
           start_a = `A_BIT'h7c0000; end_a = `A_BIT'h7cffff;
       end
       7'b1111101: begin
           start_a = `A_BIT'h7d0000; end_a = `A_BIT'h7dffff;
       end
       7'b1111110: begin
           start_a = `A_BIT'h7e0000; end_a = `A_BIT'h7effff;
       end

       7'b1111111: begin
           case( sector[2:0] )
               3'b000: begin
                   start_a = `A_BIT'h7f0000; end_a = `A_BIT'h7f1fff;
               end
               3'b001: begin
                   start_a = `A_BIT'h7f2000; end_a = `A_BIT'h7f3fff;
               end
               3'b010: begin
                   start_a = `A_BIT'h7f4000; end_a = `A_BIT'h7f5fff;
               end
               3'b011: begin
                   start_a = `A_BIT'h7f6000; end_a = `A_BIT'h7f7fff;
               end
               3'b100: begin
                   start_a = `A_BIT'h7f8000; end_a = `A_BIT'h7f9fff;
               end
               3'b101: begin
                   start_a = `A_BIT'h7fa000; end_a = `A_BIT'h7fbfff;
               end
               3'b110: begin
                   start_a = `A_BIT'h7fc000; end_a = `A_BIT'h7fdfff;
               end
               3'b111: begin
                   start_a = `A_BIT'h7fe000; end_a = `A_BIT'h7fffff;
               end
           endcase
       end
    endcase

    for( i = start_a; i <= end_a; i = i+1 ) begin
        array[ i ] = 8'bxxxxxxxx;   // set unknown first
    end

    during_erase = 1'b1;
    // Initailize Erase Operation Status
    //---------------------------------------------
    er_latch_Q[ 7 ] = 1'b0;
    er_latch_Q[ 6 ] = latch_Q[6];  // will be toggled
    er_latch_Q[ 5 ] = 1'b0;
    er_latch_Q[ 3 ] = 1'b1;
    er_latch_Q[ 2 ] = latch_Q[2];  // will be toggled

    RYBY_B = 1'b0;
    $display($stime, " Sector Erase  Address %h - %h (Word) ...",
                       (start_a >> 1), (end_a>>1));

    // Enter Erase Operation 
    //---------------------------------------------
    fork
        er_timer;
        begin
            #1;
            for( i = 0; i < ers_count; i = i+1 ) begin
                @( posedge ers_clk or negedge hw_reset_b or
                   posedge suspend_flag );
                if ( hw_reset_b == 1'b0 ) i = ers_count;  // terminate
                if ( suspend_flag == 1'b1 ) begin
                    RYBY_B = 1'b1;
                    during_erase = 1'b0;
                    suspend_erase;
                    $display($stime, " Resume Sector Erase ...");
                    during_erase = 1'b1;
                    RYBY_B = 1'b0;
                end
            end
            if ( hw_reset_b == 1'b1 ) begin // No Reset. Finish completly
                for( i = start_a; i <= end_a; i = i+1 ) begin
                    array[ i ] = 8'hff;
                end
            end
            // else leave array [ A ] unknow
            disable er_timer;
        end
    join

    RYBY_B = 1'b1;
    during_erase = 1'b0;

end
endtask

/*---------------------------------------------------------------*/
/*  Description: define a sector erase suspend task              */
/*---------------------------------------------------------------*/
task suspend_erase;
begin

    $display($stime, " Suspend Sector Erase ...");
    state = cycle1;

    forever
    begin
        during_susp_read = 1'b1;

        @( posedge program or negedge hw_reset_b or posedge resume_flag );

        if ( hw_reset_b == 1'b0 ) begin
            RYBY_B = 1'b1;
            during_erase = 1'b0;
            during_susp_read = 1'b0;
            disable sec_erase;
        end
        else if ( resume_flag == 1'b1 ) begin
            during_susp_read = 1'b0;
            disable suspend_erase;
        end
        else begin
            during_susp_read = 1'b0;
            RYBY_B = 1'b0;

            case ( state )
                cycle1: begin
                    case ( cmd_bus )
                        cyc1_w_cmd: state = cyc2_w;
                        cyc1_b_cmd: state = cyc2_b;
                        default:    state = cycle1;
                    endcase
                end
                cyc2_w: state = (cmd_bus==cyc2_w_cmd) ? cyc3_w : cycle1;
                cyc2_b: state = (cmd_bus==cyc2_b_cmd) ? cyc3_b : cycle1;
                cyc3_w: state = (cmd_bus==pgm3_w_cmd) ? pgm4_w : cycle1;
                cyc3_b: state = (cmd_bus==pgm3_b_cmd) ? pgm4_b : cycle1;
                pgm4_w: begin
                    latch_A = A;
                    latch_Q = Q;
                    pgw_count_down;
                    state = cycle1;
                end
                pgm4_b: begin
                    latch_A = { A, Q[15] };
                    latch_Q = { Q[7:0] };
                    pgb_count_down;
                    state = cycle1;
                end
                default: begin
                    state = cycle1;
                end
            endcase
        end
    end
end
endtask

/*---------------------------------------------------------------*/
/*  Description: define actions after entering security sector   */
/*---------------------------------------------------------------*/
task enter_sec_region;
begin

    $display($stime, " Enter Security Sector ...");

    // during_sec_region = 1'b1;
    state = cycle1;

    forever
    begin
        @( posedge program or negedge hw_reset_b );

        if ( hw_reset_b == 1'b0 ) begin
            disable enter_sec_region;
        end
        else begin
            case ( state )
                cycle1: begin
                    case ( cmd_bus )
                        cyc1_w_cmd: state = cyc2_w;
                        cyc1_b_cmd: state = cyc2_b;
                        default:    state = cycle1;
                    endcase
                end
                cyc2_w: state = (cmd_bus==cyc2_w_cmd)? cyc3_w : cycle1;
                cyc2_b: state = (cmd_bus==cyc2_b_cmd)? cyc3_b : cycle1;
                cyc3_w: state = (cmd_bus==ext3_w_cmd)? ext4_w : cycle1;
                cyc3_b: state = (cmd_bus==ext3_b_cmd)? ext4_b : cycle1;
                ext4_w: begin
                    if ( Q[ 7:0 ] == 8'h00 ) begin
                        $display($stime, " Exit Security Sector ...");
                        disable enter_sec_region;
                    end
                    state = cycle1;
                end
                ext4_w: begin
                    if ( Q[ 7:0 ] == 8'h00 ) begin
                        $display($stime, " Exit Security Sector ...");
                        disable enter_sec_region;
                    end
                    state = cycle1;
                end
                default: begin
                    state = cycle1;
                end
            endcase
        end
    end
end
endtask

/*---------------------------------------------------------------*/
/*  Description: define a timer to count program time            */
/*---------------------------------------------------------------*/
task pg_timer;
begin
    pgm_clk = 1'b0;
    forever begin
        #cd_cyc pgm_clk = ~pgm_clk;
    end
end
endtask

/*---------------------------------------------------------------*/
/*  Description: define a timer to count erase time              */
/*---------------------------------------------------------------*/
task er_timer;
begin
    ers_clk = 1'b0;
    forever begin
        #cd_cyc ers_clk = ~ers_clk;
    end
end
endtask

function [15:0] cfi_table;
input [7:0] addr;
begin
    case ( addr )
        8'h10: cfi_table = 16'h0051;
        8'h11: cfi_table = 16'h0052;
        8'h12: cfi_table = 16'h0059;
        8'h13: cfi_table = 16'h0002;
        8'h14: cfi_table = 16'h0000;
        8'h15: cfi_table = 16'h0040;
        8'h16: cfi_table = 16'h0000;
        8'h17: cfi_table = 16'h0000;
        8'h18: cfi_table = 16'h0000;
        8'h19: cfi_table = 16'h0000;
        8'h1a: cfi_table = 16'h0000;
        8'h1b: cfi_table = 16'h0030;
        8'h1c: cfi_table = 16'h0036;
        8'h1d: cfi_table = 16'h0000;
        8'h1e: cfi_table = 16'h0000;
        8'h1f: cfi_table = 16'h0005;
        8'h20: cfi_table = 16'h0000;
        8'h21: cfi_table = 16'h0008;
        8'h22: cfi_table = 16'h0008;
        8'h23: cfi_table = 16'h0000;
        8'h24: cfi_table = 16'h0000;
        8'h25: cfi_table = 16'h0004;
        8'h26: cfi_table = 16'h0000;
        8'h27: cfi_table = 16'h0025;
        8'h28: cfi_table = 16'h0002;
        8'h29: cfi_table = 16'h0000;
        8'h2a: cfi_table = 16'h0000;
        8'h2b: cfi_table = 16'h0000;
        8'h2c: cfi_table = 16'h0002;
        8'h2d: cfi_table = 16'h001f;
        8'h2e: cfi_table = 16'h0000;
        8'h2f: cfi_table = 16'h0000;
        8'h30: cfi_table = 16'h0002;
        8'h31: cfi_table = 16'h0000;
        8'h32: cfi_table = 16'h0000;
        8'h33: cfi_table = 16'h0000;
        8'h34: cfi_table = 16'h0000;
        8'h35: cfi_table = 16'h0000;
        8'h36: cfi_table = 16'h0000;
        8'h37: cfi_table = 16'h0000;
        8'h38: cfi_table = 16'h0000;
        8'h39: cfi_table = 16'h0000;
        8'h3a: cfi_table = 16'h0000;
        8'h3b: cfi_table = 16'h0000;
        8'h3c: cfi_table = 16'h0000;
        8'h40: cfi_table = 16'h0050;
        8'h41: cfi_table = 16'h0052;
        8'h42: cfi_table = 16'h0049;
        8'h43: cfi_table = 16'h0031;
        8'h44: cfi_table = 16'h0030;
        8'h45: cfi_table = 16'h0000;
        8'h46: cfi_table = 16'h0002;
        8'h47: cfi_table = 16'h0001;
        8'h48: cfi_table = 16'h0001;
        8'h49: cfi_table = 16'h0000;
        8'h4a: cfi_table = 16'h0000;
        8'h4b: cfi_table = 16'h0000;
        8'h4c: cfi_table = 16'h0000;
        8'h4d: cfi_table = 16'h00b5;
        8'h4e: cfi_table = 16'h00c5;
        8'h4f: cfi_table = 16'h0003;
        default: cfi_table = 16'h0000;
    endcase
end
endfunction

`endprotect
endmodule
