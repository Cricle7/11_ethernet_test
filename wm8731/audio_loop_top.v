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

  output reg      led,  
  output reg [3:0]led_stage,
  output          phy_rstn,

  input           rgmii_rxc,
  input           rgmii_rx_ctl,
  input [3:0]     rgmii_rxd,
                
  output          rgmii_txc,
  output          rgmii_tx_ctl,
  output [3:0]    rgmii_txd
    
);

  parameter RTP_Header_Param = 16'h8080; // 版本号（V=2） + 填充位（P=0） + 扩展位（X=0） + CSRC 计数（CC=0）
                                         // + 标记位（M=0） + 负载类型（PT=0）
  parameter SSRC = 32'h12345678; // SSRC 设置为常量值，例如，这里设置为 32 位的常量值 0x12345678
  parameter UDP_LENGTH = 960;    //一定要保证payload_length为整数

wire        rst              ;
wire [15:0] wav_out_data     ;
wire        wav_rden         ;
wire [15:0] wav_in_data      ;
wire        wav_wren         ;
wire        record_en        ;
assign rst = ~ rst_n;

wire [15:0] wav_out_data_2   ;
reg [15:0] wav_in_data_2_reg;
reg [15:0] wav_in_data_1_reg ;
wire        wav_rden_2       ;
wire [15:0] wav_in_data_2    ;
wire        wav_wren_2       ;
wire        record_en_2      ;

wire                 udp_send_data_valid;
wire                 udp_send_data_ready;
wire [UDP_LENGTH*8-1:0]    udp_send_data;
wire [15:0]          udp_send_data_length;
wire                 udp_rec_data_valid;
wire [7:0]           udp_rec_rdata;
wire [15:0]          udp_rec_data_length;
wire [9:0] stage    ;
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
always @(posedge clk) begin
  if (wav_wren) begin
    wav_in_data_1_reg <= wav_in_data;
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
  .filter_en    (wav_wren), 
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
  .udp_send_data_valid  (udp_send_data_valid),//input
  .udp_send_data_ready  (),
  .S_clr_flag_clk_udp_send_data_ready_posedge(udp_send_data_ready),       
  .udp_send_data        (udp_send_data),
  .udp_send_data_length (udp_send_data_length),
  .udp_rec_data_valid   (udp_rec_data_valid),
  .udp_rec_rdata        (udp_rec_rdata),
  .udp_rec_data_length  (udp_rec_data_length),
  .state    (  state  )
);

net_top #(
  .RTP_Header_Param(16'h8080), // 版本号（V=2） + 填充位（P=0） + 扩展位（X=0） + CSRC 计数（CC=0）
                                         // + 标记位（M=0） + 负载类型（PT=0）
  .SSRC( 32'h12345678), // SSRC 设置为常量值，例如，这里设置为 32 位的常量值 0x12345678
  .UDP_LENGTH( UDP_LENGTH)    //一定要保证payload_length为整数
)u_net_top (
  .clk                  (clk),
  .rst_n                (phy_rstn),
  .wav_in_data          (wav_in_data), // input [15:0]
  .wav_wren             (wav_wren),     // input

  .udp_send_data_valid  (udp_send_data_valid),//output
  .udp_send_data_ready  (udp_send_data_ready),
  .udp_send_data        (udp_send_data),
  .udp_send_data_length (udp_send_data_length),

  .udp_rec_data_valid   (udp_rec_data_valid),
  .udp_rec_rdata        (udp_rec_rdata),
  .udp_rec_data_length  (udp_rec_data_length)
);
    parameter IDLE          = 10'b0_000_000_001 ;
    parameter ARP_REQ       = 10'b0_000_000_010 ;
    parameter ARP_SEND      = 10'b0_000_000_100 ;
    parameter ARP_WAIT      = 10'b0_000_001_000 ;
    parameter GEN_REQ       = 10'b0_000_010_000 ;
    parameter WRITE_RAM     = 10'b0_000_100_000 ;
    parameter SEND          = 10'b0_001_000_000 ;
    parameter WAIT_VALID_END= 10'b0_010_000_000 ;
    parameter WAIT          = 10'b0_100_000_000 ;
    parameter CHECK_ARP     = 10'b1_000_000_000 ;
always @(*)
    begin
        case(state)
            IDLE        :led_stage = 4'd1;
            ARP_REQ     :led_stage = 4'd2;
            ARP_SEND    :led_stage = 4'd3;
            ARP_WAIT    :led_stage = 4'd4;
            GEN_REQ     :led_stage = 4'd5;
            WRITE_RAM   :led_stage = 4'd6;
            SEND        :led_stage = 4'd7;
            WAIT        :led_stage = 4'd8;
            WAIT_VALID_END     :led_stage = 4'd9;
            CHECK_ARP   :led_stage = 4'd10;
            default     : led_stage = 4'd11;
        endcase
end

endmodule //WM8731_ctrl
