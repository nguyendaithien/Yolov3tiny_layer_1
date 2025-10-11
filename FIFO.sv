module FIFO_OFM #(
	parameter DATA_WIDTH = 256   , 
	parameter FIFO_SIZE  = 512 
) (
	input                           clk           ,
	input                           rd_clr        ,
	input                           wr_clr        ,
	input                           rd_en         ,
	input                           wr_en         ,
	input      [DATA_WIDTH - 1 : 0] data_in_fifo  ,
	output reg [DATA_WIDTH - 1 : 0] data_out_fifo                
);

(* ram_style = "block", syn_ramstyle = "block_ram" *)	reg [DATA_WIDTH        - 1 : 0] fifo_data [0 : FIFO_SIZE - 1] ;
	reg [$clog2(FIFO_SIZE) - 1 : 0] rd_ptr                        ;
	reg [$clog2(FIFO_SIZE) - 1 : 0] wr_ptr                        ;

	wire [$clog2(FIFO_SIZE) - 1 : 0] rd_ptr_next   ;
	wire [$clog2(FIFO_SIZE) - 1 : 0] wr_ptr_next                        ;
	assign rd_ptr_next = (rd_ptr == FIFO_SIZE - 1) ? '0 :  rd_ptr + (rd_en);

always @(posedge clk) begin
  if (!rd_clr) begin
    rd_ptr        <= 0;
    data_out_fifo <= 0;
  end else begin
    if (rd_en) begin
      data_out_fifo <= fifo_data[rd_ptr];
      rd_ptr        <= rd_ptr_next;
    end
		else data_out_fifo <= 0;
  end
end

	assign wr_ptr_next = (wr_ptr == FIFO_SIZE - 1 ) ? '0 :( wr_ptr + (wr_en));

	always @(posedge clk) begin
		if      (!wr_clr) wr_ptr <= 0 ; 
		else if (wr_en) begin
			fifo_data[wr_ptr] <= data_in_fifo    ;
			wr_ptr            <= wr_ptr_next ;
		end
	end



endmodule
