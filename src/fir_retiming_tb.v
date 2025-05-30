// src/fir_retiming_tb.v
`timescale 1ns/1ps

module fir_retiming_tb;

    parameter N_TAPS = 4;
    parameter DATA_WIDTH = 18;
    parameter COEFF_WIDTH = 18;
    localparam OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS);
    localparam CLK_PERIOD = 10; // ns, for a 100MHz clock

    // Testbench signals
    logic clk;
    logic reset_n;
    logic ena;
    logic signed [DATA_WIDTH-1:0] data_in;
    
    logic signed [OUTPUT_WIDTH-1:0] data_out_orig;
    logic signed [OUTPUT_WIDTH-1:0] data_out_retimed;

    // Expected output for comparison (delayed version of original output)
    logic signed [OUTPUT_WIDTH-1:0] data_out_orig_delayed_1;
    logic signed [OUTPUT_WIDTH-1:0] data_out_orig_delayed_2;
    logic signed [OUTPUT_WIDTH-1:0] data_out_orig_delayed_3; // Expected delay difference is 3 cycles

    integer errors = 0;
    integer test_vectors_applied = 0; // Renamed from test_vectors to avoid confusion
    integer cycle_count = 0;
    // Start comparison after initial pipeline fill-up of both DUTs and delay line for original's output
    // Original: N_TAPS for delay line to fill for first full FIR output value (assuming comb. output)
    // Retimed: N_TAPS for its own delay line + 3 for pipeline stages (mult, sum1, sum2)
    // Delay registers for original output: 3 cycles
    // So, min cycles before retimed output is valid for first input: N_TAPS + 3
    // Min cycles before original_delayed_3 is valid for first input: N_TAPS + 3
    // Let's be generous and add a few more cycles.
    integer comparison_start_cycle = N_TAPS + 3 + 2; 

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
    always_ff @(posedge clk or negedge reset_n) begin
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
        $display("Starting FIR Retiming Testbench...");
        reset_n = 1'b0;
        ena = 1'b0;
        data_in = {DATA_WIDTH{1'b0}};
        // cycle_count is incremented at each posedge clk where input is applied
        
        #(CLK_PERIOD * 2.5); // Hold reset for a few cycles
        reset_n = 1'b1;
        $display("Cycle %0d (%0t): Reset released.", cycle_count, $time);
        
        #(CLK_PERIOD * 2); // Wait for reset to propagate
        ena = 1'b1; // Enable DUTs
        $display("Cycle %0d (%0t): Enable asserted.", cycle_count, $time);

        // Apply some test vectors
        // Vector 1: Impulse
        apply_and_log_input(18'd1);
        apply_and_log_input(18'd0);
                
        for (int i = 0; i < N_TAPS + 2; i++) begin
            apply_and_log_input(18'd0);
        end

        // Vector 2: Step input
        apply_and_log_input(18'd10);
        for (int i = 0; i < N_TAPS + 2; i++) begin
            apply_and_log_input(18'd10);
        end
        
        // Vector 3: Alternating values
        for (int i = 0; i < 10; i++) begin
            apply_and_log_input((i % 2 == 0) ? 18'd5 : 18'd-5);
        end

        for (int i = 0; i < N_TAPS + 5; i++) begin // Flush out
            apply_and_log_input(18'd0);
        end
        
        #(CLK_PERIOD * 5); // Wait a bit more
        ena = 1'b0;
        $display("Simulation finished after %0d input cycles and %0d total clock cycles.", test_vectors_applied, cycle_count);
        
        if (errors == 0) begin
            $display("TEST PASSED: All compared outputs matched.");
        end else begin
            $display("TEST FAILED: %0d mismatches found.", errors);
        end
        $finish;
    end

    // Task to apply input and increment cycle counter
    task apply_and_log_input(input signed [DATA_WIDTH-1:0] val);
        @(posedge clk);
        data_in = val;
        cycle_count++; // Counts active clock cycles where ena is high
        test_vectors_applied++;
        $display("Cycle %0d (Input Cycle %0d, Time %0t): data_in = %d", cycle_count, test_vectors_applied, $time, data_in);
    endtask

    // Output comparison logic, active only when ena is high
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Do nothing specific on reset for comparison logic itself
        end else if (ena) begin // Only compare when system is enabled
            // Start comparing after pipelines are expected to be full
            if (cycle_count >= comparison_start_cycle) begin
                if (data_out_retimed !== data_out_orig_delayed_3) begin
                    $error("Mismatch detected at active cycle %0d (Input cycle %0d, time %0t)!", cycle_count, test_vectors_applied, $time);
                    $display("  data_out_orig_delayed_3 = %d (%h)", data_out_orig_delayed_3, data_out_orig_delayed_3);
                    $display("  data_out_retimed        = %d (%h)", data_out_retimed, data_out_retimed);
                    // To see the input that caused this, one would need to trace back inputs N_TAPS+3 cycles ago
                    errors = errors + 1;
                end else begin
                    $display("Match at active cycle %0d: retimed = %d, original_delayed = %d", cycle_count, data_out_retimed, data_out_orig_delayed_3);
                end
            end
        end
    end

endmodule 