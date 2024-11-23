// File Description : Testbench for victim cache integrated with dcache in UET-RV PCore and for normal testing of dcache.  
// Author           : Muhammad Ehsan, Moazzam Ali.
// Date             : Nov 4, 2024.

`include "../defines/cache_defs.svh"

module tb_cache;

int no_of_cache_tests;
int cache_test_passed = 0;
int cache_test_failed = 0;

int no_of_victim_cache_tests;
int victim_cache_test_passed = 0;
int victim_cache_test_failed = 0;

type_lsummu2dcache_s  test_input, test_input_1, test_input_2, test_input_3;    

logic [4:0] deme_tag;

//=================== Declearing Input And Outputs For UUT ===================//

    logic                 clk;
    logic                 rst;

    logic                 dmem_sel_i;
    logic                 dcache_flush_i;
    logic                 dcache_kill_i;
    logic                 dcache2mem_kill_o;

    // LSU to DCACHE
    type_lsummu2dcache_s  lsummu2dcache_i;     //input  of dut
    type_dcache2lsummu_s  dcache2lsummu_o;     //output of dut

    // MEM to DCACHE
    type_mem2dcache_s     mem2dcache_i;        //input  of dut
    type_dcache2mem_s     dcache2mem_o;        //output of dut

//=============== Declearing Main Memory And Reference Memory ================//

    int main_memory [int];
    int reference_memory [int];

//=========================== Module Instantiation ===========================//

    wb_dcache_top cache_dut(        
    .clk(clk),
    .rst_n(rst),
    .dmem_sel_i(dmem_sel_i),
    .dcache_flush_i(dcache_flush_i),
    .dcache_kill_i(dcache_kill_i),

    // LSU/MMU to data cache interface
    .lsummu2dcache_i(lsummu2dcache_i),
    .dcache2lsummu_o(dcache2lsummu_o),
  
    // Data cache to main memory interface  
    .mem2dcache_i(mem2dcache_i),
    .dcache2mem_o(dcache2mem_o),
    .dcache2mem_kill_o(dcache2mem_kill_o)
);

//=========================== Generating Waveform ============================//

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0);
end

//============================= Clock Generation =============================//

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

//============================== Reset Sequence ==============================//

    task reset_circuit;
        rst = 0;
        #10;
        rst = 1;
    endtask

//========================== Initialize The Signals ==========================//

    task init_sequence;

    // LSU to DCACHE
    lsummu2dcache_i.addr      = 0;
    lsummu2dcache_i.w_data    = 0;
    lsummu2dcache_i.sel_byte  = 0;  
    lsummu2dcache_i.w_en      = 0;  
    lsummu2dcache_i.req       = 0;
    
    //MEM to DCACHE
    mem2dcache_i.r_data = 0;
    mem2dcache_i.ack    = 0;

    @(posedge clk);

    endtask

//============================ Main Meemory Driver ===========================//

    task main_mem_driver;
        logic [3:0] random_delay;
        forever begin
            while (!dcache2mem_o.req) begin
                @(posedge clk); 
            end
            
            // Write Request Case
            if (dcache2mem_o.w_en) begin
                main_memory[dcache2mem_o.addr] = dcache2mem_o.w_data;
            end

            // Read Request Case
            else begin
                // Check If Entry Exit
                if (!main_memory.exists(dcache2mem_o.addr)) begin
                    main_memory[dcache2mem_o.addr] = 32'hAAAA_AAAA;
                end
                mem2dcache_i.r_data  = main_memory[dcache2mem_o.addr];
            end
            // random_delay = $random;
            // repeat(random_delay) @(posedge clk); 
            mem2dcache_i.ack     = 1;
            @(posedge clk); 
            mem2dcache_i.ack     = 0;

        end
    endtask

//============================== Driving Inputs ==============================//

    task drive_inputs(
        input type_lsummu2dcache_s lsummu2dcache,
        input logic                r_w_req
    );
        begin
                  
            // LSU to DCACHE
            lsummu2dcache_i.w_en      =  r_w_req;       
            lsummu2dcache_i.req       =  lsummu2dcache.req;    
            lsummu2dcache_i.sel_byte  =  lsummu2dcache.sel_byte; 

            lsummu2dcache_i.addr      =  lsummu2dcache.addr;     
            lsummu2dcache_i.w_data    =  lsummu2dcache.w_data;

            while (!dcache2lsummu_o.ack) @(posedge clk);
            
            lsummu2dcache_i.req       =  0;    
            @(posedge clk);

        end
    endtask

//====================== Monitoring Outputs For Cache ========================//

    task monitor_cache;
        forever begin
            //$display("enter............ @ %0t",$time );
            // write then read from address 1
            //@(posedge lsummu2dcache_i.req);
            while (!lsummu2dcache_i.req);
            // $display("Req 1............ @ %0t",$time );
            //$display("loop1 end");
          
            @(posedge dcache2lsummu_o.ack);
            // $display("reference_memory-->lsummu2dcache_i.addr = %h, lsummu2dcache_i.w_data = %h",
            // lsummu2dcache_i.addr, lsummu2dcache_i.w_data);
            reference_memory[lsummu2dcache_i.addr] = lsummu2dcache_i.w_data;  
            // $display("Ack 1............ @ %0t",$time );
            //$display("loop2 end");

            @(posedge lsummu2dcache_i.req);
            // $display("Req 2............ @ %0t",$time );
            //while (!lsummu2dcache_i.req);
            @(posedge dcache2lsummu_o.ack);
            // $display("ACK 2............ @ %0t",$time );
            
            // $display("dcache2lsummu_o.r_data = %h, addr = %h, reference_memory[lsummu2dcache_i.addr] = %h"
            // ,dcache2lsummu_o.r_data, lsummu2dcache_i.addr, reference_memory[lsummu2dcache_i.addr]);
            if (dcache2lsummu_o.r_data == reference_memory[lsummu2dcache_i.addr]) begin
                // $display("Test passeddddddddd............ @ %0t",$time );
                cache_test_passed++;
            end else begin
                $display("Test falieddddddddd............ @ %0t",$time );
                cache_test_failed++;
            end
            // $display("Test cache_test_count............ @ %0t",$time ); 
        end
    endtask

//================== Monitoring Outputs For Victim Cache =====================//

    task monitor_victim_cache;
        forever begin
            
            // write then read from address 1
            while (!lsummu2dcache_i.req);
            // while (!dcache2lsummu_o.ack) @(posedge clk);
            @(posedge dcache2lsummu_o.ack);

            while (!lsummu2dcache_i.req) @(posedge clk);
            while (!dcache2lsummu_o.ack) @(posedge clk);
            // @(posedge lsummu2dcache_i.req);
            // @(posedge dcache2lsummu_o.ack);

            // write then read from address 2
            while (!lsummu2dcache_i.req) @(posedge clk);
            while (!dcache2lsummu_o.ack) @(posedge clk);
            // @(posedge dcache2lsummu_o.ack);

            while (!lsummu2dcache_i.req) @(posedge clk);
            while (!dcache2lsummu_o.ack) @(posedge clk);
            // @(posedge lsummu2dcache_i.req);
            // @(posedge dcache2lsummu_o.ack);

            // again write then read from address 1
            while (!lsummu2dcache_i.req);

            while (!dcache2lsummu_o.ack) begin
                
                if (dcache2mem_o.req) begin
                    victim_cache_test_failed++;
                    $display("Victum Cache Teast Fail");
                    break;
                end 
                @(posedge clk);

            end

            while (!lsummu2dcache_i.req) @(posedge clk);
            while (!dcache2lsummu_o.ack) @(posedge clk);

            // @(posedge lsummu2dcache_i.req);
            // @(posedge dcache2lsummu_o.ack);

        end

    endtask

//========================== LSU Driver For Cache ============================//

   task lsu_drive_cache;
        
        $display("Testing Read Write in Cache");

        for (int j=0; j<no_of_cache_tests; j++) begin
            
            deme_tag = j;
            dmem_sel_i = 1;
            dcache_flush_i = 0;
            
            test_input.addr      = {23'h12345, deme_tag , 4'h4};
            test_input.w_data    = $random;
            test_input.sel_byte  = 4'hf;  
            test_input.w_en      = $random;  
            test_input.req       = 1;

            drive_inputs(test_input,  1);   // Write Operation
            drive_inputs(test_input,  0);   // Read Operation
        end

        $display("Read Write Testing Complete");

    endtask

//===================== LSU Driver For Victim Cache ==========================//

    task lsu_drive_victim_cache;
        
        $display("Testing Victim Cache Functionality");

        for (int j=0; j<no_of_victim_cache_tests; j++) begin
            deme_tag = j;
            dmem_sel_i = 1;
            dcache_flush_i = 0;
            
            test_input_1.addr      = 32'h0001_0010;
            test_input_1.w_data    = 32'hDEED_BEEF;
            test_input_1.sel_byte  = 4'hf;  
            test_input_1.w_en      = $random;  
            test_input_1.req       = 1;

            test_input_2.addr      = 32'h0000_1010;
            test_input_2.w_data    = 32'hDEAD_BEEF;
            test_input_2.sel_byte  = 4'hf;  
            test_input_2.w_en      = $random;  
            test_input_2.req       = 1;

            test_input_3.addr      = 32'h0001_0010;
            test_input_3.w_data    = 32'hDEED_BEEF;
            test_input_3.sel_byte  = 4'hf;  
            test_input_3.w_en      = $random;  
            test_input_3.req       = 1;


            // test_input_1.addr      = $random;
            // test_input_1.w_data    = $random;
            // test_input_1.sel_byte  = $random;  
            // test_input_1.w_en      = $random;  
            // test_input_1.req       = 1;

            // test_input_2.addr      = $random;
            // test_input_2.w_data    = $random;
            // test_input_2.sel_byte  = $random;  
            // test_input_2.w_en      = $random;  
            // test_input_2.req       = 1;

            // drive_inputs(test_input_1,  1);   // Write Operation
            drive_inputs(test_input_1,  0);   // Read Operation
 
            // drive_inputs(test_input_2,  1);   // Write Operation
            drive_inputs(test_input_2,  0);   // Read Operation
 
            // drive_inputs(test_input_3,  1);   // Write Operation
            drive_inputs(test_input_3,  0);   // Read Operation
        end

        $display("Victim Cache Testing Complete");

    endtask


    initial begin
        init_sequence;
        reset_circuit;
        @(posedge clk);

        no_of_cache_tests = 1;
        no_of_victim_cache_tests = 1;

        fork
            // driver for main mempry
            main_mem_driver;
            // monitor for testing read write in cache
            // monitor_cache;
            // monitor for testing victim cache functionality
            monitor_victim_cache;
        join_none

        
        // testing read write operation
        // lsu_drive_cache;

        // testing victim functionality
        lsu_drive_victim_cache;

        $display("\n//================================================================================// 
                    \n* Cache read write testing
                    \n    No. of tests: %0d  \n    Test Passed: %0d  \n    Test Failed: %0d,
                    \n* Victim cache testing
                    \n    No. of tests: %0d  \n    Test Passed: %0d  \n    Test Failed: %0d\n
                  \n//================================================================================//",

                no_of_cache_tests, cache_test_passed, cache_test_failed,
                no_of_victim_cache_tests, no_of_victim_cache_tests-victim_cache_test_failed, victim_cache_test_failed);

        $stop;

        end

endmodule


