module net_top #(
  parameter RTP_Header_Param = 16'h8080, // 版本号（V=2） + 填充位（P=0） + 扩展位（X=0） + CSRC 计数（CC=0）
                                         // + 标记位（M=0） + 负载类型（PT=0）
  parameter SSRC = 32'h12345678, // SSRC 设置为常量值，例如，这里设置为 32 位的常量值 0x12345678
  parameter UDP_LENGTH = 960    //一定要保证payload_length为整数
)(
  input                   clk,
  input                   rst_n,

  input signed [15:0]     wav_in_data,
  input                   wav_wren,

  output                  udp_send_data_valid,
  input                   udp_send_data_ready,
  output [UDP_LENGTH:0]   udp_send_data,
  output [15:0]           udp_send_data_length,

  input                   udp_rec_data_valid,
  input [7:0]             udp_rec_rdata,
  input [15:0]            udp_rec_data_length
);

parameter RTP_HEADER_LENGTH     = 12;
parameter PAYLOAD_LENGTH        = (UDP_LENGTH-RTP_HEADER_LENGTH)/2 ;
parameter PAYLOAD_LENGTH_BIT    = 16*PAYLOAD_LENGTH ;
parameter UDP_LENGTH_BIT        = 8*UDP_LENGTH ;

reg [15:0] sequence_number; // 序列号
reg [31:0] timestamp; // 时间戳
reg [15:0] wav_in_data_reg; 
reg [PAYLOAD_LENGTH_BIT:0] payload; 
reg [15:0] payload_cnt; 

reg [3:0]    state  ;
reg [3:0]    state_n ;

parameter IDLE          = 3'b001 ;
parameter WRITE_RAM     = 3'b010 ;
parameter SEND          = 3'b100 ;

always @(posedge clk) begin
    if (~rst_n)
        state  <=  IDLE  ;
    else
        state  <= state_n ;
end
always @(*) begin
  case (state)
    IDLE:state_n = (wav_wren)?WRITE_RAM:state; 
    WRITE_RAM:state_n = (payload_cnt == PAYLOAD_LENGTH-1)?SEND:state; 
    SEND:state_n = (udp_send_data_ready)?IDLE:state; 
    default:state_n = IDLE; 
  endcase
end
assign udp_send_data[UDP_LENGTH_BIT:UDP_LENGTH_BIT-15] = RTP_Header_Param;
assign udp_send_data[UDP_LENGTH_BIT-64:UDP_LENGTH_BIT-95] = SSRC;
assign udp_send_data[UDP_LENGTH_BIT-96:0] = payload;
assign udp_send_data[UDP_LENGTH_BIT-16:UDP_LENGTH_BIT-31] = sequence_number;
assign udp_send_data[UDP_LENGTH_BIT-31:UDP_LENGTH_BIT-63] = timestamp;
assign udp_send_data_valid = (state == SEND)? 1'b1:0;
// 在时钟上升沿处理
always @(posedge clk) begin
  // 每个时钟周期重置计数器
  if (~rst_n) begin
    sequence_number <= 0;
    timestamp <= 0;
  end
  else if(wav_wren)begin
    sequence_number <= sequence_number + 1'b1;
    timestamp <= timestamp + 1'b1;
    wav_in_data_reg <= wav_in_data;
  end
end

always @(posedge clk) begin
  if (wav_wren) begin
    if (state == WRITE_RAM) begin
      payload_cnt <= payload_cnt + 1'b1;
      payload <= {payload[PAYLOAD_LENGTH_BIT-1-15: 0],wav_in_data};
    end
    else begin
      payload_cnt <= 0;
    end
  end
end


endmodule
