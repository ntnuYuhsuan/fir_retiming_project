// src/fir_original.v (Verilog-2001 style)
module fir_original #(
    parameter N_TAPS = 4,         // For this version, assume N_TAPS will be 4
    parameter DATA_WIDTH = 18,
    parameter COEFF_WIDTH = 18
    // Constraint: This version is simplified for N_TAPS=4
) (
    input clk,
    input reset_n,
    input ena,
    input signed [DATA_WIDTH-1:0] data_in,
    output signed [(DATA_WIDTH + COEFF_WIDTH + 2)-1:0] data_out // $clog2(4) = 2
);

    localparam OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + 2; // Manual $clog2(4)
    localparam PRODUCT_WIDTH = DATA_WIDTH + COEFF_WIDTH;

    // Filter coefficients (hardcoded for N_TAPS = 4)
    localparam signed [COEFF_WIDTH-1:0] b0 = 18'd10;
    localparam signed [COEFF_WIDTH-1:0] b1 = 18'd20;
    localparam signed [COEFF_WIDTH-1:0] b2 = 18'd30;
    localparam signed [COEFF_WIDTH-1:0] b3 = 18'd40;

    // Delay line registers
    reg signed [DATA_WIDTH-1:0] delay_line [0:N_TAPS-1];
    
    // Product terms
    wire signed [PRODUCT_WIDTH-1:0] product [0:N_TAPS-1];

    // Accumulated sum (combinational)
    wire signed [OUTPUT_WIDTH-1:0] acc_sum;
    
    // Intermediate wire for output to avoid direct connection from reg to output for clarity
    // wire signed [OUTPUT_WIDTH-1:0] data_out_wire; // Not strictly needed if data_out is wire

    integer i; // For loops in Verilog-2001 always blocks (if used for sequential logic assignment)
               // Not used in this current hardcoded version's combinational assignments.

    // Input data register and delay line
    always @(posedge clk or negedge reset_n) begin
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

    // Multiplication (combinational)
    // For N_TAPS = 4
    assign product[0] = delay_line[0] * b0;
    assign product[1] = delay_line[1] * b1;
    assign product[2] = delay_line[2] * b2;
    assign product[3] = delay_line[3] * b3;

    // Accumulation (combinational)
    // For N_TAPS = 4
    assign acc_sum = product[0] + product[1] + product[2] + product[3];
    
    // Output assignment
    // In Verilog-2001, output port can be declared as wire (implicitly) or reg.
    // If it's an output of a combinational block, it's typically a wire.
    // If it's directly from a sequential block, it's a reg.
    // Here, data_out is combinationally derived from acc_sum.
    assign data_out = acc_sum;

endmodule 