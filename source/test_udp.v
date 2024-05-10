`timescale 1ns / 1ns

module test_udp;

  reg rgmii_clk;
  reg udp_rec_data_valid;
  reg [7:0] udp_rec_rdata;
  
  wire [1279:0] test_data_rx; // Assuming 160 * 8 bits for test_data_rx

  // Instantiate the module under test
  your_module_under_test dut (
    .rgmii_clk(rgmii_clk),
    .udp_rec_data_valid(udp_rec_data_valid),
    .udp_rec_rdata(udp_rec_rdata),
    .test_data_rx(test_data_rx)
  );

  // Clock generation
  always #5 rgmii_clk = ~rgmii_clk;

  // Test stimulus
  initial begin
    // Initialize inputs
    rgmii_clk = 0;
    udp_rec_data_valid = 0;
    udp_rec_rdata = 8'h00;

    // Apply reset if needed

    // Test case 1: udp_rec_data_valid is de-asserted
    #10;
    udp_rec_data_valid = 1;
    udp_rec_rdata = 8'hFF;
    #100;
    udp_rec_data_valid = 0;

    // Test case 2: udp_rec_data_valid is asserted, verify shifting and updating of test_data_rx
    #10;
    udp_rec_data_valid = 1;
    udp_rec_rdata = 8'hAA; // Example test data
    #100; // Wait for some cycles to observe the shift operation

    // Verify test_data_rx
    if (test_data_rx !== {test_data_rx[159*8-1-7: 1], udp_rec_rdata})
      $display("Test failed: Incorrect shifting and updating of test_data_rx");
    else
      $display("Test passed: Correct shifting and updating of test_data_rx");
      
    // End simulation
    $finish;
  end

endmodule
