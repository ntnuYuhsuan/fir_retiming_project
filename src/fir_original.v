// src/fir_original.v
module fir_original #(
    parameter N_TAPS = 4,
    parameter DATA_WIDTH = 18,
    parameter COEFF_WIDTH = 18
    // Constraint: This version of fir_original is hardcoded for N_TAPS=4
    // due to coefficient definition and internal logic.
) (
    input clk,
    input reset_n,
    input ena,
    input signed [DATA_WIDTH-1:0] data_in,
    output logic signed [(DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS))-1:0] data_out
);
    // Ensure N_TAPS is 4 for this specific coefficient set and logic
    initial begin
        if (N_TAPS != 4) begin
            $display("Error: This fir_original module is configured with N_TAPS=%0d, but hardcoded for N_TAPS=4.", N_TAPS);
            $finish;
        end
    end

    localparam OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS); // $clog2(4) is 2
    localparam PRODUCT_WIDTH = DATA_WIDTH + COEFF_WIDTH;

    // Filter coefficients (hardcoded for N_TAPS = 4)
    localparam signed [COEFF_WIDTH-1:0] b0 = 18'd10;
    localparam signed [COEFF_WIDTH-1:0] b1 = 18'd20;
    localparam signed [COEFF_WIDTH-1:0] b2 = 18'd30;
    localparam signed [COEFF_WIDTH-1:0] b3 = 18'd40;

    // Delay line registers (sized by N_TAPS, but logic below is for 4 taps)
    logic signed [DATA_WIDTH-1:0] delay_line [N_TAPS-1:0]; 
    
    // Product terms (sized by N_TAPS, but logic below is for 4 taps)
    logic signed [PRODUCT_WIDTH-1:0] product [N_TAPS-1:0];

    // Accumulated sum (combinational)
    logic signed [OUTPUT_WIDTH-1:0] acc_sum;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            delay_line[0] <= {DATA_WIDTH{1'b0}};
            delay_line[1] <= {DATA_WIDTH{1'b0}};
            delay_line[2] <= {DATA_WIDTH{1'b0}};
            delay_line[3] <= {DATA_WIDTH{1'b0}};
        end else if (ena) begin
            delay_line[0] <= data_in;
            delay_line[1] <= delay_line[0];
            delay_line[2] <= delay_line[1];
            delay_line[3] <= delay_line[2];
        end
    end

    // Multiplication (combinational, hardcoded for N_TAPS = 4)
    assign product[0] = delay_line[0] * b0;
    assign product[1] = delay_line[1] * b1;
    assign product[2] = delay_line[2] * b2;
    assign product[3] = delay_line[3] * b3;

    // Accumulation (combinational, hardcoded for N_TAPS = 4)
    always_comb begin
        acc_sum = product[0] + product[1] + product[2] + product[3];
    end
    
    assign data_out = acc_sum;

endmodule 