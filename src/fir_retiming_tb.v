// src/fir_retiming_tb.v (Verilog-2001 style)
`timescale 1ns/1ps

module fir_retiming_tb;

    parameter N_TAPS = 4;
    parameter DATA_WIDTH = 18;
    parameter COEFF_WIDTH = 18;
    // Manual $clog2(N_TAPS) -> $clog2(4) = 2
    localparam OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + 2; 
    localparam CLK_PERIOD = 10; // ns, for a 100MHz clock

    // Testbench signals
    reg clk;
    reg reset_n;
    reg ena;
    reg signed [DATA_WIDTH-1:0] data_in;
    
    wire signed [OUTPUT_WIDTH-1:0] data_out_orig;
    wire signed [OUTPUT_WIDTH-1:0] data_out_retimed;

    // Expected output for comparison (delayed version of original output)
    reg signed [OUTPUT_WIDTH-1:0] data_out_orig_delayed_1;
    reg signed [OUTPUT_WIDTH-1:0] data_out_orig_delayed_2;
    reg signed [OUTPUT_WIDTH-1:0] data_out_orig_delayed_3; // Expected delay difference is 3 cycles

    integer errors = 0;
    integer test_vectors_applied = 0;
    integer cycle_count = 0; // Counts active cycles when ena is high
    integer comparison_start_cycle = N_TAPS + 3 + 2; 
    integer i; // Loop variable for initial block for loops
    reg [DATA_WIDTH-1:0] temp_data_for_task; // Temporary variable for task argument (removed signed)

    // Instantiate fir_original
    fir_original #(
        .N_TAPS(N_TAPS),
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH)
    ) u_fir_original (
        .clk(clk),
        .reset_n(reset_n),
        .ena(ena),
        .data_in(data_in),
        .data_out(data_out_orig)
    );

    // Instantiate fir_retimed
    fir_retimed #(
        .N_TAPS(N_TAPS),
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH)
    ) u_fir_retimed (
        .clk(clk),
        .reset_n(reset_n),
        .ena(ena),
        .data_in(data_in),
        .data_out(data_out_retimed)
    );

    // Clock generation
    always begin
        clk = 1'b0; #(CLK_PERIOD/2);
        clk = 1'b1; #(CLK_PERIOD/2);
    end

    // Create delay registers for original output to align with retimed output
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out_orig_delayed_1 <= {OUTPUT_WIDTH{1'b0}};
            data_out_orig_delayed_2 <= {OUTPUT_WIDTH{1'b0}};
            data_out_orig_delayed_3 <= {OUTPUT_WIDTH{1'b0}};
        end else if (ena) begin // Only shift if enabled
            data_out_orig_delayed_1 <= data_out_orig;
            data_out_orig_delayed_2 <= data_out_orig_delayed_1;
            data_out_orig_delayed_3 <= data_out_orig_delayed_2;
        end
    end

    // Test sequence
    initial begin
        $dumpfile("fir_retiming.vcd");
        $dumpvars(0, fir_retiming_tb);
        $display("Starting FIR Retiming Testbench (Verilog-2001)...");
        reset_n = 1'b0;
        ena = 1'b0;
        data_in = {DATA_WIDTH{1'b0}};
        
        #(CLK_PERIOD * 2.5); 
        reset_n = 1'b1;
        $display("Time %0t: Reset released.", $time);
        
        #(CLK_PERIOD * 2); 
        ena = 1'b1; 
        $display("Time %0t: Enable asserted.", $time);

        // Apply some test vectors using a task
        apply_and_log_input(18'd1);
        apply_and_log_input(18'd0);
                
        for (i = 0; i < N_TAPS + 2; i = i + 1) begin
            apply_and_log_input(18'd0);
        end

        apply_and_log_input(18'd10);
        for (i = 0; i < N_TAPS + 2; i = i + 1) begin
            apply_and_log_input(18'd10);
        end
        
        // Vector 3: Alternating values
        for (i = 0; i < 10; i = i + 1) begin
            if (i % 2 == 0) begin
                temp_data_for_task = 18'd5;
            end else begin
                temp_data_for_task = -5;
            end
            apply_and_log_input(temp_data_for_task); // Pass the temporary variable
        end

        for (i = 0; i < N_TAPS + 5; i = i + 1) begin 
            apply_and_log_input(18'd0);
        end
        
        #(CLK_PERIOD * 5); 
        ena = 1'b0;
        // Use test_vectors_applied for the number of inputs driven when ena was potentially high
        $display("Simulation finished. %0d input vectors applied during enabled cycles. Total active cycles for comparison: %0d.", test_vectors_applied, cycle_count);
        
        if (errors == 0) begin
            // Consider if comparison actually happened by checking if cycle_count >= comparison_start_cycle at least once
            if (cycle_count == 0 && test_vectors_applied > 0) $display("Warning: ENA might have been low throughout, or cycle_count not incremented correctly.");
            if (cycle_count < comparison_start_cycle && test_vectors_applied >0) $display("Warning: Not enough active cycles (%0d) for comparison to start (needs %0d).", cycle_count, comparison_start_cycle);
            $display("TEST PASSED: %0d mismatches found.", errors); // errors should be 0 for PASS
        end else begin
            $display("TEST FAILED: %0d mismatches found.", errors);
        end
        $finish;
    end

    // Task to apply input and increment cycle counter
    task apply_and_log_input;
        input [17:0] val; // Using fixed width 18 (as DATA_WIDTH is 18)
        begin
            @(posedge clk);
            data_in = val; // data_in is signed [DATA_WIDTH-1:0]
            if (reset_n && ena) begin 
                cycle_count = cycle_count + 1; 
                test_vectors_applied = test_vectors_applied + 1; // Counts inputs when ena is high
                $display("Active Cycle %0d (Input Vector %0d, Time %0t): data_in = %d", cycle_count, test_vectors_applied, $time, data_in);
            end else if (reset_n && !ena) begin
                 $display("Input (ena low, Time %0t): data_in = %d", $time, data_in);
            end
        end
    endtask

    // Output comparison logic
    always @(posedge clk) begin
        if (reset_n && ena) begin 
            if (cycle_count >= comparison_start_cycle) begin
                if (data_out_retimed !== data_out_orig_delayed_3) begin
                    $error("Mismatch @ active cycle %0d (Input Vector %0d, Time %0t)! Orig_del=%d, Retimed=%d", 
                           cycle_count, test_vectors_applied, $time, data_out_orig_delayed_3, data_out_retimed);
                    errors = errors + 1;
                end else begin
                    $display("Match @ active cycle %0d: %d", cycle_count, data_out_retimed);
                end
            end
        end
    end

endmodule 