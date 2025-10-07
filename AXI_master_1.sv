
`timescale 1 ns / 1 ps

module AXI_MASTER_IF #(
    parameter ADDR_WIDTH = 32  ,
    parameter DATA_WIDTH = 16 ,
		parameter AXI_WIDTH = 256,
    parameter INOUT_WIDTH= 256 ,
    parameter ID_WIDTH   = 4   ,
    parameter LEN_WIDTH  = 8 ,

  	parameter BURST_LEN_R = 255,
  	parameter BURST_LEN_W = 255

)(
    input                       ACLK   ,
    input                       ARESETN,

    // Control from CNN IP
    input  [AXI_WIDTH-1:0]      WDATA_IN  ,
    output reg                  BUSY_R    ,
    output reg                  BUSY_W    ,

    //---------------------------------
    // AXI4 Master Interface
    //---------------------------------

    // Write address channel
    output reg [ID_WIDTH-1:0]   M_AXI_AWID    ,
    output reg [ADDR_WIDTH-1:0] M_AXI_AWADDR  ,
    output reg [LEN_WIDTH-1:0]  M_AXI_AWLEN   , 
    output reg [2:0]            M_AXI_AWSIZE  , 
    output reg [1:0]            M_AXI_AWBURST , 
    output reg                  M_AXI_AWVALID ,
    input                       M_AXI_AWREADY ,

    // Write data channel
    output reg [AXI_WIDTH-1:0]      M_AXI_WDATA     ,
    output reg [(AXI_WIDTH/8)-1:0]  M_AXI_WSTRB     ,
    output reg                      M_AXI_WLAST     ,
    output reg                      M_AXI_WVALID    ,
    input                           M_AXI_WREADY    ,

    // Write response channel
    input  [1:0]                M_AXI_BRESP  ,
    input                       M_AXI_BVALID ,
    output reg                  M_AXI_BREADY ,

    // Read address channel
    output reg [ID_WIDTH-1:0]   M_AXI_ARID    ,
    output reg [ADDR_WIDTH-1:0] M_AXI_ARADDR  ,
    output reg [LEN_WIDTH-1:0]  M_AXI_ARLEN   ,
    output reg [2:0]            M_AXI_ARSIZE  ,
    output reg [1:0]            M_AXI_ARBURST ,
    output reg                  M_AXI_ARVALID ,
    input                       M_AXI_ARREADY ,

    // Read data channel
    input  [AXI_WIDTH-1:0]      M_AXI_RDATA  ,
    input  [1:0]                M_AXI_RRESP  ,
    input                       M_AXI_RLAST  ,
    input                       M_AXI_RVALID ,
    output reg                  M_AXI_RREADY ,
    input                       start_read   ,
    input [8:0]                 ifm_size     ,
		input                       read_fifo_ifm    ,
		input [8:0] ofm_size,
	  input write,
  	input [10:0] num_filter,
	  output reg done,
  	output reg start_CNN,
    output wire [AXI_WIDTH - 1:0] data_fifo_o

);
	localparam NUM_TRANS = 338;
  reg [LEN_WIDTH-1:0] beat_cnt_r;
  reg [LEN_WIDTH-1:0] beat_cnt_w;

	reg read_fifo;
  typedef enum logic [2:0] {
      IDLE_READ  ,
      READ_ADDR  ,
      READ_DATA  ,
			UPDATE_ADDR,
			END_READ  
  } state_r;
  typedef enum logic [2:0] {
      IDLE_WRITE  ,
      WRITE_ADDR  ,
			WRITE_DATA,
		  READ_FIFO,
		  DONE_LAYER,
			WRITE_RESP  
  } state_w;
	state_r c_state_r, next_state_r;
	state_w c_state_w, next_state_w;
	reg [AXI_WIDTH-1:0] ofm;
	reg [ADDR_WIDTH-1:0] addr;
wire [ADDR_WIDTH - 1:0] addr_o_fifo;
wire [ ADDR_WIDTH - 1 :0 ] addr_ofm;
wire [AXI_WIDTH - 1:0] data_o_fifo;
	reg [31:0] m_axi_araddr_1;
	reg [19:0] cnt_ifm;
	reg [8:0] cnt_trans;
	wire end_layer_1;
	localparam IFM_TILING = 10816 * 27; 
	localparam FIFO_SIZE = 1536;
	localparam BASE_ADDR_OFM = 10816 * 27 + 1;

	reg [ADDR_WIDTH-1:0] m_axi_araddr_4; 
	assign addr_ofm = m_axi_araddr_4 ;
    always @(posedge ACLK or negedge ARESETN) begin
			if (!ARESETN) begin
            c_state_r <= IDLE_READ;
            c_state_w <= IDLE_WRITE;
			end else begin
				c_state_r <= next_state_r;
				c_state_w <= next_state_w;
			end
		end
	always @(posedge ACLK or negedge ARESETN) begin
		if(~ARESETN) begin
			cnt_trans <= 0;
		end else begin
			cnt_trans <= (M_AXI_BVALID)? cnt_trans + 1 : cnt_trans;
		end
	end

	always @(*) begin
		if(M_AXI_AWVALID) begin
			ofm  = data_o_fifo ;
      addr = addr_o_fifo   ;
		end
	end
	reg M_AXI_WREADY_reg ;
	always @(posedge ACLK) begin
		M_AXI_WREADY_reg <= M_AXI_WREADY;
	end

    always @(*) begin
        next_state_w    = c_state_w              ;
        BUSY_W          = 1'b1                   ;
        M_AXI_AWVALID   = 0                      ;
        M_AXI_WVALID    = 0                      ;
        M_AXI_WLAST     = 0                      ;
        M_AXI_BREADY    = 0                      ;
        M_AXI_WSTRB     = {(AXI_WIDTH/8){1'b1}} ;

        // Address/control signals
        M_AXI_AWID      = 0                  ;
        M_AXI_AWLEN     = BURST_LEN_W         ;
        M_AXI_AWSIZE    = $clog2(AXI_WIDTH/8) ;
        M_AXI_AWBURST   = 2'b01               ;
        M_AXI_AWADDR    = m_axi_araddr_4  + BASE_ADDR_OFM               ;
        M_AXI_WDATA     = data_o_fifo                 ;
			  read_fifo = 0;
			  done = 0;
        case (c_state_w)
            IDLE_WRITE: begin
            	BUSY_W = 0;
              if ((fifo_ofm.cnt >= 256) && (cnt_trans < NUM_TRANS)) next_state_w = READ_FIFO;
							else if(cnt_trans == NUM_TRANS) next_state_w = DONE_LAYER; 
            end
					READ_FIFO: begin
						read_fifo = 1;
						next_state_w = WRITE_ADDR;
					end
            WRITE_ADDR: begin
            	M_AXI_AWVALID = 1;
              if (M_AXI_AWREADY)
              	next_state_w = WRITE_DATA;
            end
            WRITE_DATA: begin
            	M_AXI_WVALID = 1;
			  			read_fifo    = (M_AXI_WREADY) && (beat_cnt_w < BURST_LEN_W);
            	M_AXI_WLAST  = (beat_cnt_w == BURST_LEN_W);
							if (M_AXI_WLAST) begin
              	next_state_w = WRITE_RESP;
							end else  begin
              	next_state_w = WRITE_DATA;
							end
            end

            WRITE_RESP: begin
            	M_AXI_BREADY = 1;
              if (M_AXI_BVALID)
              	next_state_w = IDLE_WRITE;
            end
				  	DONE_LAYER: begin
              	next_state_w = IDLE_WRITE;
								done = 1;
						end
				endcase
		end

	always @(posedge ACLK or negedge ARESETN) begin
		if(~ARESETN) begin
			m_axi_araddr_4 <= 0;
		end else begin
			m_axi_araddr_4 <= (M_AXI_BVALID) ? m_axi_araddr_4 + BURST_LEN_W + 1 : m_axi_araddr_4;
    end
  end

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN)
            beat_cnt_w <= 0;
        else begin
            case (c_state_w)
              WRITE_DATA:  beat_cnt_w <= (M_AXI_WREADY) ? (beat_cnt_w == BURST_LEN_W) ? 0 :  beat_cnt_w + 1 : beat_cnt_w ;
                default   : beat_cnt_w <= beat_cnt_w;
            endcase
        end
    end

    always @(posedge ACLK or negedge ARESETN) begin
			if (!ARESETN) begin
					cnt_ifm <= 0;
			end else begin
					cnt_ifm <= (M_AXI_RVALID) ? cnt_ifm + 1 : cnt_ifm;
			end
		end


    // Beat counter
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN)
            beat_cnt_r <= 0;
        else begin
            case (c_state_r)
              READ_DATA : if (M_AXI_RVALID && M_AXI_RREADY) beat_cnt_r <= (beat_cnt_r == BURST_LEN_R) ? 0:  beat_cnt_r + 1;
                default   : beat_cnt_r <= 0;
            endcase
        end
    end

    always @(*) begin
        // defaults
//        next_state_r    = c_state_r ;
        BUSY_R          = 1'b1      ;
        M_AXI_ARVALID   = 0         ; 
        M_AXI_RREADY    = 0         ;
        M_AXI_ARID      = 0                  ;
        M_AXI_ARLEN     = BURST_LEN_R         ;
        M_AXI_ARSIZE    = $clog2(AXI_WIDTH/8) ;
        M_AXI_ARBURST   = 2'b01               ;
			  start_CNN       = 0                     ;
        case (c_state_r)
            IDLE_READ: begin
                BUSY_R = 0;
                  if (fifo_ifm.cnt < (FIFO_SIZE - BURST_LEN_R)) next_state_r = READ_ADDR;
									else next_state_r = IDLE_READ;
            end
            READ_ADDR: begin
                M_AXI_ARVALID = 1;
                if (M_AXI_ARREADY)
                    next_state_r = READ_DATA;
            end
            READ_DATA: begin
                M_AXI_RREADY = 1;
							start_CNN = (cnt_ifm == 2*BURST_LEN_R) ? 1 : 0;
                if (M_AXI_RVALID) begin
       //             RDATA_OUT = M_AXI_RDATA;
									if (M_AXI_RLAST) begin 
                        next_state_r = UPDATE_ADDR;
										end else if (M_AXI_RLAST  && (cnt_ifm == IFM_TILING)) begin 
                        next_state_r = END_READ;
									end else if(M_AXI_RLAST) begin
                    next_state_r = IDLE_READ;
									end
							end
             end
					UPDATE_ADDR: 
						next_state_r = IDLE_READ;
					END_READ: begin
						next_state_r = IDLE_READ;
					end
        endcase
    end

	always @(posedge ACLK or negedge ARESETN) begin
		if(!ARESETN) begin
			m_axi_araddr_1 <= 0; 
			M_AXI_ARADDR <= 0;
		end else begin
			M_AXI_ARADDR <= m_axi_araddr_1; 
		end
	end

	always @(posedge ACLK or negedge ARESETN) begin
		if(~ARESETN) begin
			m_axi_araddr_1 <= 0;
		end else begin
			m_axi_araddr_1 <= (c_state_r == UPDATE_ADDR) ? m_axi_araddr_1 + BURST_LEN_R+1 : m_axi_araddr_1;
		end
	end

	wire full,full_ifm;
	wire empty,empty_ifm;

 FIFO_OFM #(
	.DATA_WIDTH (256   ), 
	.FIFO_SIZE  (FIFO_SIZE )
) fifo_ifm (
	.clk          (ACLK          ) ,
	.rst_n        (ARESETN       ) ,
	.rd_clr       (1'b0          ) ,
	.wr_clr       (1'b0          ) ,
	.rd_en        (read_fifo_ifm ) ,
	.wr_en        (M_AXI_RVALID  ) ,
	.data_in_fifo (M_AXI_RDATA   ) ,
	.data_out_fifo(data_fifo_o   ) ,
	.empty        (empty_ifm         ) ,
	.full         (full_ifm          )
);


 FIFO_OFM #(
	.DATA_WIDTH (AXI_WIDTH  ), 
	.FIFO_SIZE  (2000 )
) fifo_ofm (
	.clk          (ACLK          ) ,
	.rst_n        (ARESETN       ) ,
	.rd_clr       (rd_clr        ) ,
	.wr_clr       (wr_clr        ) ,
	.rd_en        (read_fifo     ) ,
	.wr_en        (write         ) ,
	.data_in_fifo (WDATA_IN      ) ,
	.data_out_fifo(data_o_fifo   ) ,
	.empty        (empty         ) ,
	.full         (full          )
);

endmodule
