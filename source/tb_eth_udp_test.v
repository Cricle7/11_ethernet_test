`timescale 1ns / 1ps

module tb_eth_udp_test();

    // Parameters
    localparam CLK_PERIOD = 20; // Clock period in ns

    // Inputs
    reg rgmii_clk = 0;
    reg rstn = 0;
    reg gmii_rx_dv = 0;
    reg [7:0] gmii_rxd = 0;

    // Outputs
    wire gmii_tx_en;
    wire [7:0] gmii_txd;
    wire udp_rec_data_valid;
    wire [7:0] udp_rec_rdata;
    wire [15:0] udp_rec_data_length;

    GTP_GRS GRS_INST(
        .GRS_N(1'b1)
        ) ;
    // Instantiate DUT
    eth_udp_test #(
        .LOCAL_MAC(48'h11_11_11_11_11_11),
        .LOCAL_IP(32'hC0_A8_01_6E),
        .LOCL_PORT(16'h8080),
        .DEST_IP(32'hC0_A8_01_69),
        .DEST_PORT(16'h8080)
    ) dut (
        .rgmii_clk(rgmii_clk),
        .rstn(rstn),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rxd(gmii_rxd),
        .gmii_tx_en(gmii_tx_en),
        .gmii_txd(gmii_txd),
        .udp_rec_data_valid(udp_rec_data_valid),
        .udp_rec_rdata(udp_rec_rdata),
        .udp_rec_data_length(udp_rec_data_length)
    );

    // Clock generation
    always #(CLK_PERIOD / 2) rgmii_clk = ~rgmii_clk;

    // Initial stimulus
    initial begin
        // Reset
        rstn = 0;
        #10;
        rstn = 1;

        // Add your test stimulus here
        // gmii_rx_dv, gmii_rxd should be driven accordingly

        // Monitor outputs
        //$monitor("Time=%0t, gmii_tx_en=%b, gmii_txd=%h, udp_rec_data_valid=%b, udp_rec_rdata=%h, udp_rec_data_length=%d", $time, gmii_tx_en, gmii_txd, udp_rec_data_valid, udp_rec_rdata, udp_rec_data_length);
        
        // End simulation after some time
        #1000;
        //$finish;
    end

    initial begin
        $fsdbDumpvars;
        $fsdbDumpfile("tb.fsdb");
        #3_000_000_000
        $finish;
    end
endmodule
