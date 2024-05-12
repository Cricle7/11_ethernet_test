module net_top #(
  parameter RTP_Header_Param = 16'h8080, // 版本号（V=2） + 填充位（P=0） + 扩展位（X=0） + CSRC 计数（CC=0）
                                         // + 标记位（M=0） + 负载类型（PT=0）
  parameter SSRC = 32'h12345678, // SSRC 设置为常量值，例如，这里设置为 32 位的常量值 0x12345678
  parameter UDP_LENGTH = 960    
)(
    input                   clk,
    input                   rst_n,

    output signed [15:0]    wav_in_data,
    output                  wav_wren,

    output                  udp_send_data_valid,
    input                   udp_send_data_ready,
    output reg [UDP_LENGTH:0]udp_send_data,
    output [15:0]           udp_send_data_length,

    input                   udp_rec_data_valid,
    input [7:0]             udp_rec_rdata,
    input [15:0]            udp_rec_data_length
);

reg [15:0] sequence_number; // 序列号
reg [31:0] timestamp; // 时间戳
reg [15:0] wav_in_data_reg; 
reg [8:0]    state  ;
reg [8:0]    state_n ;

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

always @(posedge rgmii_clk)
begin
    if (~rstn)
        state  <=  IDLE  ;
    else
        state  <= state_n ;
end

assign udp_send_data[UDP_LENGTH:UDP_LENGTH-15] = RTP_Header_Param;
assign udp_send_data[UDP_LENGTH-64:UDP_LENGTH-95] = SSRC;
// 在时钟上升沿处理
always @(posedge clk) begin
  // 每个时钟周期重置计数器
  if (rst_n) begin
    sequence_number <= 0;
    timestamp <= 0;
  end
  else (wav_wden)begin
    udp_send_data[UDP_LENGTH-16:UDP_LENGTH-31] = sequence_number;
    udp_send_data[UDP_LENGTH-31:UDP_LENGTH-63] = timestamp;
    sequence_number <= sequence_number + 1'b1;
    timestamp <= timestamp + 1'b1;
    wav_in_data_reg <= wav_in_data;
  end
end


endmodule
