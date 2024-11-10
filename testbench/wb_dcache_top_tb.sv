`ifndef VERILATOR
`include "../defines/cache_defs.svh"
`else
`include "cache_defs.svh"
`endif

parameter NUM_LINES = 2048;

module wb_dcache_top_tb();

    logic                        clk;
    logic                        rst_n;
    logic                        dmem_sel_i;
    logic                        dcache_flush_i;
    logic                        dcache_kill_i;

    // LSU/MMU to data cache interface
    type_lsummu2dcache_s        lsummu2dcache_i;
    type_dcache2lsummu_s        dcache2lsummu_o;
  
    // Data cache to data memory interface  
    type_mem2dcache_s           mem2dcache_i;
    type_dcache2mem_s           dcache2mem_o;
    logic                       dcache2mem_kill_o;

    logic [`XLEN-1:0] mem [0:NUM_LINES-1]; 

    typedef logic [`XLEN-1:0] mem_data_t;  // Define the data width for the associative array
    // Associative array for reference memory
    mem_data_t reference_mem [bit[31:0]];  // Associative array with 32-bit address keys

    wb_dcache_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .dmem_sel_i(dmem_sel_i),
        .dcache_flush_i(dcache_flush_i),
        .dcache_kill_i(dcache_kill_i),
        .lsummu2dcache_i(lsummu2dcache_i),
        .dcache2lsummu_o(dcache2lsummu_o),
        .mem2dcache_i(mem2dcache_i),
        .dcache2mem_o(dcache2mem_o),
        .dcache2mem_kill_o(dcache2mem_kill_o)
    );


    initial begin
        $dumpfile("wb_dcache_top_tb.vcd");
        $dumpvars(0, wb_dcache_top_tb);

        $readmemh("testbench/hello.hex", mem);
        clk = 1;
        forever #5 clk = ~clk;
    end
    
    initial begin
        // Reset Sequence 
        reset(5);
        // Initial values of signal
        init_sequence();
        // Directed Tests 
//         cpu(0, 0, 32'hx, 0);
//         cpu(0, 0, 32'hx, 4);
//         cpu(0, 0, 32'hx, 8);
//         cpu(0, 0, 32'hx, 12);
//         // Reading the cache with different addr
//         cpu(0, 0, 32'hx, 16);
//         cpu(0, 0, 32'hx, 20);
//         cpu(0, 0, 32'hx, 24);
//         cpu(0, 0, 32'hx, 28);
//         // Writing cache from cpu data and then Reading 
//         cpu(1, 0, 32'h4, 20);
//         cpu(0, 0, 32'h4, 20);
//         // Reading the cache with different tag but same index to check for dirty bit and then write to the main memory
//         cpu(0, 0, 32'hx, 32'hC0000010);
//         cpu(0, 0, 32'hx, 32'hC0000014);
//         cpu(0, 0, 32'hx, 32'hC0000018);
//         cpu(0, 0, 32'hx, 32'hC000001C);
        // Flush the cache
//         cpu(0, 1, 32'hx, 32'hC000001C);
//         dcache_flush_i = 0;
//         repeat(4) @(posedge clk);

        fork 
            driver();
            monitor();
        join
//         $display("Valid Writes = %d Valid Reads = %d", valid_write_count, valid_read_count);
        $finish;
    end
    
    initial begin
        forever begin
            memory(dcache2mem_o.addr);
            @(posedge clk);
        end
    end

    task init_sequence;
        mem2dcache_i.ack = 0;
        lsummu2dcache_i.req = 0;
        lsummu2dcache_i.w_en = 0;
        lsummu2dcache_i.sel_byte = 4'hF;
        dmem_sel_i = 1;
        dcache_flush_i = 0;
        dcache_kill_i = 0;
    endtask

    task reset(input logic [7:0] a);
        rst_n = 1;
        #a rst_n = 0;
        #a rst_n = 1;
    endtask

    task cpu(input logic operation, input logic fls, input logic [`XLEN-1:0] data_from_cpu, input logic [`XLEN-1:0] addr);
        lsummu2dcache_i.w_en <= operation;
        lsummu2dcache_i.addr <= addr;
        lsummu2dcache_i.w_data <= data_from_cpu;
        dcache_flush_i <= fls;
        lsummu2dcache_i.req <= 1;
        while (!dcache2lsummu_o.ack) @(posedge clk);
//         @(posedge clk);
//         if (operation) begin
//             mem_main[address] = data_from_cpu;
//         end else if (dut.hit) begin
//             mem_main[address] = read_data_cpu;
//         end
        dcache_flush_i <= 0;
        lsummu2dcache_i.req <= 0;
        @(posedge clk);
//         while (!cpu_ready) @(posedge clk);
    endtask

    task memory(input logic [`XLEN-1:0] addr);
        if (dcache2mem_o.w_en && dcache2mem_o.req) begin
            {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]} <= dcache2mem_o.w_data;
            repeat(1) @(posedge clk);
            mem2dcache_i.ack <= 1;
            @(posedge clk);
            mem2dcache_i.ack <= 0;
        end else if (dcache2mem_o.req) begin
            mem2dcache_i.r_data <= {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]};
            repeat(1) @(posedge clk);
            mem2dcache_i.ack <= 1;
            @(posedge clk);
            mem2dcache_i.ack <= 0;
        end
    endtask

    // Driver: drives test inputs to test victim cache
    task driver();
        logic [`XLEN-1:0] write_data_A1, write_data_A2;
        logic [`XLEN-1:0] read_data;
        logic [16:0] tag_A1;
        logic [16:0] tag_A2;
        logic [10:0] index;
        logic [`XLEN-1:0] addr_A1, addr_A2;
    
//         for (int i=0; i<29; i++) begin
            // Generate random tags for A1 and A2
            tag_A1 = $urandom;
            
            // Ensure tag_A2 is different from tag_A1
            do begin
                tag_A2 = $urandom;
            end while (tag_A1 == tag_A2);
    
            // Generate a random index to simulate different cache lines
            index = $urandom;
    
            // Combine tag and index to create addresses A1 and A2
            addr_A1 = {tag_A1, index, 4'b0}; // Address A1 with specific index and tag
            addr_A2 = {tag_A2, index, 4'b0}; // Address A2 with same index, different tag
    
            // addr_A1 = 32'h0001_0000; // Address A1 with specific index and tag
            // addr_A2 = 32'h0011_0000; // Address A2 with same index, different tag

            // Step 1: Write to A1
            write_data_A1 = $random;
            cpu(1, 0, write_data_A1, addr_A1); 
            reference_mem[addr_A1] = write_data_A1; // Store in reference memory
    
            // Step 2: Write to A2 (evict A1 to victim cache)
            write_data_A2 = $random;
            cpu(1, 0, write_data_A2, addr_A2);
//             reference_mem[addr_A2] = write_data_A2; // Store in reference memory
    
            // Step 3: Access A1 again (this should come from victim cache, not main memory)
            cpu(1, 0, 32'hA, addr_A1); 
            cpu(0, 0, 32'hA, addr_A1); 

    
            @(posedge clk); // Allow some time for response
            $display("1");
//         end
    endtask
    
    task monitor();
//         for (int i=0; i<29; i++) begin
            // For Addr A1
            while (!dcache2lsummu_o.ack) @(posedge clk);
            @(posedge clk);
            // For Addr A2
            while (!dcache2lsummu_o.ack) @(posedge clk);
            @(posedge clk);
            // For Testing Victim case
            while (!mem2dcache_i.ack) begin
                // Check for A1 (evicted case)
                @(posedge clk);
                if (dcache2lsummu_o.ack) begin
                    if (reference_mem.exists(lsummu2dcache_i.addr)) begin
                        if (dcache2lsummu_o.r_data == reference_mem[lsummu2dcache_i.addr]) begin
                            $display("Pass: Addr: %h Expected Data: %h Observed Data: %h", lsummu2dcache_i.addr, reference_mem[lsummu2dcache_i.addr], dcache2lsummu_o.r_data);
                            break;
                        end else begin
                            $display("Fail: Addr: %h Expected Data: %h Observed Data: %h", lsummu2dcache_i.addr, reference_mem[lsummu2dcache_i.addr], dcache2lsummu_o.r_data);
                            break;
                        end
                    end else begin
                        $display("Error: Address %h not found in reference memory!", lsummu2dcache_i.addr);
                        break;
                    end
                end
            end
//         end
            $display("2");
    endtask

endmodule
