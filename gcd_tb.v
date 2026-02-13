`timescale 1ns / 1ps

module gcd_tb();
    parameter W = 16;
    reg clk, reset, data_rdy, result_taken;
    reg [W-1:0] operands_bits_A, operands_bits_B;
    wire result_rdy;
    wire [W-1:0] result_bits_data;

    gcd #(W) uut (
        .clk(clk), .reset(reset), .data_rdy(data_rdy),
        .operands_bits_A(operands_bits_A), .operands_bits_B(operands_bits_B),
        .result_taken(result_taken), .result_rdy(result_rdy),
        .result_bits_data(result_bits_data)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task with delayed transitions to avoid simulation race conditions
    task do_gcd(input [W-1:0] valA, input [W-1:0] valB);
        begin
            @(posedge clk); 
            #1; // Delay input to ensure it's sampled on the NEXT edge
            operands_bits_A = valA;
            operands_bits_B = valB;
            data_rdy = 1;
            
            @(posedge clk);
            #1;
            data_rdy = 0;
            
            // Wait for FSM to complete the calculation
            wait(result_rdy);
            $display("GCD(%0d, %0d) = %0d", valA, valB, result_bits_data);
            
            @(posedge clk);
            #1;
            result_taken = 1; // Acknowledge result
            @(posedge clk);
            #1;
            result_taken = 0;
        end
    endtask

    initial begin
        // Initialize signals
        reset = 1; data_rdy = 0; result_taken = 0;
        operands_bits_A = 0; operands_bits_B = 0;

        // Reset Sequence
        #25 reset = 0;
        #20;

        $display("--- Starting Extended GCD Tests ---");

        // Case 1: Standard case
        do_gcd(48, 18);   // Result: 6

        // Case 2: Prime numbers
        do_gcd(13, 7);    // Result: 1

        // Case 3: A is multiple of B
        do_gcd(100, 25);  // Result: 25

        // Case 4: B is larger than A (Triggers the SWAP logic)
        do_gcd(12, 60);   // Result: 12

        // Case 5: Large values
        do_gcd(1024, 128);// Result: 128

        // Case 6: Relatively prime large numbers
        do_gcd(525, 100); // Result: 25

        // Case 7: GCD with 1
        do_gcd(99, 1);    // Result: 1

        // Case 8: Both numbers same
        do_gcd(37, 37);   // Result: 37

        #100;
        $display("--- All Test Cases Finished ---");
        $finish;
    end
endmodule
