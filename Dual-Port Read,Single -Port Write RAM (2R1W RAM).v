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

//Test_bench
module RAM_2R1W_tb;
    // Testbench signals
    reg [7: 0] wr_data;
    reg [5: 0] wr_addr;
    reg [5: 0] rd_addr1;
    reg [5: 0] rd_addr2;
    reg wr_en;
    reg clk;
    reg en;
    wire [7: 0] rd_data1;
    wire [7: 0] rd_data2;
    
    integer i;

    // Instantiate RAM module
    RAM_2R1W ram_inst (
        .wr_data(wr_data),
        .wr_addr(wr_addr),
        .rd_addr1(rd_addr1),
        .rd_addr2(rd_addr2),
        .wr_en(wr_en),
        .clk(clk),
        .en(en),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // VCD file generation
        $dumpfile("ram_2r1w.vcd");
        $dumpvars(0, RAM_2R1W_tb);

        // Initialize signals
        wr_data = 0;
        wr_addr = 0;
        rd_addr1 = 0;
        rd_addr2 = 0;
        wr_en = 0;
        en = 0;
        
        // Wait for a few clock cycles
        repeat(3) @(posedge clk);

        // Test 1: Write Operation with Clock Gating
        en = 1;
        wr_en = 1;
        
        // Write sequential data
        for(i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            wr_addr = i;
            wr_data = i + 8'h10; // Write pattern: 0x10, 0x11, 0x12...
            @(posedge clk);
            $display("Writing: Addr=%h, Data=%h", wr_addr, wr_data);
        end

        // Test 2: Simultaneous Read Operations
        wr_en = 0;
        for(i = 0; i < 7; i = i + 1) begin
            @(posedge clk);
            rd_addr1 = i;
            rd_addr2 = i + 1;
            @(posedge clk);
            $display("Reading: Addr1=%h Data1=%h, Addr2=%h Data2=%h", 
                     rd_addr1, rd_data1, rd_addr2, rd_data2);
        end

        // Test 3: Clock Gating Test
        @(posedge clk);
        en = 0; // Disable clock
        wr_en = 1;
        wr_addr = 6'h0F;
        wr_data = 8'hFF;
        @(posedge clk);
        $display("Clock Gated: Write should not occur");

        // Test 4: Re-enable and verify
        @(posedge clk);
        en = 1;
        rd_addr1 = 6'h0F;
        @(posedge clk);
        $display("Verify after clock gating: Addr=%h Data=%h", 
                 rd_addr1, rd_data1);
          // Test 5: High Impedance Test
        @(posedge clk);
        en = 0;
        @(posedge clk);
        $display("High-Z Test: Data1=%h Data2=%h", rd_data1, rd_data2);

        // End simulation
        #20 $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t en=%b wr_en=%b wr_addr=%h wr_data=%h rd1=%h rd2=%h", 
                 $time, en, wr_en, wr_addr, wr_data, rd_data1, rd_data2);
    end

endmodule
