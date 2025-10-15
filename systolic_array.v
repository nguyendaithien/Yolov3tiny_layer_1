`timescale 1 ns / 1 ps

	module SYSTOLIC_ARRAY_v1_0_M00_AXI #
	(
		// Users to add parameters here
	parameter SYSTOLIC_SIZE     = 16      ,
	parameter DATA_WIDTH        = 16      ,
	parameter INOUT_WIDTH       = 256     ,
	parameter IFM_RAM_SIZE      = 524172  ,
	parameter WGT_RAM_SIZE      = 5040 ,
	parameter OFM_RAM_SIZE_1    = 2205619 ,
  parameter OFM_RAM_SIZE_2    = 259584  ,
	parameter MAX_WGT_FIFO_SIZE = 4608    ,
	parameter RELU_PARAM        = 0       ,
  parameter Q                 = 9       ,
  parameter NUM_LAYER         = 1       ,

  parameter ID_WIDTH          = 4 ,
  parameter ADDR_WIDTH        = 32,
  parameter LEN_WIDTH         = 8 ,


		// User parameters ends
		// Base address of targeted slave
		parameter  C_M_TARGET_SLAVE_BASE_ADDR  = 32'h40000000,
		parameter integer C_M_AXI_BURST_LEN    = 256,
		parameter integer C_M_AXI_ID_WIDTH     = 4,
		parameter integer C_M_AXI_ADDR_WIDTH   = 32,
		parameter integer C_M_AXI_DATA_WIDTH   = 256,
		parameter integer C_M_AXI_AWUSER_WIDTH = 0,
		parameter integer C_M_AXI_ARUSER_WIDTH = 0,
		parameter integer C_M_AXI_WUSER_WIDTH  = 0,
		parameter integer C_M_AXI_RUSER_WIDTH  = 0,
		parameter integer C_M_AXI_BUSER_WIDTH  = 0
	)
	(
//		input wire  INIT_AXI_TXN, // start transacsison
		output wire  TXN_DONE                                       ,
		output reg  ERROR                                           ,
		input wire  M_AXI_ACLK                                      ,
		input wire  M_AXI_ARESETN                                   ,
		output wire [C_M_AXI_ID_WIDTH-1 : 0         ] M_AXI_AWID    ,
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0       ] M_AXI_AWADDR  ,
		output wire [7 : 0                          ] M_AXI_AWLEN   ,
		output wire [2 : 0                          ] M_AXI_AWSIZE  ,
		output wire [1 : 0                          ] M_AXI_AWBURST ,
		output wire  M_AXI_AWLOCK                                   ,
		output wire [3 : 0                          ] M_AXI_AWCACHE ,
		output wire [2 : 0                          ] M_AXI_AWPROT  ,
		output wire [3 : 0                          ] M_AXI_AWQOS   ,
		output wire [C_M_AXI_AWUSER_WIDTH-1 : 0     ] M_AXI_AWUSER  ,
		output wire  M_AXI_AWVALID                                  ,
		input wire  M_AXI_AWREADY                                   ,
		output wire [C_M_AXI_DATA_WIDTH-1 : 0       ] M_AXI_WDATA   ,
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0     ] M_AXI_WSTRB   ,
		output wire  M_AXI_WLAST                                    ,
		output wire [C_M_AXI_WUSER_WIDTH-1 : 0      ] M_AXI_WUSER   ,
		output wire  M_AXI_WVALID                                   ,
		input wire  M_AXI_WREADY                                    ,
		input wire [C_M_AXI_ID_WIDTH-1 : 0          ] M_AXI_BID     ,
		input wire [1 : 0                           ] M_AXI_BRESP   ,
		input wire [C_M_AXI_BUSER_WIDTH-1 : 0       ] M_AXI_BUSER   ,
		input wire  M_AXI_BVALID                                    ,
		output wire  M_AXI_BREADY                                   ,
		output wire [C_M_AXI_ID_WIDTH-1 : 0         ] M_AXI_ARID    ,
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0       ] M_AXI_ARADDR  ,
		output wire [7 : 0                          ] M_AXI_ARLEN   ,
		output wire [2 : 0                          ] M_AXI_ARSIZE  ,
		output wire [1 : 0                          ] M_AXI_ARBURST ,
		output wire  M_AXI_ARLOCK                                   ,
		output wire [3 : 0                          ] M_AXI_ARCACHE ,
		output wire [2 : 0                          ] M_AXI_ARPROT  ,
		output wire [3 : 0                          ] M_AXI_ARQOS   ,
		output wire [C_M_AXI_ARUSER_WIDTH-1 : 0     ] M_AXI_ARUSER  ,
		output wire  M_AXI_ARVALID                                  ,
		input wire  M_AXI_ARREADY                                   ,
		input wire [C_M_AXI_ID_WIDTH-1 : 0          ] M_AXI_RID     ,
		input wire [C_M_AXI_DATA_WIDTH-1 : 0        ] M_AXI_RDATA   ,
		input wire [1 : 0                           ] M_AXI_RRESP   ,
		input wire  M_AXI_RLAST                                     ,
		input wire [C_M_AXI_RUSER_WIDTH-1 : 0       ] M_AXI_RUSER   ,
		input wire  M_AXI_RVALID                                    ,
		output wire  M_AXI_RREADY                                   ,
		input wire start_read                                       ,
    output wire                   done_wr_layer         
	);
     wire                   start       ;
     wire                   ifm_read_en ;
	   wire                   upsample_mode         ;

     wire [ 8:0]                            ofm_size      ; 
     wire                                   ofm_read_en   ; 
     wire [ $clog2(OFM_RAM_SIZE_1) - 1 : 0] ofm_addr_read ; 
     wire [ INOUT_WIDTH-1:0]                ofm_data_read ; 
     wire                                   ofm_write_en  ; 
     wire [ $clog2(OFM_RAM_SIZE_1) - 1 : 0] ofm_addr_write; 
     wire [10: 0]                           num_filter    ;
	   wire [8:0]                             ifm_size      ; 
     wire [ INOUT_WIDTH-1:0]                ofm_data_write ;

		wire done_CNN;
	

    wire [INOUT_WIDTH-1:0] data_in ;
    wire [3 : 0] count_layer        ;
    wire [8 : 0] ofm_size_conv      ;
    wire [8 : 0] ofm_size_ofm_ram_2 ;
    wire [10: 0] ifm_channel        ;
    wire [1 : 0] kernel_size        ;
    wire         maxpool_mode       ;
    wire [1 : 0] maxpool_stride     ;

    wire [$clog2(OFM_RAM_SIZE_1) - 1 : 0] start_write_addr_1 ;
    wire [$clog2(OFM_RAM_SIZE_1) - 1 : 0] start_read_addr_1  ;
    wire [$clog2(OFM_RAM_SIZE_2) - 1 : 0] start_write_addr_2 ;
    wire [$clog2(OFM_RAM_SIZE_2) - 1 : 0] start_read_addr_2  ;
    wire [17: 0]                          ifm_channel_size   ;
    wire [15: 0]                          ofm_channel_size_1 ;
    wire [$clog2(OFM_RAM_SIZE_1) - 1 : 0] write_addr_incr_1  ;
    wire [4 : 0]                          last_write_size_1  ;
    wire [15: 0]                          ofm_channel_size_2 ;
    wire [$clog2(OFM_RAM_SIZE_2) - 1 : 0] write_addr_incr_2  ;
    wire [4 : 0]                          last_write_size_2  ;


    wire [12: 0] num_cycle_load    ;
    wire [12: 0] num_cycle_compute ;
    wire [6 : 0] num_load_filter   ;
    wire [13: 0] num_tiling	       ;

		wire start_layer;
		wire busy_r;
		wire busy_w;

  // ================= Master =================
  AXI_MASTER_IF #    (
  .ADDR_WIDTH        ( ADDR_WIDTH        ) ,
  .DATA_WIDTH        ( DATA_WIDTH        ) ,
  .ID_WIDTH          ( ID_WIDTH          ) ,
  .INOUT_WIDTH       ( INOUT_WIDTH       ) ,
  .AXI_WIDTH         ( INOUT_WIDTH       ) ,
  .LEN_WIDTH         ( LEN_WIDTH         )
  ) u_master         (
    .ACLK      ( M_AXI_ACLK    ) ,
    .ARESETN   ( M_AXI_ARESETN ) ,
    .WDATA_IN  ( ofm_data_write   ) , // OFM from SA
    .BUSY_R    ( busy_r  ) ,
    .BUSY_W    ( busy_w  ) ,

    // Write address channel
    .M_AXI_AWID           ( M_AXI_AWID        ) ,// slave 
    .M_AXI_AWADDR         ( M_AXI_AWADDR      ) ,// slave
    .M_AXI_AWLEN          ( M_AXI_AWLEN       ) ,// slave
    .M_AXI_AWSIZE         ( M_AXI_AWSIZE      ) ,// slave
    .M_AXI_AWBURST        ( M_AXI_AWBURST     ) ,// slave
    .M_AXI_AWVALID        ( M_AXI_AWVALID     ) ,// slave
    .M_AXI_AWREADY        ( M_AXI_AWREADY     ) ,// slave

    // Write data channel
    .M_AXI_WDATA          ( M_AXI_WDATA   ) ,// slave 
    .M_AXI_WSTRB          ( M_AXI_WSTRB       ) ,// slave
    .M_AXI_WLAST          ( M_AXI_WLAST       ) ,// slave
    .M_AXI_WVALID         ( M_AXI_WVALID      ) ,// slave
    .M_AXI_WREADY         ( M_AXI_WREADY      ) ,// slave

    // Write response
    .M_AXI_BRESP          ( M_AXI_BRESP       ) ,// slave 
    .M_AXI_BVALID         ( M_AXI_BVALID      ) ,// slave
    .M_AXI_BREADY         ( M_AXI_BREADY      ) ,// slave

    // Read address
    .M_AXI_ARID           ( M_AXI_ARID        ) ,// slave 
    .M_AXI_ARADDR         ( M_AXI_ARADDR      ) ,// slave
    .M_AXI_ARLEN          ( M_AXI_ARLEN       ) ,// slave
    .M_AXI_ARSIZE         ( M_AXI_ARSIZE      ) ,// slave
    .M_AXI_ARBURST        ( M_AXI_ARBURST     ) ,// slave
    .M_AXI_ARVALID        ( M_AXI_ARVALID     ) ,// slave
    .M_AXI_ARREADY        ( M_AXI_ARREADY     ) ,// slave

    // Read data
    .M_AXI_RDATA          ( M_AXI_RDATA  ) , // slave
    .M_AXI_RRESP          ( M_AXI_RRESP  ) , // SLAVE
    .M_AXI_RLAST          ( M_AXI_RLAST  ) , // TO SLAVE
    .M_AXI_RVALID         ( M_AXI_RVALID ) , // READ VALID TO SLAVE
    .M_AXI_RREADY         ( M_AXI_RREADY ) , // TO SLAVE

    .start_read           ( start_read  ) , // INPUT TOP
    .ifm_size             ( ifm_size    ) ,
		.start_CNN            (start_CNN    ) ,
    .ofm_size             (ofm_size     ) ,
		.num_filter           (num_filter   ) ,
    .write                (ofm_write_en ) ,
		.read_fifo_ifm        (ifm_read_en  ) ,
    .data_fifo_o          (data_in      ) , 
		.done_layer           (done_wr_layer)
  );

Functional_Unit #(
    .SYSTOLIC_SIZE     ( SYSTOLIC_SIZE     ) ,
    .DATA_WIDTH        ( DATA_WIDTH        ) ,
    .INOUT_WIDTH       ( INOUT_WIDTH       ) ,
    .IFM_RAM_SIZE      ( IFM_RAM_SIZE      ) ,
    .WGT_RAM_SIZE      ( WGT_RAM_SIZE      ) ,
    .OFM_RAM_SIZE_1    ( OFM_RAM_SIZE_1    ) ,
    .OFM_RAM_SIZE_2    ( OFM_RAM_SIZE_2    ) ,
    .MAX_WGT_FIFO_SIZE ( MAX_WGT_FIFO_SIZE ) ,
    .RELU_PARAM        ( RELU_PARAM        ) ,
    .Q                 ( Q                 )
) F_U (
    .clk                ( M_AXI_ACLK         ) ,
    .rst_n              ( M_AXI_ARESETN      ) ,
    .start              ( start_layer        ) ,
    .done               ( done               ) ,

    //Layer config
    .count_layer        ( count_layer        ) ,
    .ifm_size           ( ifm_size           ) ,
    .ofm_size_conv      ( ofm_size_conv      ) ,
    .ofm_size           ( ofm_size           ) ,
    .ofm_size_ofm_ram_2 ( ofm_size_ofm_ram_2 ) ,
    .ifm_channel        ( ifm_channel        ) ,
    .kernel_size        ( kernel_size        ) ,
    .num_filter         ( num_filter         ) ,
    .maxpool_mode       ( maxpool_mode       ) ,
    .maxpool_stride     ( maxpool_stride     ) ,
    .upsample_mode      ( upsample_mode      ) ,

    .start_write_addr_1 ( start_write_addr_1 ) ,
    .start_read_addr_1  ( start_read_addr_1  ) ,
    .start_write_addr_2 ( start_write_addr_2 ) ,
    .start_read_addr_2  ( start_read_addr_2  ) ,
    .ifm_channel_size   ( ifm_channel_size   ) ,
    .ofm_channel_size_1 ( ofm_channel_size_1 ) ,
    .write_addr_incr_1  ( write_addr_incr_1  ) ,
    .last_write_size_1  ( last_write_size_1  ) ,
    .ofm_channel_size_2 ( ofm_channel_size_2 ) ,
    .write_addr_incr_2  ( write_addr_incr_2  ) ,
    .last_write_size_2  ( last_write_size_2  ) ,
    
  	.num_cycle_load     ( num_cycle_load     ) ,
  	.num_cycle_compute  ( num_cycle_compute  ) ,
  	.num_load_filter    ( num_load_filter    ) ,
  	.num_tiling         ( num_tiling         ) ,
  	.ifm_data_in        (data_in             ) ,                                             
    .ifm_read_en        (ifm_read_en         ) ,    
    .write_out_ofm_en_1 (ofm_write_en        ) ,
    .ofm_data_out_1     (ofm_data_write      )
 
);

Control_Unit #(.NUM_LAYER (NUM_LAYER), .OFM_RAM_SIZE_1 (OFM_RAM_SIZE_1), .OFM_RAM_SIZE_2 (OFM_RAM_SIZE_2)) C_U (
    .clk                ( M_AXI_ACLK         ) ,
    .rst_n              ( M_AXI_ARESETN      ) ,
    .start_CNN          ( start_CNN          ) ,
    .done_layer         ( done               ) ,
    .start_layer        ( start_layer        ) ,
    .done_CNN           ( done_CNN           ) ,
    
    //Layer config
    .count_layer        ( count_layer        ) ,
    .ifm_size           ( ifm_size           ) ,
    .ofm_size_conv      ( ofm_size_conv      ) ,
    .ofm_size           ( ofm_size           ) ,
    .ofm_size_ofm_ram_2 ( ofm_size_ofm_ram_2 ) ,    
    .ifm_channel        ( ifm_channel        ) ,
    .kernel_size        ( kernel_size        ) ,
    .num_filter         ( num_filter         ) ,
    .maxpool_mode       ( maxpool_mode       ) ,
    .maxpool_stride     ( maxpool_stride     ) ,
    .upsample_mode      ( upsample_mode      ) ,
    
    .start_write_addr_1 ( start_write_addr_1 ) ,
    .start_read_addr_1  ( start_read_addr_1  ) ,
    .start_write_addr_2 ( start_write_addr_2 ) ,
    .start_read_addr_2  ( start_read_addr_2  ) ,
    .ifm_channel_size   ( ifm_channel_size   ) ,
    .ofm_channel_size_1 ( ofm_channel_size_1 ) ,
    .write_addr_incr_1  ( write_addr_incr_1  ) ,
    .last_write_size_1  ( last_write_size_1  ) ,
    .ofm_channel_size_2 ( ofm_channel_size_2 ) ,
    .write_addr_incr_2  ( write_addr_incr_2  ) ,
    .last_write_size_2  ( last_write_size_2  ) ,

  	.num_cycle_load     ( num_cycle_load     ) ,
  	.num_cycle_compute  ( num_cycle_compute  ) ,
  	.num_load_filter    ( num_load_filter    ) ,
  	.num_tiling         ( num_tiling         )
);

endmodule


