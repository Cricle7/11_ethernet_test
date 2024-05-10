module Adaptive_filter #(
  parameter STEP_SIZE = 0.1,//mu
  parameter STAGE = 256
)
(
  input clk, 
  input rst,//高电平复位
  input signed [15:0] filter_in, 
  input filter_en,
  input signed [15:0] desired_in, 
  input desired_en,
  output reg signed [15:0] filter_out,
  output reg signed [15:0] error_out
);

reg         [3:0]   lms_state;
reg         [3:0]   lms_next_state;
reg         [8:0]   fir_cnt;
reg         [8:0]   coeff_cnt;
reg         [8:0]   coeff_addr;


wire signed [15:0]  coeff_data_reg;
wire                coeff_up;
wire                wr_coeff_en;
reg  signed [15:0]  wr_coeff_data;
wire                wr_busy_filter_in;


wire signed [15:0]  filter_data_reg;//
wire signed [15:0]  filter_out_reg;//
reg  signed [95:0]  filter_out_test;//
reg  signed [95:0]  desired_in_reg;//

wire                product_ce;
wire                reload;


// x 参考信号进滤波器
// mic_in 麦克风信号
// N 滤波器阶数
wire signed   [15:0]   error_out_reg;//
wire signed   [95:0]   y;//
wire signed   [31:0]   p;//
reg  signed   [16:0]   p_reg;//

//fir

parameter  INIT	            = 4'h0;	
parameter  WR_EN            = 4'h1;	
parameter  RD_EN            = 4'h2;	
parameter  FIR              = 4'h3;	
parameter  COEFF            = 4'h4;	//往后是无脑打拍环节，fir的addr变换结束
parameter  E_U              = 4'h5;	//en*u
parameter  W                = 4'h6;	//w = w + mu * e_n * u, ram输出结束,
parameter  W_DLY            = 4'h7;	//fir计算完成,error_out_reg正确,w(i)输出，
parameter  COEFF_WR_EN      = 4'h8;	//coeff_multiply计算结束,w_n+1(i)计算正确
parameter  COEFF_UP         = 4'h9;	

assign reload = (fir_cnt == 1) ? 1 : 0;
assign coeff_up = (lms_state == COEFF_UP) ? 1 : 0;
assign wr_coeff_en = (lms_state == COEFF_WR_EN) ? 1 : 0;
//assign wr_coeff_data = coeff_data_reg + p_reg;
//assign wr_coeff_data = {p[31],p[17:3]};//这个是不正确的
assign filter_out_reg = {y[95],y[30:16]};//16bit
assign error_out_reg = desired_in_reg - filter_out_reg;
assign product_ce = 1'b1;

always @(*) begin
  wr_coeff_data = coeff_data_reg + p_reg;
end
always@(*)begin
  if(p[31]) begin
    p_reg = {3'b111,p[31:19]};
  end
  else begin
    p_reg = {3'b000,p[31:19]};
  end
end

always @(posedge clk) begin
  if (lms_state == W_DLY) begin
    filter_out_test <= y;
  end
end

always @(posedge clk) begin
  if (filter_en) begin
    desired_in_reg <= desired_in;
  end
end

always @(posedge clk) begin
  lms_state <= lms_next_state;
end

always @(*) begin
  case (lms_state)
    INIT      : lms_next_state = (filter_en) ? WR_EN : lms_state; 
    WR_EN     : lms_next_state = (!wr_busy_filter_in) ? RD_EN : lms_state; 
    RD_EN     : lms_next_state = FIR; 
    FIR       : lms_next_state = (fir_cnt == STAGE - 1) ? COEFF : lms_state; 
    COEFF     : lms_next_state = E_U; 
    E_U       : lms_next_state = W; 
    W         : lms_next_state = W_DLY; 
    W_DLY     : lms_next_state = COEFF_WR_EN; 
    COEFF_WR_EN : lms_next_state = (coeff_cnt == STAGE) ? COEFF_UP : INIT; 
    COEFF_UP  : lms_next_state = INIT; 
      default : lms_next_state = INIT; 
  endcase
end

always @(posedge clk) begin
  if (lms_state == FIR) begin
    fir_cnt <= fir_cnt + 1'b1;//从0开始数
  end
  else begin
    fir_cnt <= 0;
  end
end

always @(posedge clk) begin
  if (lms_state == W_DLY) begin //fir 算完三个周期
    filter_out <= filter_out_reg;
  end
  if (lms_state == COEFF_WR_EN) begin //fir 算完三个周期
    error_out <= error_out_reg;
  end
end

always @(posedge clk) begin
  if (rst) begin
    coeff_cnt <= 0;
  end
  else if (lms_state == COEFF) begin
    coeff_cnt <= coeff_cnt + 1'b1;
  end
  else if (lms_state == COEFF_UP) begin
    coeff_cnt <= 0;
  end
end

always @(*) begin
  if (lms_state == W) begin
    coeff_addr = coeff_cnt;    
  end
  else if (fir_cnt == 0) begin
    coeff_addr = 0;    
  end
  else
    coeff_addr = STAGE +1  - fir_cnt;    
end

ram_based_shift_register filter_in_reg_16(
  .rst          (rst                    ),//高电平复位
  .clk          (clk                    ),
  .wr_data      (filter_in              ),
  .wr_en        (filter_en              ),//1:wr,0:rd
  .rd_addr      (fir_cnt                ),
  .rd_data      (filter_data_reg        ),
  .wr_busy      (wr_busy_filter_in      )//1:wr,0:rd
);

coeff_reg #(
  .STAGE        (STAGE                  )
) u_coeff_reg   (
  .clk          (clk                    ),
  .rst          (rst                    ),
  .wr_addr      (coeff_cnt              ),
  .wr_coeff     (wr_coeff_data          ),
  .wr_en        (wr_coeff_en            ),
  .coeff_up     (coeff_up               ),
  .rd_addr      (coeff_addr             ),
  .rd_data      (coeff_data_reg         )
);

multiply_accumulator_16bit fir (//延迟一拍
  .a            (filter_data_reg        ),// input [15:0]
  .b            (coeff_data_reg         ),// input [15:0]
  .clk          (clk                    ),// input
  .rst          (rst                    ),// input
  .ce           (1'b1                   ),// input
  .reload       (reload                 ),// input
  .p            (y                      ) // output [95:0]
);

product coeff_multiply (//延迟两拍
  .a            (error_out_reg          ),// input [15:0] 
  .b            (filter_data_reg        ),// input [15:0] 
  .clk          (clk                    ),// input
  .rst          (rst                    ),// input
  .ce           (product_ce             ),// input
  .p            (p                      ) // output [31:0]
);


endmodule