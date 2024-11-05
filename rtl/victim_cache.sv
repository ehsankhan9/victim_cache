// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: The Victim-Cache for data cache. 
//
// Author: Muhammad Ehsan, Muhammad Mujtaba Rawn, Moazzam Ali
// Date: 08.10.2024

// `include "../defines/cache_defs.svh"

parameter VICTIM_NO_OF_SETS = 4;
parameter VICTIM_COUNTER_BITS = $clog2(VICTIM_NO_OF_SETS);
parameter int DCACHE_LINE_WIDTH = 128; 
parameter int VICTIM_ADDR_BITS = 28;   //VICTIM_ADDR_BITS = DCACHE_ADDR_WIDTH - DCACHE_OFFSET_BITS;


module victim_cache (
    input logic                            clk,
    input logic                            rst,
    input logic [DCACHE_LINE_WIDTH-1 : 0]  cache_to_victim_data,  //incomming_data
    input logic [VICTIM_ADDR_BITS-1  : 0]  cache_to_victim_addr,   //incomming_tag (original tag is of 8 bit which is 0's extend with valid aad dirty
    input logic                            write_to_victim_i,

    output logic [DCACHE_LINE_WIDTH-1 : 0] victim_to_cache_data,  //outgoing_data
    output logic [VICTIM_ADDR_BITS-1  : 0] victim_to_cache_addr ,  //out_going_tag
    output logic                           victim_hit_o
);

//////////////    VICTIM_CACHE      /////////////// 
////////////// VICTIM_NO_OF_SETS = 4  ////////////
logic [DCACHE_LINE_WIDTH-1  : 0] victim_cache_data   [VICTIM_NO_OF_SETS-1:0];
logic [VICTIM_ADDR_BITS-1   : 0] victim_cache_addr   [VICTIM_NO_OF_SETS-1:0];
///////////////////////////////////////////////////

logic [VICTIM_COUNTER_BITS-1:0] write_counter;

/////////////////////////////////////////////////
//genvar i;
//generate
//for (i=0; i<4; i++) begin
//    always_comb begin    
//        
//        if (cache_to_victim_addr == victim_cache_addr[i]) begin
//            victim_to_cache_data = victim_cache_data[i];
//            victim_to_cache_addr  = victim_cache_addr[i];
//            victim_hit_o = 1;
//        end         
//        
//        //else begin
//        //    victim_to_cache_data = '0;  /// for simulation
//        //    victim_to_cache_addr  = '0;   ///for simulation
//        //    victim_hit_o = 0; 
//        //end
//    end
//end
//endgenerate
genvar i;
generate
always_comb begin
    victim_hit_o = 0; // Default values
    victim_to_cache_data = '0;
    victim_to_cache_addr = '0;

    for (int i = 0; i < VICTIM_NO_OF_SETS; i++) begin
        if (cache_to_victim_addr == victim_cache_addr[i]) begin
            victim_to_cache_data = victim_cache_data[i];
            victim_to_cache_addr = victim_cache_addr[i];
            victim_hit_o = 1;
            //break; // Stop the loop after the first match
        end
    end
end
endgenerate

always_ff @(posedge clk or negedge rst) begin 
    if (!rst) begin
        victim_cache_addr <= '{default : '0};  
    end
    else if (write_to_victim_i) begin
        victim_cache_data[write_counter]  <= cache_to_victim_data;
        victim_cache_addr [write_counter] <= cache_to_victim_addr;
    end

    // this is case if VICTIM_NO_OF_SETS is not give integer clog2;
    if (!rst || (write_counter == (VICTIM_NO_OF_SETS-1))) begin
        write_counter                     <= '0;
    end
    else if (write_to_victim_i) begin
        write_counter                     <= write_counter + 1;
    end

end


endmodule
