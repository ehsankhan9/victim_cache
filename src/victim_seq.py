import re

# Function to parse parameters from the .svh file
def parse_svh_parameters(filename):
    parameters = {}
    # Regular expression to match SystemVerilog parameters
    pattern = r"parameter\s+(\w+)\s*=\s*(\d+);"
    
    # Read the .svh file and find all parameters
    with open(filename, "r") as file:
        for line in file:
            match = re.search(pattern, line)
            if match:
                param_name = match.group(1)
                param_value = int(match.group(2))
                parameters[param_name] = param_value
    return parameters

# Parse the parameters from the provided .svh file
svh_file_path = "defines/cache_defs.svh"
parameters = parse_svh_parameters(svh_file_path)

# Define values for parameters, falling back on defaults if they’re not in the .svh file
#DCACHE_LINE_WIDTH = parameters.get("DCACHE_LINE_WIDTH", 32)
#VICTIM_ADDR_BITS = parameters.get("VICTIM_ADDR_BITS", 8)
VICTIM_NO_OF_SETS = parameters.get("VICTIM_NO_OF_SETS", 4)
#VICTIM_COUNTER_BITS = parameters.get("VICTIM_COUNTER_BITS", 2)

# Open a file in write mode
num_lines_first = VICTIM_NO_OF_SETS # Adjust as needed for the first loop
num_lines_second = VICTIM_NO_OF_SETS  # Adjust as needed for the second loop

with open("rtl/victim_cache.sv", "w") as file:
    # Write the lines of the SystemVerilog code to the file
    file.write("""// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: The Victim-Cache for data cache. 
//
// Author: Muhammad Ehsan, Moazzam Ali, Muhammad Mujtaba Rawn
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

    input logic [DCACHE_LINE_WIDTH-1 : 0]  dcache2victim_data_i,    //input_data
    input logic [VICTIM_ADDR_BITS-1  : 0]  dcache2victim_addr_w_i,  //input_tag + index
    input logic [VICTIM_ADDR_BITS-1  : 0]  dcache2victim_addr_r_i,  //input_tag + index
    input logic                            victim_wr_en_i,

    output logic [DCACHE_LINE_WIDTH-1 : 0] victim2dcache_data_o,    //output_data
    output logic [VICTIM_ADDR_BITS-1  : 0] victim2dcache_addr_o ,   //output_tag + index
    output logic                           victim_hit_o
);

//////////////    VICTIM_CACHE      /////////////// 

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
    else if  (victim_wr_en_i) begin
        if ((dcache2victim_addr_w_i == victim_cache_addr[0]) && valid[0]) begin
            victim_cache_data[0]  <= dcache2victim_data_i;
        end\n""") 
    #file.write("// Additional lines before the second set of conditions-----------------------------------------------------------\n")
    for i in range(1,num_lines_second):
        file.write(f"        else if ((dcache2victim_addr_w_i == victim_cache_addr[{i}]) && valid[{i}]) begin\n")
        file.write(f"            victim_cache_data[{i}]  <= dcache2victim_data_i;\n")
        file.write("        end\n")
    file.write("""        else begin
            valid[write_counter]              <= 1'b1;
            victim_cache_data[write_counter]  <= dcache2victim_data_i;
            victim_cache_addr [write_counter] <= dcache2victim_addr_w_i;
            write_counter                     <= write_counter + 1'b1;            
        end
    end
end\n""")

    file.write("""\nalways_ff @(posedge clk) begin
    if (valid[0] && (dcache2victim_addr_r_i == victim_cache_addr[0])) begin
        victim2dcache_data_o <= victim_cache_data[0];
        victim2dcache_addr_o <= victim_cache_addr[0];
        victim_hit_o         <= 1'b1;
    end\n""")
    for i in range(1,num_lines_first):
        file.write(f"    else if (valid[{i}] && (dcache2victim_addr_r_i == victim_cache_addr[{i}])) begin\n")
        file.write(f"        victim2dcache_data_o <= victim_cache_data[{i}];\n")
        file.write(f"        victim2dcache_addr_o <= victim_cache_addr[{i}];\n")
        file.write("        victim_hit_o         <= 1'b1;\n")
        file.write("    end\n")
    file.write("""    else begin
        victim2dcache_data_o <= '0;
        victim2dcache_addr_o <= '0;
        victim_hit_o         <= 1'b0;
    end
end

endmodule""")
    


print("SystemVerilog code has been written to victim_cache_module.txt")

