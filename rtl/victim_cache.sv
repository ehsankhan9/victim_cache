// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: The Victim-Cache for data cache. 
//
// Author: Ehsan Khan, Muhammad Mujtaba Rawn, Moazzam Ali, UET Lahore
// Date: 08.10.2024

// `include "../defines/cache_defs.svh"

parameter VICTIM_NO_OF_SETS = 4;
parameter int DCACHE_LINE_WIDTH = 128; 
parameter int DCACHE_TAG_BITS = 23;    


module victim_cache (
    input logic                            clk,
    input logic                            rst,
    input logic [DCACHE_LINE_WIDTH-1 : 0]  cache_to_victim_data,  //incomming_data
    input logic [DCACHE_TAG_BITS-1  : 0]   cache_to_victim_tag,   //incomming_tag (original tag is of 8 bit which is 0's extend with valid aad dirty
    input logic                            write_to_victim_i,

    output logic [DCACHE_LINE_WIDTH-1 : 0] victim_to_cache_data,  //outgoing_data
    output logic [DCACHE_TAG_BITS-1  : 0]  victim_to_cache_tag ,  //out_going_tag
    output logic                           victim_hit_o
);

//////////////    VICTIM_CACHE      ///////////////     
////////////// VICTIM_NO_OF_SETS = 4  ////////////
logic [DCACHE_LINE_WIDTH-1 : 0] victim_cache_data  [VICTIM_NO_OF_SETS-1:0];
logic [DCACHE_TAG_BITS-1  : 0]  victim_cache_tag   [VICTIM_NO_OF_SETS-1:0];
///////////////////////////////////////////////////

logic [3:0] write_counter;

/////////////////////////////////////////////////
always_comb begin 
    if (cache_to_victim_tag == victim_cache_tag[0]) begin
        victim_to_cache_data = victim_cache_data[0];
        victim_to_cache_tag  = victim_cache_tag[0] ;
        victim_hit_o = 1;
    end 
    else if (cache_to_victim_tag == victim_cache_tag[1]) begin
        victim_to_cache_data = victim_cache_data[1];
        victim_to_cache_tag  = victim_cache_tag[1];
        victim_hit_o = 1;
    end
    else if (cache_to_victim_tag == victim_cache_tag[2]) begin
        victim_to_cache_data = victim_cache_data[2];
        victim_to_cache_tag  = victim_cache_tag[2];
        victim_hit_o = 1;
    end
    else if (cache_to_victim_tag == victim_cache_tag[3]) begin
        victim_to_cache_data = victim_cache_data[3];
        victim_to_cache_tag  = victim_cache_tag[3];
        victim_hit_o = 1;
    end
    else begin
        victim_hit_o = 0; 
    end
end

always_ff @(posedge clk or negedge rst) begin 
    if (!rst) begin
        write_counter <= 2'b00;
        victim_cache_tag <= '{default : '0};  // Also done by this in place of generate block
    end
    else if (write_to_victim_i) begin
        victim_cache_data[write_counter] <= cache_to_victim_data;
        victim_cache_tag [write_counter] <= cache_to_victim_tag;
        write_counter                    <= write_counter + 1;
    end
end

endmodule
