`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/16 23:40:05
// Design Name: 
// Module Name: eth_udp_test
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


module eth_udp_test#(
    parameter       LOCAL_MAC = 48'h11_11_11_11_11_11,
    parameter       LOCAL_IP  = 32'hC0_A8_01_6E,//192.168.1.110
    parameter       LOCL_PORT = 16'h8080,

    parameter       DEST_IP   = 32'hC0_A8_01_69,//192.168.1.105
    parameter       DEST_PORT = 16'h8080 
)(
    input                rgmii_clk,
    input                rstn,
    input                gmii_rx_dv,
    input  [7:0]         gmii_rxd,
    output reg           gmii_tx_en,
    output reg [7:0]     gmii_txd,
                 
    input                udp_send_data_valid,         
    output               udp_send_data_ready,         
    input [1024*8-1:0]   udp_send_data ,//先给这么多，爆了再改得了             
    input [15:0]         udp_send_data_length,        

    output               udp_rec_data_valid,         
    output [7:0]         udp_rec_rdata ,             
    output [15:0]        udp_rec_data_length         
);
    
    localparam UDP_WIDTH = 32 ;
    localparam UDP_DEPTH = 368;//最大大小为1500 - 20 - 8 = 1472字节
    reg   [7:0]          ram_wr_data ;
    reg                  ram_wr_en ;
    wire                 udp_ram_data_req ;
      
    wire                 udp_tx_req ;
    wire                 arp_request_req ;
    wire                 mac_send_end ;
    reg                  write_end ;
    
    reg  [31:0]          wait_cnt ;
    
    wire                 mac_not_exist ;
    wire                 arp_found ;
       

    parameter IDLE          = 10'b0_000_000_001 ;
    parameter ARP_REQ       = 10'b0_000_000_010 ;
    parameter ARP_SEND      = 10'b0_000_000_100 ;
    parameter ARP_WAIT      = 10'b0_000_001_000 ;
    parameter GEN_REQ       = 10'b0_000_010_000 ;
    parameter WRITE_RAM     = 10'b0_000_100_000 ;
    parameter SEND          = 10'b0_001_000_000 ;
    parameter WAIT          = 10'b0_010_000_000 ;
    parameter WAIT_REQ      = 10'b0_100_000_000 ;
    parameter CHECK_ARP     = 10'b1_000_000_000 ;
    parameter test_data_rx_length = 159;
    parameter ONE_SECOND_CNT= 32'd125_000_000;//32'd12500;//
    `ifdef SIMULATION
        assign arp_found = 1'b1;
        assign mac_not_exist = 1'b0;
    `endif
    assign udp_send_data_ready = write_end;

    reg [9:0]    state  ;
    reg [9:0]    state_n ;

    always @(posedge rgmii_clk)
    begin
        if (~rstn)
            state  <=  IDLE  ;
        else
            state  <= state_n ;
    end
      
    always @(*)
    begin
        case(state)
            IDLE        :
            begin
                `ifdef SIMULATION
                    state_n = ARP_REQ ;
                `else
                    if (wait_cnt == ONE_SECOND_CNT)    //1s
                        state_n = ARP_REQ ;
                    else
                        state_n = IDLE ;
                `endif
            end
            ARP_REQ     :
                state_n = ARP_SEND ;
            ARP_SEND    :
            begin
                if (mac_send_end)
                    state_n = ARP_WAIT ;
                else
                    state_n = ARP_SEND ;
            end
            ARP_WAIT    :
            begin
                if (arp_found)
                    state_n = WAIT ;
                else if (wait_cnt == ONE_SECOND_CNT)
                    state_n = ARP_REQ ;
                else
                    state_n = ARP_WAIT ;
            end
            GEN_REQ     :
            begin
                if (udp_ram_data_req)
                    state_n = WRITE_RAM ;
                else
                    state_n = GEN_REQ ;
            end
            WRITE_RAM   :
            begin
                if (write_end) 
                    state_n = WAIT  ;
                else
                    state_n = WRITE_RAM ;
            end
            SEND        :
            begin
                if (mac_send_end)
                    state_n = WAIT ;
                else
                    state_n = SEND ;
            end
            WAIT        :
            begin
                if (udp_send_data_valid) 
                    state_n = CHECK_ARP ;
    		    else if (wait_cnt == ONE_SECOND_CNT)    //1s
                    state_n = CHECK_ARP ;
                else
                    state_n = WAIT ;
            end
            WAIT_REQ     :
            begin
    		    if (udp_send_data_valid)    //1s
                    state_n = CHECK_ARP ;
                else if (wait_cnt == ONE_SECOND_CNT) begin
                    state_n = CHECK_ARP ;
                end
                else
                    state_n = WAIT_REQ ;
            end
            CHECK_ARP   :
            begin
                if (mac_not_exist)
                    state_n = ARP_REQ ;
                else
                    state_n = GEN_REQ ;
            end
            default     : state_n = IDLE ;
        endcase
    end

    reg          gmii_rx_dv_1d;
    reg  [7:0]   gmii_rxd_1d;
    wire         gmii_tx_en_tmp;
    wire [7:0]   gmii_txd_tmp;
    
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
        begin
            gmii_rx_dv_1d <= 1'b0 ;
            gmii_rxd_1d   <= 8'd0 ;
        end
        else
        begin
            gmii_rx_dv_1d <= gmii_rx_dv ;
            gmii_rxd_1d   <= gmii_rxd ;
        end
    end
      
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
        begin
            gmii_tx_en <= 1'b0 ;
            gmii_txd   <= 8'd0 ;
        end
        else
        begin
            gmii_tx_en <= gmii_tx_en_tmp ;
            gmii_txd   <= gmii_txd_tmp ;
        end
    end
    
udp_ip_mac_top#(
    .LOCAL_MAC                (LOCAL_MAC               ),// 48'h11_11_11_11_11_11,
    .LOCAL_IP                 (LOCAL_IP                ),// 32'hC0_A8_01_6E,//192.168.1.110
    .LOCL_PORT                (LOCL_PORT               ),// 16'h8080,
                                                        
    .DEST_IP                  (DEST_IP                 ),// 32'hC0_A8_01_69,//192.168.1.105
    .DEST_PORT                (DEST_PORT               ) // 16'h8080 
)udp_ip_mac_top(
    .rgmii_clk                (  rgmii_clk             ),//input           rgmii_clk,
    .rstn                     (  rstn                  ),//input           rstn,

    .app_data_in_valid        (  ram_wr_en             ),//input           app_data_in_valid,
    .app_data_in              (  ram_wr_data           ),//input   [7:0]   app_data_in,      
    .app_data_length          (  udp_send_data_length  ),//input   [15:0]  app_data_length,   
    .app_data_request         (  udp_tx_req            ),//input           app_data_request, 
                                                        
    .udp_send_ack             (  udp_ram_data_req      ),//output          udp_send_ack,   
                                                        
    .arp_req                  (  arp_request_req       ),//input           arp_req,
    `ifdef SIMULATION
        .arp_found                (               ),//output          arp_found,
        .mac_not_exist            (           ),//output          mac_not_exist, 
    `else
        .arp_found                (  arp_found             ),//output          arp_found,
        .mac_not_exist            (  mac_not_exist         ),//output          mac_not_exist, 
    `endif

    .mac_send_end             (  mac_send_end          ),//output          mac_send_end,
    
    .udp_rec_rdata            (  udp_rec_rdata         ),//output  [7:0]   udp_rec_rdata ,      //udp ram read data   
    .udp_rec_data_length      (  udp_rec_data_length   ),//output  [15:0]  udp_rec_data_length,     //udp data length     
    .udp_rec_data_valid       (  udp_rec_data_valid    ),//output          udp_rec_data_valid,       //udp data valid      
    
    .mac_data_valid           (  gmii_tx_en_tmp        ),//output          mac_data_valid,
    .mac_tx_data              (  gmii_txd_tmp          ),//output  [7:0]   mac_tx_data,   
                                    
    .rx_en                    (  gmii_rx_dv_1d         ),//input           rx_en,         
    .mac_rx_datain            (  gmii_rxd_1d           ) //input   [7:0]   mac_rx_datain
);

    reg [test_data_rx_length*8-1:0] test_data_rx;
    reg [15 : 0] udp_rec_rdata_cnt;
      
    assign udp_tx_req    = (state == GEN_REQ) ;
    assign arp_request_req  = (state == ARP_REQ) ;
    
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
            wait_cnt <= 0 ;
        else if ((state==IDLE||state == WAIT || state == ARP_WAIT) && state != state_n)
            wait_cnt <= 0 ;
        else if (state==IDLE||state == WAIT || state == ARP_WAIT)
            wait_cnt <= wait_cnt + 1'b1 ;
    	else
    	    wait_cnt <= 0 ;
    end
    
    reg [15:0] test_cnt;
    always@(posedge rgmii_clk)//例程里没用到
    begin
        if(rstn == 1'b0)
        begin
            write_end  <= 1'b0;
            ram_wr_data <= 0;
            ram_wr_en  <= 0 ;
            test_cnt   <= 0;
        end
        else if (state == WRITE_RAM)//例程里没到
        begin
            if(test_cnt == udp_send_data_length)
            begin
                ram_wr_en <=1'b0;
                write_end <= 1'b1;
            end
            else
            begin
                ram_wr_en <= 1'b1 ;
                write_end <= 1'b0 ;
                ram_wr_data <= udp_send_data[udp_send_data_length*8-1-{test_cnt[15:0],3'd0} -: 8] ;
                test_cnt <= test_cnt + 8'd1;
            end
        end
        else
        begin
            write_end  <= 1'b0;
            ram_wr_data <= 0;
            ram_wr_en  <= 0;
            test_cnt   <= 0;
        end
    end
      

    always @(posedge rgmii_clk) begin
        if (udp_rec_data_valid) begin
             test_data_rx <= {test_data_rx[test_data_rx_length*8-1-7: 0],udp_rec_rdata} ;
        end
    end
  
endmodule
