// Dual Read, Single Write RAM with clock gating and reset (64x8)
module RAM_2R1W(
    input [7:0] wr_data,           
    input [5:0] wr_addr,           
    input [5:0] rd_addr1,          
    input [5:0] rd_addr2,          
    input wr_en,                    
    input clk,                      
    input rst_n,                    // Active low reset
    input en,                       
    output reg [7:0] rd_data1,    
    output reg [7:0] rd_data2     
);
    
    reg [7:0] ram[0:63];        
    reg latch_en;                 // Latch for glitch-free clock gating
    wire gated_clk;              // Internal gated clock

    // Initialize memory on reset
    integer i;
    always @(negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) begin
                ram[i] <= 8'h00;
            end
            // rd_data1 <= 8'h00;
            // rd_data2 <= 8'h00;
            // latch_en <= 1'b0;
        end
    end

    // Latch-based clock gating (integrated)
    always @(clk or en or rst_n) begin
        if (!rst_n)
            latch_en <= 1'b0;
        else if (!clk)
            latch_en <= en;
    end
    
    // Generate gated clock
    assign gated_clk = clk && latch_en;

    // Write operation using gated clock
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset handled in the reset block
        end
        else if (wr_en) begin
            ram[wr_addr] <= wr_data;    
        end
    end

    // Read operations using gated clock
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data1 <= 8'h00;
            rd_data2 <= 8'h00;
        end
        else begin
            rd_data1 <= ram[rd_addr1];  
            rd_data2 <= ram[rd_addr2];  
        end
    end

    // High impedance control
    always @(*) begin
        if(!en || !rst_n) begin
            rd_data1 = 8'h00;          // Default to 0 instead of Z for better synthesis
            rd_data2 = 8'h00;
        end
    end

endmodule
