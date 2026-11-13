// FM savestate transport buffer. Exactly one synchronous 256 x 32 M10K.
// Live OPLL state is read/written locally; this is not a parallel shadow bank.
module opll_snapshot (
    input clk, reset_n,
    input capture, apply_state, legacy,
    input initialized,
    output legacy_reset, initialization_run,
    input bulk_read, bulk_write,
    input [6:0] bulk_addr,
    input [63:0] bulk_wdata,
    output reg [63:0] bulk_rdata,
    output reg done,
    output busy,
    output [7:0] state_addr,
    output state_read, state_write,
    output [31:0] state_wdata,
    input [31:0] state_rdata
);
    localparam WORDS=100;
    localparam IDLE=0,CAP_READ=1,CAP_STORE=2,AP_READ=3,AP_WRITE=4,
               REFILL=5,B_RD_LO=6,B_GET_LO=7,B_RD_HI=8,B_GET_HI=9,
               B_WR_LO=10,B_WR_HI=11,LEG_RESET=12,LEG_INIT=13;
    reg [3:0] state;
    reg [7:0] index;
    reg [3:0] refill_count;
    reg [63:0] incoming;
    reg legacy_mode;
    (* ramstyle = "M10K" *) reg [31:0] memory [0:255];
    reg [31:0] ram_q;
    wire [7:0] ram_addr = (state==B_RD_HI || state==B_GET_HI || state==B_WR_HI) ? index+8'd1 : index;
    wire ram_we = state==CAP_STORE || state==B_WR_LO || state==B_WR_HI;
    wire [31:0] ram_d = state==CAP_STORE ? state_rdata : state==B_WR_LO ? incoming[31:0] : incoming[63:32];
    // No reset on memory or its output: preserve block-RAM inference.
    always @(posedge clk) begin
        if (ram_we) memory[ram_addr] <= ram_d;
        ram_q <= memory[ram_addr];
    end
    assign busy=state!=IDLE;
    assign state_addr=(state==CAP_READ || state==CAP_STORE || state==AP_READ || state==AP_WRITE) ? index : 8'hff;
    assign state_read=state==CAP_READ;
    assign state_write=state==AP_WRITE;
    assign legacy_reset=state==LEG_RESET;
    assign initialization_run=state==LEG_RESET || state==LEG_INIT;
    // Deterministic missing-history fallback is generated from the state map.
    function [31:0] legacy_word;
        input [7:0] address;
        begin
            legacy_word=0;
            case(address)
            // Legacy FM state defaults
            8'd78: legacy_word=32'h47;
            8'd88: legacy_word=32'h8000;
            8'd90: legacy_word=32'h3ffff;


            default: legacy_word=0;
            endcase
        end
    endfunction
    assign state_wdata=legacy_mode?legacy_word(index):ram_q;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin state<=IDLE;index<=0;done<=0;refill_count<=0;incoming<=0;bulk_rdata<=0;legacy_mode<=0;end
        else begin
            done<=0;
            case(state)
            IDLE: begin
                if(capture) begin index<=0;legacy_mode<=0;state<=CAP_READ;end
                else if(apply_state) begin index<=0;legacy_mode<=0;state<=AP_READ;end
                else if(legacy) begin legacy_mode<=1;state<=LEG_RESET;end
                else if(bulk_read) begin index<={bulk_addr,1'b0};state<=B_RD_LO;end
                else if(bulk_write) begin index<={bulk_addr,1'b0};incoming<=bulk_wdata;state<=B_WR_LO;end
            end
            CAP_READ: state<=CAP_STORE;
            CAP_STORE: if(index==WORDS-1)begin state<=IDLE;done<=1;end
                       else begin index<=index+8'd1;state<=CAP_READ;end
            AP_READ: state<=AP_WRITE;
            AP_WRITE: if(index==WORDS-1)begin refill_count<=0;state<=REFILL;end
                      else begin index<=index+8'd1;state<=AP_READ;end
            REFILL: if(refill_count==7)begin state<=IDLE;done<=1;end else refill_count<=refill_count+4'd1;
            B_RD_LO: state<=B_GET_LO;
            B_GET_LO: begin bulk_rdata[31:0]<=ram_q;state<=B_RD_HI;end
            B_RD_HI: state<=B_GET_HI;
            B_GET_HI: begin bulk_rdata[63:32]<=ram_q;state<=IDLE;done<=1;end
            B_WR_LO: state<=B_WR_HI;
            B_WR_HI: begin state<=IDLE;done<=1;end
            LEG_RESET: state<=LEG_INIT;
            LEG_INIT: if(initialized)begin index<=76;state<=AP_READ;end
            default: state<=IDLE;
            endcase
        end
    end
endmodule
