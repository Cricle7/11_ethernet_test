`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/18 00:51:04
// Design Name: 
// Module Name: eth_test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ethernet_test#(
    parameter       LOCAL_MAC = 48'ha0_b1_c2_d3_e1_e1,
    parameter       LOCAL_IP  = 32'hC0_A8_01_0B,//192.168.1.11
    parameter       LOCL_PORT = 16'h1F91,//8081
    parameter       DEST_IP   = 32'hC0_A8_01_69,//192.168.1.105
    parameter       DEST_PORT = 16'h1F91 
)(
    input           clk_50m,
    output reg      led,
    output          phy_rstn,

    input           rgmii_rxc,
    input           rgmii_rx_ctl,
    input [3:0]     rgmii_rxd,
                 
    output          rgmii_txc,
    output          rgmii_tx_ctl,
    output [3:0]    rgmii_txd,

    input           udp_send_data_valid,         
    output          udp_send_data_ready,  
    output          S_clr_flag_clk_udp_send_data_ready_posedge,       

    input [960:0]   udp_send_data ,             
    input [15:0]    udp_send_data_length,        

    output          udp_rec_data_valid,         
    output [7:0]    udp_rec_rdata ,             
    output [15:0]   udp_rec_data_length     
);
    
    wire         rst;              
    wire         rgmii_clk;        
    wire         rgmii_clk_90p;       
                 
    wire         mac_rx_data_valid;
    wire [7:0]   mac_rx_data;    
                 
    wire         mac_data_valid;  
    wire  [7:0]  mac_tx_data;  
    
    reg          arp_req;

    wire clk_125m;
    wire clk_200m;

    wire idelayctrl_rdy;
    reg  idelay_ctl_rst;
    reg  [3:0] setup_cnt=4'hF;

    ref_clock ref_clock(
        .clkout0 ( clk_200m  ), // output clk_out1
        .clkout1 ( clk_125m  ), // output clk_out2
        .pll_lock( rstn      ), // output locked
        .clkin1  ( clk_50m   )  // input clk_in1
    );
    
    always @(posedge clk_200m)
    begin
        if(~rstn)
            setup_cnt <= 4'd0;
        else
        begin
            if(setup_cnt == 4'hF)
                setup_cnt <= setup_cnt;
            else
                setup_cnt <= setup_cnt + 1'b1;
        end
    end
    
    always @(posedge clk_200m)
    begin
        if(~rstn)
            idelay_ctl_rst <= 1'b1;
        else if(setup_cnt == 4'hF)
            idelay_ctl_rst <= 1'b0;
        else
            idelay_ctl_rst <= 1'b1;
    end 
    
    
    eth_udp_test #(
        .LOCAL_MAC                (LOCAL_MAC               ),// 48'h11_11_11_11_11_11,
        .LOCAL_IP                 (LOCAL_IP                ),// 32'hC0_A8_01_6E,//192.168.1.110
        .LOCL_PORT                (LOCL_PORT               ),// 16'h8080,
                                                           
        .DEST_IP                  (DEST_IP                 ),// 32'hC0_A8_01_69,//192.168.1.105
        .DEST_PORT                (DEST_PORT               ) // 16'h8080 
)eth_udp_test(
        .rgmii_clk              (  rgmii_clk            ),//input                rgmii_clk,
        .rstn                   (  rstn                 ),//input                rstn,
        .gmii_rx_dv             (  mac_rx_data_valid    ),//input                gmii_rx_dv,
        .gmii_rxd               (  mac_rx_data          ),//input  [7:0]         gmii_rxd,
        .gmii_tx_en             (  mac_data_valid       ),//output reg           gmii_tx_en,
        .gmii_txd               (  mac_tx_data          ),//output reg [7:0]     gmii_txd,
                                                      
        .udp_send_data_valid    (  udp_send_data_valid_reg),
        .udp_send_data_ready    (  udp_send_data_ready  ),
        .udp_send_data          (  udp_send_data        ),
        .udp_send_data_length   (  udp_send_data_length ),

        .udp_rec_data_valid     (  udp_rec_data_valid   ),//output               udp_rec_data_valid,         
        .udp_rec_rdata          (  udp_rec_rdata        ),//output [7:0]         udp_rec_rdata ,             
        .udp_rec_data_length    (  udp_rec_data_length  ) //output [15:0]        udp_rec_data_length         
    );
    
    wire        arp_found;
    wire        mac_not_exist;
    wire [7:0]  state;
    
    rgmii_interface rgmii_interface(
        .rst                       (  ~rstn              ),//input        rst,
        .rgmii_clk                 (  rgmii_clk          ),//output       rgmii_clk,
        .rgmii_clk_90p             (  rgmii_clk_90p      ),//input        rgmii_clk_90p,
  
        .mac_tx_data_valid         (  mac_data_valid     ),//input        mac_tx_data_valid,
        .mac_tx_data               (  mac_tx_data        ),//input [7:0]  mac_tx_data,
    
        .mac_rx_error              (                     ),//output       mac_rx_error,
        .mac_rx_data_valid         (  mac_rx_data_valid  ),//output       mac_rx_data_valid,
        .mac_rx_data               (  mac_rx_data        ),//output [7:0] mac_rx_data,
                                                         
        .rgmii_rxc                 (  rgmii_rxc          ),//input        rgmii_rxc,
        .rgmii_rx_ctl              (  rgmii_rx_ctl       ),//input        rgmii_rx_ctl,
        .rgmii_rxd                 (  rgmii_rxd          ),//input [3:0]  rgmii_rxd,
                                                         
        .rgmii_txc                 (  rgmii_txc          ),//output       rgmii_txc,
        .rgmii_tx_ctl              (  rgmii_tx_ctl       ),//output       rgmii_tx_ctl,
        .rgmii_txd                 (  rgmii_txd          ) //output [3:0] rgmii_txd 
    );
assign led_test =  (udp_rec_data_valid== 1'b1 ? (|udp_rec_rdata) : (&udp_rec_data_length));
//test led
reg[31:0] cnt_timer;
  always @(posedge rgmii_rxc)begin
  cnt_timer<=cnt_timer+1'b1;
if( cnt_timer==32'h1_fff_fff)
begin
   led=~led;
    cnt_timer<=32'h0;
end
  end

assign phy_rstn = rstn;
assign clk = clk_50m;
//=======================================================
// 对于 udp_send_data_valid 信号做跨时钟域处理（clk -> rgmii_clk）
//=======================================================
reg                S_clr_flag_rgmii_clk_udp_send_data_valid_d0;
reg                S_clr_flag_rgmii_clk_udp_send_data_valid_d1;
//=======================================================
// 对于 udp_send_data_ready 信号做跨时钟域处理（rgmii_clk -> clk）
//=======================================================
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d0;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d1;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d2;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d3;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d4;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d5;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d6;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d7;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d8;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d9;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d10;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d11;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d12;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d13;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d14;
reg                S_clr_flag_rgmii_clk_udp_send_data_ready_d15;

reg                S_clr_flag_rgmii_clk_udp_send_data_ready_all;

reg                S_clr_flag_clk_udp_send_data_ready_posedge;


reg                S_clr_flag_clk_udp_send_data_ready_d0;
reg                S_clr_flag_clk_udp_send_data_ready_d1;
reg                S_clr_flag_clk_udp_send_data_ready_d2;
//=======================================================
// 时钟域 clk
//=======================================================
always @(posedge clk) begin//这里我直接按照rgmii_clk是250M的时钟来做
  S_clr_flag_clk_udp_send_data_ready_d0 <= S_clr_flag_rgmii_clk_udp_send_data_ready_all;
  S_clr_flag_clk_udp_send_data_ready_d1 <= S_clr_flag_clk_udp_send_data_ready_d0;
  S_clr_flag_clk_udp_send_data_ready_d2 <= S_clr_flag_clk_udp_send_data_ready_d1;
 
  S_clr_flag_clk_udp_send_data_ready_posedge <= (!S_clr_flag_clk_udp_send_data_ready_d2) & S_clr_flag_clk_udp_send_data_ready_d1;
end

//=======================================================
// 时钟域 rgmii_clk
//=======================================================
wire               S_clr_flag_rgmii_clk_udp_send_data_valid_d11;
assign udp_rec_data_valid_reg = S_clr_flag_rgmii_clk_udp_send_data_valid_d1;
always @(posedge rgmii_clk) begin
  S_clr_flag_rgmii_clk_udp_send_data_valid_d0 <= udp_send_data_valid;
  S_clr_flag_rgmii_clk_udp_send_data_valid_d1 <= S_clr_flag_rgmii_clk_udp_send_data_valid_d0;

  S_clr_flag_rgmii_clk_udp_send_data_ready_d0 <= udp_send_data_ready;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d1 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d0;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d2 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d1;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d3 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d2;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d4 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d3;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d5 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d4;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d6 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d5;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d7 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d6;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d8 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d7;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d9 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d8;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d10 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d9;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d11 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d10;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d12 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d11;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d13 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d12;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d14 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d13;
  S_clr_flag_rgmii_clk_udp_send_data_ready_d15 <= S_clr_flag_rgmii_clk_udp_send_data_ready_d14;

  S_clr_flag_rgmii_clk_udp_send_data_ready_all <= udp_send_data_ready 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d0 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d1 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d2 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d3  
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d4 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d5 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d6 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d7  
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d8 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d9 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d10 
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d11  
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d12  
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d13  
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d14  
  | S_clr_flag_rgmii_clk_udp_send_data_ready_d15;  

end



endmodule
