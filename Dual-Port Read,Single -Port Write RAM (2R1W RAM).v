// Dual Read, Single Write RAM (64x8)
module RAM_2R1W(
    input [7:0] wr_data,          // Write data
    input [5:0] wr_addr,          // Write address
    input [5:0] rd_addr1,         // First read address
    input [5:0] rd_addr2,         // Second read address
    input wr_en,                  // Write enable
    input clk,                    // Clock
    input en,                     // Global enable
    output reg [7:0] rd_data1,    // First read output
    output reg [7:0] rd_data2     // Second read output
);
    
    reg [7:0] ram[0:63];         // Memory array: 64 locations x 8-bit

    // Write operation
    always @(posedge clk) begin
        if(en && wr_en) begin
            ram[wr_addr] <= wr_data;    // Write operation
        end
    end

    // Read operations (can happen simultaneously)
    always @(posedge clk) begin
        if(en) begin
            rd_data1 <= ram[rd_addr1];  // First read operation
            rd_data2 <= ram[rd_addr2];  // Second read operation
        end
        else begin
            rd_data1 <= 8'bz;           // High impedance when disabled
            rd_data2 <= 8'bz;
        end
    end
endmodule

// Testbench for Dual Read, Single Write RAM
module RAM_2R1W_tb;
    reg [7:0] wr_data;
    reg [5:0] wr_addr, rd_addr1, rd_addr2;
    reg wr_en, clk, en;
    wire [7:0] rd_data1, rd_data2;
    integer i;

    // Instantiate RAM
    RAM_2R1W ram_inst(
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
        $dumpfile("ram_2r1w_wave.vcd");
        $dumpvars(0, RAM_2R1W_tb);

        // Initialize signals
        wr_data = 0;
        wr_addr = 0;
        rd_addr1 = 0;
        rd_addr2 = 0;
        wr_en = 0;
        en = 0;
        @(posedge clk);

        // Enable RAM
        en = 1;
        wr_en = 1;
        
        // Write sequential data
        for(i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            wr_addr = i;
            wr_data = {4'h1, i[3:0]};  // Generate 10, 11, 12, 13, 14, 15, 16, 17
            @(posedge clk);
        end

        // Additional write tests
        @(posedge clk);
        wr_addr = 6'h20;
        wr_data = 8'hAA;
        @(posedge clk);

        wr_addr = 6'h3F;
        wr_data = 8'hFF;
        @(posedge clk);

        // Test simultaneous reads
        wr_en = 0;  // Disable writing
        
        // Read from two different addresses simultaneously
        for(i = 0; i < 7; i = i + 1) begin
            @(posedge clk);
            rd_addr1 = i;
            rd_addr2 = i + 1;
            @(posedge clk);
            $display("Time=%0t Read1 Addr=%h Data1=%h, Read2 Addr=%h Data2=%h",
                     $time, rd_addr1, rd_data1, rd_addr2, rd_data2);
        end

        // Test reading from specific locations
        @(posedge clk);
        rd_addr1 = 6'h20;
        rd_addr2 = 6'h3F;
        @(posedge clk);
        $display("Special Read: Addr1=20h Data1=%h, Addr2=3Fh Data2=%h",
                 rd_data1, rd_data2);

        // Test disabled state
        en = 0;
        @(posedge clk);

        #20 $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t en=%b wr_en=%b wr_addr=%h wr_data=%h rd_addr1=%h rd_data1=%h rd_addr2=%h rd_data2=%h",
                 $time, en, wr_en, wr_addr, wr_data, rd_addr1, rd_data1, rd_addr2, rd_data2);
    end
endmodule
