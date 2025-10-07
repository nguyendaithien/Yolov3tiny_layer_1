
`timescale 1 ns / 1 ps
module tb();
parameter ID_WIDTH     = 4;
parameter ADDR_WIDTH   = 32;
parameter DATA_WIDTH   = 16;        

parameter SYSTOLIC_SIZE     = 16      ;
parameter INOUT_WIDTH       = 256     ;
parameter IFM_RAM_SIZE      = 524172  ;
parameter WGT_RAM_SIZE      = 5040    ;
parameter OFM_RAM_SIZE_1    = 2205619 ;
parameter OFM_RAM_SIZE_2    = 259584  ;
parameter MAX_WGT_FIFO_SIZE = 4608    ;
parameter RELU_PARAM        = 0       ;
parameter Q                 = 9       ;

	parameter AXI_WIDTH =   256;

parameter NUM_LAYER         = 1       ;



	parameter LEN_WIDTH         = 8 ;


		// User parameters ends
		// Base address of targeted slave
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000 ;
		parameter integer C_M_AXI_BURST_LEN	= 256            ;
		parameter integer C_M_AXI_ID_WIDTH	= 1              ;
		parameter integer C_M_AXI_ADDR_WIDTH	= 32           ;
		parameter integer C_M_AXI_DATA_WIDTH	= 256          ;
		parameter integer C_M_AXI_AWUSER_WIDTH	= 0          ;
		parameter integer C_M_AXI_ARUSER_WIDTH	= 0          ;
		parameter integer C_M_AXI_WUSER_WIDTH	= 0            ;
		parameter integer C_M_AXI_RUSER_WIDTH	= 0            ;
	parameter integer C_M_AXI_BUSER_WIDTH	= 0            ;


localparam BASE_ADDR_OFM = 65550;
localparam OFM_SIZE   = 208 ;
localparam NUM_FILTER = 16 ;
  reg                       rd_en ;
  reg                     	wr_en ;
  reg  [ADDR_WIDTH-1:0]     addr_R  ;
  reg  [ADDR_WIDTH-1:0]     addr_W  ;
  reg  [AXI_WIDTH-1:0]     wdata ;
  wire [AXI_WIDTH-1:0]     rdata ;
	wire                       busy_r  ; 
	wire                       busy_w  ; 
  reg ACLK;
  reg ARESETN;
	reg [10:0] num_channel           ;
	wire read_en_out                 ;
	reg start_read                   ;
	reg [8:0] ifm_size               ;
	reg wr_en_test;
	wire done_CNN;
	wire done_wr_layer;
	wire done;


 wire  TXN_DONE                                       ;
 wire  ERROR                                          ;
 wire  M_AXI_ACLK                                     ;
 wire  M_AXI_ARESETN                                  ;
 wire [C_M_AXI_ID_WIDTH-1 : 0         ] M_AXI_AWID    ;
 wire [C_M_AXI_ADDR_WIDTH-1 : 0       ] M_AXI_AWADDR  ;
 wire [7 : 0                          ] M_AXI_AWLEN   ;
 wire [2 : 0                          ] M_AXI_AWSIZE  ;
 wire [1 : 0                          ] M_AXI_AWBURST ;
 wire  M_AXI_AWLOCK                                   ;
 wire [3 : 0                          ] M_AXI_AWCACHE ;
 wire [2 : 0                          ] M_AXI_AWPROT  ;
 wire [3 : 0                          ] M_AXI_AWQOS   ;
 wire [C_M_AXI_AWUSER_WIDTH-1 : 0     ] M_AXI_AWUSER  ;
 wire  M_AXI_AWVALID                                  ;
 wire  M_AXI_AWREADY                                  ;
 wire [C_M_AXI_DATA_WIDTH-1 : 0       ] M_AXI_WDATA   ;
 wire [C_M_AXI_DATA_WIDTH/8-1 : 0     ] M_AXI_WSTRB   ;
 wire  M_AXI_WLAST                                    ;
 wire [C_M_AXI_WUSER_WIDTH-1 : 0      ] M_AXI_WUSER   ;
 wire  M_AXI_WVALID                                   ;
 wire  M_AXI_WREADY                                   ;
 wire [C_M_AXI_ID_WIDTH-1 : 0          ] M_AXI_BID    ;
 wire [1 : 0                           ] M_AXI_BRESP  ;
 wire [C_M_AXI_BUSER_WIDTH-1 : 0       ] M_AXI_BUSER  ;
 wire  M_AXI_BVALID                                   ;
 wire  M_AXI_BREADY                                   ;
 wire [C_M_AXI_ID_WIDTH-1 : 0         ] M_AXI_ARID    ;
 wire [C_M_AXI_ADDR_WIDTH-1 : 0       ] M_AXI_ARADDR  ;
 wire [7 : 0                          ] M_AXI_ARLEN   ;
 wire [2 : 0                          ] M_AXI_ARSIZE  ;
 wire [1 : 0                          ] M_AXI_ARBURST ;
 wire  M_AXI_ARLOCK                                   ;
 wire [3 : 0                          ] M_AXI_ARCACHE ;
 wire [2 : 0                          ] M_AXI_ARPROT  ;
 wire [3 : 0                          ] M_AXI_ARQOS   ;
 wire [C_M_AXI_ARUSER_WIDTH-1 : 0     ] M_AXI_ARUSER  ;
 wire  M_AXI_ARVALID                                  ;
 wire  M_AXI_ARREADY                                  ;
 wire [C_M_AXI_ID_WIDTH-1 : 0          ] M_AXI_RID    ;
 wire [C_M_AXI_DATA_WIDTH-1 : 0        ] M_AXI_RDATA  ;
 wire [1 : 0                           ] M_AXI_RRESP  ;
 wire  M_AXI_RLAST                                    ;
 wire [C_M_AXI_RUSER_WIDTH-1 : 0       ] M_AXI_RUSER  ;
 wire  M_AXI_RVALID                                   ;
 wire  M_AXI_RREADY                                   ;
	
	SYSTOLIC_ARRAY_v1_0_M00_AXI #
	(
		// Users to add parameters here
	.SYSTOLIC_SIZE     ( 16      ),
	.DATA_WIDTH        ( 16      ),
	.INOUT_WIDTH       ( 256     ),
	.IFM_RAM_SIZE      ( 524172  ),
	.WGT_RAM_SIZE      ( 5040    ),
	.OFM_RAM_SIZE_1    ( 2205619 ),
  .OFM_RAM_SIZE_2    ( 259584  ),
	.MAX_WGT_FIFO_SIZE ( 4608    ),
	.RELU_PARAM        ( 0       ),
  .Q                 ( 9       ),
  .NUM_LAYER         ( 1       ),

  .ID_WIDTH          ( 4       ),
  .ADDR_WIDTH        ( 32      ),
  .LEN_WIDTH         ( 8       ),

	.C_M_TARGET_SLAVE_BASE_ADDR ( 32'h40000000) ,
	.C_M_AXI_BURST_LEN          ( 256         ) ,
	.C_M_AXI_ID_WIDTH           ( 1           ) ,
	.C_M_AXI_ADDR_WIDTH         ( 32          ) ,
	.C_M_AXI_DATA_WIDTH         ( 256         ) ,
	.C_M_AXI_AWUSER_WIDTH       ( 0           ) ,
	.C_M_AXI_ARUSER_WIDTH       ( 0           ) ,
	.C_M_AXI_WUSER_WIDTH        ( 0           ) ,
	.C_M_AXI_RUSER_WIDTH        ( 0           ) ,
	.C_M_AXI_BUSER_WIDTH        ( 0           )
	) 
  top
	(
   .TXN_DONE      (TXN_DONE      ),
   .ERROR         (ERROR         ),
   .M_AXI_ACLK    (ACLK          ),
   .M_AXI_ARESETN (ARESETN       ),
   .M_AXI_AWID    (M_AXI_AWID    ),
   .M_AXI_AWADDR  (M_AXI_AWADDR  ),
   .M_AXI_AWLEN   (M_AXI_AWLEN   ),
   .M_AXI_AWSIZE  (M_AXI_AWSIZE  ),
   .M_AXI_AWBURST (M_AXI_AWBURST ),
   .M_AXI_AWLOCK  (M_AXI_AWLOCK  ),
   .M_AXI_AWCACHE (M_AXI_AWCACHE ),
   .M_AXI_AWPROT  (M_AXI_AWPROT  ),
   .M_AXI_AWQOS   (M_AXI_AWQOS   ),
   .M_AXI_AWUSER  (M_AXI_AWUSER  ),
   .M_AXI_AWVALID (M_AXI_AWVALID ),
   .M_AXI_AWREADY (M_AXI_AWREADY ),
   .M_AXI_WDATA   (M_AXI_WDATA   ),
   .M_AXI_WSTRB   (M_AXI_WSTRB   ),
   .M_AXI_WLAST   (M_AXI_WLAST   ),
   .M_AXI_WUSER   (M_AXI_WUSER   ),
   .M_AXI_WVALID  (M_AXI_WVALID  ),
   .M_AXI_WREADY  (M_AXI_WREADY  ),
   .M_AXI_BID     (M_AXI_BID     ),
   .M_AXI_BRESP   (M_AXI_BRESP   ),
   .M_AXI_BUSER   (M_AXI_BUSER   ),
   .M_AXI_BVALID  (M_AXI_BVALID  ),
   .M_AXI_BREADY  (M_AXI_BREADY  ),
   .M_AXI_ARID    (M_AXI_ARID    ),
   .M_AXI_ARADDR  (M_AXI_ARADDR  ),
   .M_AXI_ARLEN   (M_AXI_ARLEN   ),
   .M_AXI_ARSIZE  (M_AXI_ARSIZE  ),
   .M_AXI_ARBURST (M_AXI_ARBURST ),
   .M_AXI_ARLOCK  (M_AXI_ARLOCK  ),
   .M_AXI_ARCACHE (M_AXI_ARCACHE ),
   .M_AXI_ARPROT  (M_AXI_ARPROT  ),
   .M_AXI_ARQOS   (M_AXI_ARQOS   ),
   .M_AXI_ARUSER  (M_AXI_ARUSER  ),
   .M_AXI_ARVALID (M_AXI_ARVALID ),
   .M_AXI_ARREADY (M_AXI_ARREADY ),
   .M_AXI_RID     (M_AXI_RID     ),
   .M_AXI_RDATA   (M_AXI_RDATA   ),
   .M_AXI_RRESP   (M_AXI_RRESP   ),
   .M_AXI_RLAST   (M_AXI_RLAST   ),
   .M_AXI_RUSER   (M_AXI_RUSER   ),
   .M_AXI_RVALID  (M_AXI_RVALID  ),
   .M_AXI_RREADY  (M_AXI_RREADY  ),
   .start_read    (start_read    ),
   .done          (done          )
	);
	
  // ================= Slave =================
  axi_ram #(

    .DATA_WIDTH     (AXI_WIDTH      ), 
    .ADDR_WIDTH     (ADDR_WIDTH     ), 
    .STRB_WIDTH     (1              ), 
    .ID_WIDTH       (ID_WIDTH       ), 
		.TEST_SIZE      (1000000         ),
    .PIPELINE_OUTPUT(0) 
  ) u_slave (
    .clk(ACLK),
    .rst(!ARESETN),

    // Write addr
    .s_axi_awid       ( M_AXI_AWID    ) ,
    .s_axi_awaddr     ( M_AXI_AWADDR  ) ,
    .s_axi_awlen      ( M_AXI_AWLEN   ) ,
    .s_axi_awsize     ( M_AXI_AWSIZE  ) ,
    .s_axi_awburst    ( M_AXI_AWBURST ) ,
    .s_axi_awvalid    ( M_AXI_AWVALID ) ,
    .s_axi_awready    ( M_AXI_AWREADY ) ,

    // Write data
    .s_axi_wdata      ( M_AXI_WDATA   ) ,
    .s_axi_wstrb      ( M_AXI_WSTRB    ) ,
    .s_axi_wlast      ( M_AXI_WLAST    ) ,
    .s_axi_wvalid     ( M_AXI_WVALID   ) ,
    .s_axi_wready     ( M_AXI_WREADY   ) ,

    // Write response
    .s_axi_bresp      ( M_AXI_BRESP   ) ,
    .s_axi_bvalid     ( M_AXI_BVALID  ) ,
    .s_axi_bready     ( M_AXI_BREADY  ) ,

    // Read addr
    .s_axi_arid       ( M_AXI_ARID    ) ,
    .s_axi_araddr     ( M_AXI_ARADDR  ) ,
    .s_axi_arlen      ( M_AXI_ARLEN   ) ,
    .s_axi_arsize     ( M_AXI_ARSIZE  ) ,
    .s_axi_arburst    ( M_AXI_ARBURST ) ,
    .s_axi_arvalid    ( M_AXI_ARVALID ) ,
    .s_axi_arready    ( M_AXI_ARREADY ) ,


    // Read data
    .s_axi_rdata      ( M_AXI_RDATA   ) ,
    .s_axi_rresp      ( M_AXI_RRESP   ) ,
    .s_axi_rlast      ( M_AXI_RLAST   ) ,
    .s_axi_rvalid     ( M_AXI_RVALID  ) ,
    .s_axi_rready     ( M_AXI_RREADY  )

  );
	
always #5 ACLK = !ACLK ;
  parameter ROWS      = 208;
  parameter COLS_PACK = 26;   
  parameter PACK_SIZE = 8;    
parameter CHANNELS = 16;


  reg [15:0] mem_out [OFM_SIZE*OFM_SIZE*NUM_FILTER-1];
  integer c, i, j, k;
  integer idx;


//integer fd, fg, fg_1;
//initial begin
//	wait (done_wr_layer)
//    fg_1 = $fopen("ofm_memory_binary.txt", "w");
//    for (c = 0; c < 16; c = c + 1) begin
//        for (i = 0; i < 208; i = i + 1) begin
//            for (j = 0; j < 26; j = j + 1) begin
//                $fwrite(fd, "%0b ", $signed(top.u_slave.mem[c*208*26 + i*26 +  j + BASE_ADDR_OFM]));
//            end
//            $fwrite(fg_1, "\n");
//        end
//        $fwrite(fg_1, "\n"); // blank line between channels
//    end
//
//    $fclose(fg_1);
//    $display("Dumped OFM memory to ofm_memory_binary.txt");
//end

//initial begin
//	wait(done_wr_layer)
//    fg = $fopen("ofm_memory_demical.txt", "w");
//    for (c = 0; c < 16; c = c + 1) begin
//        for (i = 0; i < 208; i = i + 1) begin
//            for (j = 0; j < 26; j = j + 1) begin
//                $fwrite(fd, "%0d ", top.u_slave.mem[c*208*26 + i*26 + j + BASE_ADDR_OFM]);
//            end
//            $fwrite(fg, "\n");
//        end
//        $fwrite(fg, "\n"); // blank line between channels
//    end
//
//    $fclose(fg);
//    $display("Dumped OFM memory to ofm_memory_demical.txt");
//end

//always @(posedge top.BREADY) begin
//      $display(" data in memory ofm in %d : %h ", top.u_master.addr, top.u_slave.mem[top.u_master.addr]);
//	end

//always @(posedge ACLK) begin
//	if(top.valid_4) begin
//		$display (" IFM from DRAM : %h , counter fifo : %d, counter read: %d, count ifm %d, read FIFO = %b, ADDR = %d, c_state = %d , RLAST = %b, enable=%b, next_state=%d" , top.u_master.M_AXI_RDATA, top.u_master.fifo_ofm.cnt, top.u_master.beat_cnt_r,top.u_master.cnt_ifm, top.u_master.read_fifo, top.u_master.M_AXI_ARADDR, top.u_master.c_state_r,top.u_master.M_AXI_RLAST, top.u_master.M_AXI_RLAST && top.u_master.M_AXI_RVALID, top.u_master.next_state_r);
//	end
//end

//always @(posedge ACLK) begin
//	if(top.u_master.write) begin
//		$display (" DATA in FIFO %h ", top.u_master.WDATA_IN);
//		//$display (" DATA out FIFO %h ", top.u_master.data_fifo_o);
//		//$display (" Beat cnt read %b ", top.u_master.beat_cnt_r);
//		//$display (" Current state : %d ", top.u_master.c_state_r);
//	end
//end

//always @(posedge ACLK) begin
//	if(top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.write_out_ofm_en_1 ) begin
//		$display ("OFM: %h ", top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.ofm_data_out_1);
//	end
//end

//always @(posedge ACLK) begin
//	if(top.u_master.M_AXI_WREADY) begin
//		$display ("OFM: %h ", top.u_slave.mem[index]);
//		index = index + 1;
//	end
//end
//always @(posedge ACLK) begin
//	if(top.u_master.read_fifo) begin
// 		$display ("OFM: %h ", top.u_master.data_o_fifo);
//	end
//end
always @(posedge ACLK) begin
	if(M_AXI_WREADY) begin
 		$display ("OFM: %h", M_AXI_WDATA);
	end
end

reg [31:0] index;
initial begin
	index = 10816 * 27 + 1 ;
end
	
//always @(posedge ACLK) begin
//	if(M_AXI_WREADY) begin
//   $display ("time %d  OFM mem [%d] : %h ",$time, index,  u_slave.mem[index -2 ]);
//		index <= index + 1;
//	end
//end





//initial begin
//    @(posedge top.u_master.end_read_ifm);
//    fd = $fopen("ifm_memory.txt", "w");
//    if (fd == 0) begin
//        $display("Error: could not open output file.");
//        $finish;
//    end
//    // Dump memory per channel
//    for (c = 0; c < 3; c = c + 1) begin
//        for (i = 0; i < 418; i = i + 1) begin
//            for (j = 0; j < 418; j = j + 1) begin
//                $fwrite(fd, "%0d ", top.ifm_bram.mem[c*418*418 + i*418 + j]);
//            end
//            $fwrite(fd, "\n");
//        end
//        $fwrite(fd, "\n"); // blank line between channels
//    end
//
//    $fclose(fd);
//    $display("Dumped IFM memory to ifm_memory.txt");
//end

//write to output text file
//integer file;
//initial begin
//    wait (done_wr_layer)
//    file = $fopen ("output_matrix.txt", "w");
//        for (i = 0; i < NUM_FILTER; i = i + 1) begin
//            for (j = 0; j < OFM_SIZE; j = j + 1) begin
//            for (k = 0; k < OFM_SIZE; k = k + 1) begin
//                $fwrite (file, "%0d ", mem_out[i*OFM_SIZE*OFM_SIZE + j*OFM_SIZE +k]); //9558
//            end
//            $fwrite (file, "\n");
//				end
//            $fwrite (file, "\n");
//            if ( (i + 1) % OFM_SIZE == 0 ) $fwrite (file, "\n");
//        end
//        $fclose (file);
//end

initial begin
		ACLK = 0;
	wr_en_test = 0;
	num_channel = 11'd3;
	ifm_size = 9'd418;
		ARESETN = 0 ;
   # 30 
		ARESETN = 1 ;
	# 20 
	start_read = 0;
    rd_en  = 0;
    wr_en  = 0;
    addr_R   = 0;
    addr_W   = 16;
    wdata  =  16'd20; 
	# 50 
    rd_en  = 1;
	  start_read = 1;
	# 10 
    rd_en  = 0;
  	start_read = 0;
	  wdata = 16'd 45;
end
initial begin
	#135 wr_en_test = 1;
	#10 wr_en_test = 0; 
end

initial begin
    $readmemb ("ifm_256_bit.txt", u_slave.mem,0);
end

initial begin
    $readmemb ("wgt.txt", top.F_U.wgt_dpram.mem);
end
reg [DATA_WIDTH - 1 : 0] ofm_golden [OFM_SIZE * OFM_SIZE * NUM_FILTER - 1 : 0];

initial begin
	$readmemb ("output_layer1_bin.txt", ofm_golden);
end

initial begin 
    #200000000 $finish  ; 
end
//initial begin
//	#1000000
//	$display ( "OFM  65550     %b",  top.u_slave.mem[65550] );	
//	$display ( "OFM   70958    %b", top.u_slave.mem [70958] );	
//	$display ( "OFM   76366    %b", top.u_slave.mem [76366] );	
//	$display ( "OFM   81774    %b", top.u_slave.mem [81774] );	
//	$display ( "OFM  81774 + 1*208*26     %b", top.u_slave.mem [81774 + 1*208*26] );	
//	$display ( "OFM  81774 + 2*208*26     %b", top.u_slave.mem [81774 + 2*208*26] );	
//	$display ( "OFM  81774 + 3*208*26     %b", top.u_slave.mem [81774 + 3*208*26] );	
//	$display ( "OFM  81774 + 4*208*26     %b", top.u_slave.mem [81774 + 4*208*26] );	
//	$display ( "OFM  81774 + 5*208*26     %b", top.u_slave.mem [81774 + 5*208*26] );	
//	$display ( "OFM  81774 + 6*208*26     %b", top.u_slave.mem [81774 + 6*208*26] );	
//	$display ( "OFM  81774 + 7*208*26     %b", top.u_slave.mem [81774 + 7*208*26] );	
//	$display ( "OFM  81774 + 8*208*26     %b",  top.u_slave.mem[81774 + 8*208*26] );	
//	$display ( "OFM  81774 + 9*208*26     %b",  top.u_slave.mem[81774 + 9*208*26] );	
//	$display ( "OFM  81774 + 10*208*2     %b",  top.u_slave.mem[81774 + 10*208*26] );	
//end


//compare
task compare;
	integer i;
	begin
		for (i = 0; i < OFM_SIZE * OFM_SIZE * NUM_FILTER; i = i + 1) begin
			$display (" matrix ofm RTL : %d", mem_out[i + 0]);
			$display (" matrix golden : %d", ofm_golden[i]);
			if (ofm_golden[i] != mem_out[i + 0]) begin
				$display ("NO PASS in addess %d", i);
				disable compare;
			end
		end
		$display("\n");
		$display("██████╗  █████╗ ███████╗███████╗    ████████╗███████╗███████╗████████╗");
		$display("██╔══██╗██╔══██╗██╔════╝██╔════╝    ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝");
		$display("██████╔╝███████║███████╗███████╗       ██║   █████╗  ███████    ██║   ");
		$display("██╔═══╝ ██╔══██║╚════██║╚════██║       ██║   ██╔══╝       ██    ██║   ");
		$display("██║     ██║  ██║███████║███████║       ██║   ███████╗███████╗   ██║   ");
		$display("╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝       ╚═╝   ╚══════╝╚══════╝   ╚═╝   ");
	end
endtask

//always @(posedge done_wr_layer) begin
//	if (done_wr_layer) begin
//		compare();
//	end
//end

//initial begin
//	$monitor ("At time : %d - ofm_size = %d - count_layer = %d - counter filter = %d (max = %d) - counter tiling = %d (max = %d)", $time, top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.ofm_size_conv,top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.count_layer,top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.control.count_filter, top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.control.num_load_filter, top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.control.count_tiling, top.wrapper_ip.SYSTOLIC_ARRAY_v1_0_M00_AXI_inst.F_U.control.num_tiling);
//end

endmodule

