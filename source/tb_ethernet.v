`timescale 1ns / 1ps

module tb_ethernet();

    // Parameters
    localparam CLK_PERIOD = 20; // Clock period in ns

    // Inputs
    reg clk_50m = 0;
    reg rgmii_rxc = 0;
    reg rgmii_rx_ctl = 0;
    reg [3:0] rgmii_rxd = 0;

    // Outputs
    wire led;
    wire phy_rstn;
    wire rgmii_txc;
    wire rgmii_tx_ctl;
    wire [3:0] rgmii_txd;

    GTP_GRS GRS_INST(
        .GRS_N(1'b1)
        ) ;


    // Instantiate DUT
    ethernet_test #(
        .LOCAL_MAC(48'ha0_b1_c2_d3_e1_e1),
        .LOCAL_IP(32'hC0_A8_01_0B),
        .LOCL_PORT(16'h1F90),
        .DEST_IP(32'hC0_A8_01_69),
        .DEST_PORT(16'h1F90)
    ) dut (
        .clk_50m(clk_50m),
        .led(led),
        .phy_rstn(phy_rstn),
        .rgmii_rxc(rgmii_rxc),
        .rgmii_rx_ctl(rgmii_rx_ctl),
        .rgmii_rxd(rgmii_rxd),
        .rgmii_txc(rgmii_txc),
        .rgmii_tx_ctl(rgmii_tx_ctl),
        .rgmii_txd(rgmii_txd)
    );

    // Clock generation
    always #(CLK_PERIOD / 2) clk_50m = ~clk_50m;

    // Initial stimulus
    initial begin
        // Reset
        // Add your test stimulus here
        // rgmii_rxc, rgmii_rx_ctl, rgmii_rxd should be driven accordingly

        // Monitor outputs
        $monitor("Time=%0t, led=%b, rgmii_txc=%b, rgmii_tx_ctl=%b, rgmii_txd=%h", $time, led, rgmii_txc, rgmii_tx_ctl, rgmii_txd);
        
        // End simulation after some time
        //#100000;
        //$finish;
    end

endmodule
