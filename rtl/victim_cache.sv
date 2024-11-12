// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: The Victim-Cache for data cache. 
//
// Author: Muhammad Ehsan, Muhammad Mujtaba Rawn, Moazzam Ali
// Date: 08.10.2024


`ifndef VERILATOR
`include "../../defines/cache_defs.svh"
`else
`include "cache_defs.svh"
`endif

module victim_cache (
    input logic                            clk,
    input logic                            rst,
    input logic                            flush_i,

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
logic [VICTIM_NO_OF_SETS-1:0]   valid;

/////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst) begin 
    if (!rst || flush_i) begin
        write_counter  <= '0;
        valid          <= '0;
    end
    else if (write_to_victim_i) begin
        if ((cache_to_victim_addr == victim_cache_addr[0]) && valid[0]) begin
            victim_cache_data[0]  <= cache_to_victim_data;
        end 
        else if ((cache_to_victim_addr == victim_cache_addr[1]) && valid[1]) begin
            victim_cache_data[1]  <= cache_to_victim_data;
        end
        else if ((cache_to_victim_addr == victim_cache_addr[2]) && valid[2]) begin
            victim_cache_data[2]  <= cache_to_victim_data;
        end
        else if ((cache_to_victim_addr == victim_cache_addr[3]) && valid[3]) begin
            victim_cache_data[3]  <= cache_to_victim_data;
        end
        else begin
            valid[write_counter]              <= 1'b1;
            victim_cache_data[write_counter]  <= cache_to_victim_data;
            victim_cache_addr [write_counter] <= cache_to_victim_addr;
            write_counter                     <= write_counter + 1'b1;            
        end
    end
end


always_comb begin
    if (valid[0] && (cache_to_victim_addr == victim_cache_addr[0])) begin
        victim_to_cache_data  =  victim_cache_data[0];
        victim_to_cache_addr  =  victim_cache_addr[0];
        victim_hit_o = 1'b1;
    end
    else if (valid[1] && (cache_to_victim_addr == victim_cache_addr[1])) begin
        victim_to_cache_data  =  victim_cache_data[1];
        victim_to_cache_addr  =  victim_cache_addr[1];
        victim_hit_o = 1'b1;
    end
    else if (valid[2] && (cache_to_victim_addr == victim_cache_addr[2])) begin
        victim_to_cache_data  =  victim_cache_data[2];
        victim_to_cache_addr  =  victim_cache_addr[2];
        victim_hit_o = 1'b1;
    end
    else if (valid[3] && (cache_to_victim_addr == victim_cache_addr[3])) begin
        victim_to_cache_data  =  victim_cache_data[3];
        victim_to_cache_addr  =  victim_cache_addr[3];
        victim_hit_o = 1'b1;
    end
    else  begin
        victim_to_cache_data = '0;
        victim_to_cache_addr = '0;
        victim_hit_o = 1'b0;
    end
end


endmodule

