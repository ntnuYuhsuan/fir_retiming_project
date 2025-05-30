// src/fir_retimed.v
module fir_retimed #(
    parameter N_TAPS = 4, 
    parameter DATA_WIDTH = 18,
    parameter COEFF_WIDTH = 18
    // Constraint: This version of fir_retimed is hardcoded for N_TAPS=4
) (
    input clk,
    input reset_n,
    input ena,
    input signed [DATA_WIDTH-1:0] data_in,
    output logic signed [(DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS))-1:0] data_out
);
    // Ensure N_TAPS is 4
    initial begin
        if (N_TAPS != 4) begin
            $display("Error: This fir_retimed module is hardcoded for N_TAPS=4, but N_TAPS=%0d.", N_TAPS);
            $finish;
        end
    end

    localparam OUTPUT_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS); // For N_TAPS=4, $clog2(N_TAPS)=2
    localparam PRODUCT_WIDTH = DATA_WIDTH + COEFF_WIDTH;
    localparam INTERMEDIATE_SUM_WIDTH = OUTPUT_WIDTH; 

    // Filter coefficients (hardcoded for N_TAPS = 4)
    localparam signed [COEFF_WIDTH-1:0] b0 = 18'd10;
    localparam signed [COEFF_WIDTH-1:0] b1 = 18'd20;
    localparam signed [COEFF_WIDTH-1:0] b2 = 18'd30;
    localparam signed [COEFF_WIDTH-1:0] b3 = 18'd40;

    // Pipeline Stage 1: Input delay line (registers)
    logic signed [DATA_WIDTH-1:0] delay_line_s1 [3:0]; 
    // Combinational products after Stage 1 registers
    logic signed [PRODUCT_WIDTH-1:0] product_s1_comb [3:0]; 

    // Pipeline Stage 2: Product registers
    logic signed [PRODUCT_WIDTH-1:0] product_reg_s2 [3:0];
    // Combinational sums after Stage 2 registers
    logic signed [INTERMEDIATE_SUM_WIDTH-1:0] sum1_s2_comb;
    logic signed [INTERMEDIATE_SUM_WIDTH-1:0] sum2_s2_comb;

    // Pipeline Stage 3: Intermediate sum registers
    logic signed [INTERMEDIATE_SUM_WIDTH-1:0] sum1_reg_s3;
    logic signed [INTERMEDIATE_SUM_WIDTH-1:0] sum2_reg_s3;
    // Combinational final sum after Stage 3 registers
    logic signed [OUTPUT_WIDTH-1:0] final_sum_s3_comb;

    // Pipeline Stage 4: Output register
    logic signed [OUTPUT_WIDTH-1:0] data_out_reg_s4;

    // Stage 1: Input shift registers for delay line
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            delay_line_s1[0] <= {DATA_WIDTH{1'b0}};
            delay_line_s1[1] <= {DATA_WIDTH{1'b0}};
            delay_line_s1[2] <= {DATA_WIDTH{1'b0}};
            delay_line_s1[3] <= {DATA_WIDTH{1'b0}};
        end else if (ena) begin
            delay_line_s1[0] <= data_in;
            delay_line_s1[1] <= delay_line_s1[0];
            delay_line_s1[2] <= delay_line_s1[1];
            delay_line_s1[3] <= delay_line_s1[2];
        end
    end

    // Combinational logic after Stage 1 registers: Multiplications
    assign product_s1_comb[0] = delay_line_s1[0] * b0;
    assign product_s1_comb[1] = delay_line_s1[1] * b1;
    assign product_s1_comb[2] = delay_line_s1[2] * b2;
    assign product_s1_comb[3] = delay_line_s1[3] * b3;

    // Stage 2: Register products
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            product_reg_s2[0] <= {PRODUCT_WIDTH{1'b0}};
            product_reg_s2[1] <= {PRODUCT_WIDTH{1'b0}};
            product_reg_s2[2] <= {PRODUCT_WIDTH{1'b0}};
            product_reg_s2[3] <= {PRODUCT_WIDTH{1'b0}};
        end else if (ena) begin
            product_reg_s2[0] <= product_s1_comb[0];
            product_reg_s2[1] <= product_s1_comb[1];
            product_reg_s2[2] <= product_s1_comb[2];
            product_reg_s2[3] <= product_s1_comb[3];
        end
    end
    
    // Combinational logic after Stage 2 registers: First stage of additions
    assign sum1_s2_comb = product_reg_s2[0] + product_reg_s2[1];
    assign sum2_s2_comb = product_reg_s2[2] + product_reg_s2[3];

    // Stage 3: Register intermediate sums
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sum1_reg_s3 <= {INTERMEDIATE_SUM_WIDTH{1'b0}};
            sum2_reg_s3 <= {INTERMEDIATE_SUM_WIDTH{1'b0}};
        end else if (ena) begin
            sum1_reg_s3 <= sum1_s2_comb;
            sum2_reg_s3 <= sum2_s2_comb;
        end
    end

    // Combinational logic after Stage 3 registers: Final addition
    assign final_sum_s3_comb = sum1_reg_s3 + sum2_reg_s3;

    // Stage 4: Register final sum (output register)
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out_reg_s4 <= {OUTPUT_WIDTH{1'b0}};
        end else if (ena) begin
            data_out_reg_s4 <= final_sum_s3_comb;
        end
    end

    assign data_out = data_out_reg_s4;

endmodule 