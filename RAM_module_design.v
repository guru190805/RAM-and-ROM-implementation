// RAM module with synchronous read/write operations (64x8)
module RAM(data, r, address, clk, en, out);
    input [7:0] data;        // Input data
    input [5:0] address;     // Address bus
    input r, en, clk;        // Control signals
    output reg [7:0] out;    // Output data
    
    reg [7:0] ram[0:63];     // Memory array: 64 locations x 8-bit

    always @(posedge clk) begin
        if(en) begin
            if(r) out <= ram[address];      // Read operation
            else ram[address] <= data;       // Write operation
        end
        else out <= 8'bz;                   // High impedance when disabled
    end
endmodule

module RAM_tb;
    reg [7: 0] data;
    reg [5: 0] address;
    reg r,  en,  clk;
    wire [7: 0] out;
    integer i;

    RAM ram_inst(data, r, address, clk, en, out);

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        $dumpfile("ram_wave.vcd");
        $dumpvars(0, RAM_tb);

        // Initialize signals
        data = 0;
        address = 0;
        r = 0;
        en = 0;
        @(posedge clk);

        // Write Test
        en = 1;
        r = 0;
        
        // Write sequential data with proper timing
        for(i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            address = i;
            data = {4'h1, i[3:0]};  // This will generate 10,11,12,13,14,15,16,17
            @(posedge clk);
        end

        // Additional write tests
        @(posedge clk);
        address = 6'h20;
        data = 8'hAA;
        @(posedge clk);

        address = 6'h3F;
        data = 8'hFF;
        @(posedge clk);

        // Read Test
        r = 1;
        
        // Read back sequential data
        for(i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            address = i;
            @(posedge clk);
            $display("Read Address %h: Data = %h", address, out);
        end

        // Read specific locations
        @(posedge clk);
        address = 6'h20;
        @(posedge clk);
        $display("Read Address 20: Data = %h", out);

        @(posedge clk);
        address = 6'h3F;
        @(posedge clk);
        $display("Read Address 3F: Data = %h", out);

        // Test disabled state
        en = 0;
        @(posedge clk);

        #20 $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t en=%b r=%b addr=%h data=%h out=%h", 
                 $time, en, r, address, data, out);
    end
endmodule