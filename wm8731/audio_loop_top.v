module WM8731_ctrl (
  input      clk,
  input      rst_n,

  input 	        DACLRC      ,
  input 	        BCLK        ,
  output 	        DACDAT      ,
  input           ADCLRC      ,                   
  input           ADCDAT      ,					      

  
  output   	      I2C_SCLK    ,
  inout 	        I2C_SDAT    ,
 
  input 	        DACLRC_2    ,
  input 	        BCLK_2      ,
  output 	        DACDAT_2    ,
  input           ADCLRC_2    ,                   
  input           ADCDAT_2    ,					      

  
  output   	      I2C_SCLK_2  ,
  inout 	        I2C_SDAT_2
    
);

wire        rst              ;
wire [15:0] wav_out_data     ;
wire        wav_rden         ;
wire [15:0] wav_in_data      ;
wire        wav_wren         ;
wire        record_en        ;
assign rst = ~ rst_n;

wire [15:0] wav_out_data_2   ;
reg [15:0] wav_in_data_2_reg;
wire        wav_rden_2       ;
wire [15:0] wav_in_data_2    ;
wire        wav_wren_2       ;
wire        record_en_2      ;
//		input  [15:0]	wav_out_data,
		//output     	    wav_rden    ,
    //input           play_en     , 
        
        
		//output [15:0] 	wav_in_data ,
		//output 	        wav_wren    ,		
    //input           record_en   ,

//def lms(x, d, N = 4, mu = 0.1):
  //nIters = min(len(x),len(d)) - N
  //u = np.zeros(N)
  //w = np.zeros(N)
  //e = np.zeros(nIters)
  //for n in range(nIters):
    //u[1:] = u[:-1]
    //u[0] = x[n]
    //e_n = d[n] - np.dot(u, w)
    //w = w + mu * e_n * u
    //e[n] = e_n
  //return e

always @(posedge clk) begin
  if (wav_wren_2) begin
    wav_in_data_2_reg <= wav_in_data_2;
  end
end

mywav u_my_wav(
  .clk50M(clk),
  .wav_out_data(wav_out_data),//input [15:0]
  .wav_rden(wav_rden),//output
  .play_en(1'b1),//input
  .wav_in_data(wav_in_data),//output [15:0]
  .wav_wren(wav_wren),//output
  .record_en(1'b1),//input
  .DACLRC(DACLRC),//input
  .BCLK(BCLK),//input
  .DACDAT(DACDAT),//output
  .ADCLRC(ADCLRC),//input
  .ADCDAT(ADCDAT),//input

  .I2C_SCLK(I2C_SCLK),//output
  .I2C_SDAT(I2C_SDAT)//inout
); 
mywav u_my_wav_2(
  .clk50M(clk),
  .wav_out_data(wav_out_data_2),//input [15:0]
  .wav_rden(wav_rden_2),//output
  .play_en(1'b1),//input
  .wav_in_data(wav_in_data_2),//output [15:0]
  .wav_wren(wav_wren_2),//output
  .record_en(1'b1),//input
  .DACLRC(DACLRC_2),//input
  .BCLK(BCLK_2),//input
  .DACDAT(DACDAT_2),//output
  .ADCLRC(ADCLRC_2),//input
  .ADCDAT(ADCDAT_2),//input

  .I2C_SCLK(I2C_SCLK_2),//output
  .I2C_SDAT(I2C_SDAT_2)//inout
); 

Adaptive_filter #(
  .STEP_SIZE(0.1),
  .STAGE(256)
) u_adaptive_filter(
  .clk(clk), 
  .rst(rst),
  .filter_in(wav_in_data), 
  .filter_en(wav_rden), 
  .desired_in(wav_in_data_2_reg),
  .filter_out(),
  .error_out(wav_out_data)
);


endmodule //WM8731_ctrl

