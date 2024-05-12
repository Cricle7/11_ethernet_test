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
  inout 	        I2C_SDAT_2  ,

  input           clk_50m,
  output reg      led,
  output          phy_rstn,

  input           rgmii_rxc,
  input           rgmii_rx_ctl,
  input [3:0]     rgmii_rxd,
                
  output          rgmii_txc,
  output          rgmii_tx_ctl,
  output [3:0]    rgmii_txd,
    
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
mywav u_my_wav (
  .clk50M        (clk),
  .wav_out_data  (wav_out_data), // input [15:0]
  .wav_rden      (wav_rden),     // output
  .play_en       (1'b1),         // input
  .wav_in_data   (wav_in_data), // output [15:0]
  .wav_wren      (wav_wren),     // output
  .record_en     (1'b1),         // input
  .DACLRC        (DACLRC),       // input
  .BCLK          (BCLK),         // input
  .DACDAT        (DACDAT),       // output
  .ADCLRC        (ADCLRC),       // input
  .ADCDAT        (ADCDAT),       // input
  .I2C_SCLK      (I2C_SCLK),     // output
  .I2C_SDAT      (I2C_SDAT)      // inout
);

mywav u_my_wav_2 (
  .clk50M        (clk),
  .wav_out_data  (wav_out_data_2), // input [15:0]
  .wav_rden      (wav_rden_2),     // output
  .play_en       (1'b1),           // input
  .wav_in_data   (wav_in_data_2),  // output [15:0]
  .wav_wren      (wav_wren_2),     // output
  .record_en     (1'b1),           // input
  .DACLRC        (DACLRC_2),       // input
  .BCLK          (BCLK_2),         // input
  .DACDAT        (DACDAT_2),       // output
  .ADCLRC        (ADCLRC_2),       // input
  .ADCDAT        (ADCDAT_2),       // input
  .I2C_SCLK      (I2C_SCLK_2),     // output
  .I2C_SDAT      (I2C_SDAT_2)      // inout
);

Adaptive_filter #(
  .STEP_SIZE(0.1),
  .STAGE(256)
) u_adaptive_filter (
  .clk          (clk), 
  .rst          (rst),
  .filter_in    (wav_in_data), 
  //.filter_en    (wav_rden), 之前写的，打问号
  .filter_en    (wav_wden), 
  .desired_in   (wav_in_data_2_reg),
  .filter_out   (),
  .error_out    (wav_out_data)
);

ethernet_test #(
  .LOCAL_MAC    (48'hA0_B1_C2_D3_E1_E1),
  .LOCAL_IP     (32'hC0_A8_01_0B),     // 192.168.1.11
  .LOCL_PORT    (16'h1F91),            // 8081
  .DEST_IP      (32'hC0_A8_01_69),     // 192.168.1.105
  .DEST_PORT    (16'h1F91)
) inst_eth_test (
  .clk_50m              (clk),
  .led                  (led),
  .phy_rstn             (phy_rstn),
  .rgmii_rxc            (rgmii_rxc),
  .rgmii_rx_ctl         (rgmii_rx_ctl),
  .rgmii_rxd            (rgmii_rxd),
  .rgmii_txc            (rgmii_txc),
  .rgmii_tx_ctl         (rgmii_tx_ctl),
  .rgmii_txd            (rgmii_txd),
  .udp_send_data_valid  (udp_send_data_valid),
  .udp_send_data_ready  (udp_send_data_ready),
  .udp_send_data        (udp_send_data),
  .udp_send_data_length (udp_send_data_length),
  .udp_rec_data_valid   (udp_rec_data_valid),
  .udp_rec_rdata        (udp_rec_rdata),
  .udp_rec_data_length  (udp_rec_data_length)
);

net_top u_net_top (
  .clk                  (clk),
  .rst_n                (phy_rstn),
  .wav_out_data         (wav_out_data), // input [15:0]
  .wav_rden             (wav_rden),     // output
  .wav_in_data          (wav_in_data), // output [15:0]
  .wav_wren             (wav_wren),     // output

  .udp_send_data_valid  (udp_send_data_valid),
  .udp_send_data_ready  (udp_send_data_ready),
  .udp_send_data        (udp_send_data),
  .udp_send_data_length (udp_send_data_length),

  .udp_rec_data_valid   (udp_rec_data_valid),
  .udp_rec_rdata        (udp_rec_rdata),
  .udp_rec_data_length  (udp_rec_data_length)
);
endmodule //WM8731_ctrl

