// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: The datapath for data cache. 
//
// Author: Muhammad Tahir, UET Lahore
// Date: 11.6.2023

`include "../defines/cache_defs.svh"

module wb_dcache_datapath(
    input  wire                            clk,
    input  wire                            rst_n,

    // Interface signals to/from cache controller
    input  wire                            cache_wr_i,
    input  wire                            cache_line_wr_i,
    input  wire                            cache_line_clean_i,
    input  wire                            cache_wrb_req_i,
    input  wire [DCACHE_IDX_BITS-1:0]      evict_index_i,
    output logic                           cache_hit_o,
    output logic                           cache_evict_req_o,

    // LSU/MMU to data cache interface
    input  wire                            dcache_flush_i,
    input  wire                            lsummu2dcache_req_i,
    input  wire  [DCACHE_ADDR_WIDTH-1:0]   lsummu2dcache_addr_i,
    input  wire  [DCACHE_DATA_WIDTH-1:0]   lsummu2dcache_wdata_i,
    input  wire  [3:0]                     sel_byte_i,
    output logic [DCACHE_DATA_WIDTH-1:0]   dcache2lsummu_data_o,

    // Data cache to data memory interface
    input  wire  [DCACHE_LINE_WIDTH-1:0]   mem2dcache_data_i,
    output logic [DCACHE_LINE_WIDTH-1:0]   dcache2mem_data_o,
    output logic [DCACHE_ADDR_WIDTH-1:0]   dcache2mem_addr_o,

    //victim cache to/from dcache
    output logic                          victim_hit_o,      
    output logic                          dcache_valid_o, 
    input  logic                          write_from_victim_i,
    input  logic                          write_to_victim_i,
    input  logic                          lsu_victim_mux_sel_i
);

type_dcache_data_s                   cache_line_read, cache_line_write, cache_wdata;
type_dcache_tag_s                    cache_tag_read, cache_tag_write;

logic [DCACHE_DATA_WIDTH-1:0]        cache_word_read, cache_word_write;
logic [DCACHE_DATA_WIDTH-1:0]        lsummu2dcache_wdata;
logic [DCACHE_ADDR_WIDTH-1:0]        dcache2mem_addr;
logic [15:0]                         cache_line_sel_byte, cache_data_wr_sel;
logic [3:0]                          sel_byte;
logic [3:0]                          cache_tag_wr_sel;

logic [DCACHE_DATA_WIDTH-1:0]        dcache2lsummu_data_ff, dcache2lsummu_data_next;
logic [DCACHE_TAG_BITS-1:0]          addr_tag, addr_tag_ff;
logic [1:0]                          addr_offset, addr_offset_ff;
logic [DCACHE_IDX_BITS-1:0]          addr_index, addr_index_ff;
logic [DCACHE_IDX_BITS-1:0]          evict_index;
logic                                dcache_flush;   
                            
///logic [DCACHE_DATA_WIDTH-1:0]        victim2cache_data;
logic [DCACHE_LINE_WIDTH-1:0]        victim2cache_data;
logic [DCACHE_TAG_BITS-1:0]          victim2cache_tag;      

assign dcache_flush         = dcache_flush_i;
assign evict_index          = evict_index_i;
//assign sel_byte             = sel_byte_i;
//assign lsummu2dcache_wdata  = lsummu2dcache_wdata_i;

assign addr_tag             = lsummu2dcache_addr_i[DCACHE_ADDR_WIDTH-1:DCACHE_TAG_LSB];
assign addr_offset          = lsummu2dcache_addr_i[DCACHE_OFFSET_BITS-1:2];
assign addr_index           = dcache_flush ? evict_index : cache_wr_i ? addr_index_ff :
                              lsummu2dcache_addr_i[DCACHE_TAG_LSB-1:DCACHE_OFFSET_BITS];


always_ff@(posedge clk) begin
   if(!rst_n) begin
        lsummu2dcache_wdata <= '0;
        sel_byte            <= '0;
    end else begin
        lsummu2dcache_wdata <= lsummu2dcache_wdata_i; // MT
        sel_byte            <= sel_byte_i;
    end
end

always_ff@(posedge clk) begin
   if(!rst_n) begin
        addr_offset_ff <= '0;
    end else begin
        addr_offset_ff <= addr_offset; // MT
    end
end

//assign cache_line_read = cache_data_ram[addr_index]; // MT
////////////////////////////////////////////////
////////////////////////////////////////////////
always_comb begin
    unique case (addr_offset_ff) // MT
      2'b00:    cache_word_read = cache_line_read[31:0];
      2'b01:    cache_word_read = cache_line_read[63:32];
      2'b10:    cache_word_read = cache_line_read[95:64];
      2'b11:    cache_word_read = cache_line_read[127:96];
    default:  cache_word_read = '0;
    endcase
end
////////////////////////////////////////////////
////////////////////////////////////////////////
always_comb begin
    cache_word_write = '0;  // MT cache_word_read      
        if (sel_byte[0]) cache_word_write[7:0]   = lsummu2dcache_wdata[7:0]; 
        if (sel_byte[1]) cache_word_write[15:8]  = lsummu2dcache_wdata[15:8]; 
        if (sel_byte[2]) cache_word_write[23:16] = lsummu2dcache_wdata[23:16]; 
        if (sel_byte[3]) cache_word_write[31:24] = lsummu2dcache_wdata[31:24]; 
end

always_comb begin
    cache_line_write = '0;  // MT cache_line_read
    cache_line_sel_byte = '0;

    unique case (addr_offset_ff)
        2'b00: begin
            cache_line_write[31:0]   = cache_word_write;
            cache_line_sel_byte[3:0] = sel_byte;
        end
        2'b01: begin
            cache_line_write[63:32]  = cache_word_write;
            cache_line_sel_byte[7:4] = sel_byte;
        end
        2'b10: begin
            cache_line_write[95:64]   = cache_word_write;
            cache_line_sel_byte[11:8] = sel_byte;
        end
        2'b11: begin
            cache_line_write[127:96]   = cache_word_write;
            cache_line_sel_byte[15:12] = sel_byte;
        end
      //  default:  dcache2lsummu_data_next = '0;
    endcase
end

always_comb begin
cache_tag_write  = '0;
cache_tag_wr_sel = '0;
  
    if (cache_line_clean_i) begin // Only clean (not invalidate) cache line on flush
        cache_tag_write.dirty = 8'b0;
        cache_tag_wr_sel      = 4'h8;
    end else if (cache_wr_i) begin
        cache_tag_write.dirty = 8'b1;
        cache_tag_wr_sel      = 4'h8;
    end else if (cache_line_wr_i) begin
        cache_tag_write.tag   = {{23-DCACHE_TAG_BITS{1'b0}}, addr_tag};
        cache_tag_write.valid = 1'b1;
        cache_tag_write.dirty = 8'b0;
        cache_tag_wr_sel      = 4'hF;

 //////////////////////////////////////////////////////////////////////////
 //888888888888888888888888888888888888888888888888888888888888888888888888   
    end else if (write_from_victim_i) begin
        cache_tag_write.tag   = {{23-DCACHE_TAG_BITS{1'b0}}, victim2cache_tag};
        cache_tag_write.valid = 1'b1;
        cache_tag_write.dirty = 8'b0;
        cache_tag_wr_sel      = 4'hF;
    end
 //888888888888888888888888888888888888888888888888888888888888888888888888   
 //////////////////////////////////////////////////////////////////////////

end

// Prepare address and data signals for cache-line writeback or allocate on cache miss 
always_comb begin
    if (cache_wrb_req_i) begin
        dcache2mem_addr = {cache_tag_read.tag[DCACHE_TAG_BITS-1:0], addr_index, {{DCACHE_OFFSET_BITS}{1'b0}}};
    end else begin
        dcache2mem_addr = lsummu2dcache_addr_i;
    end
end
 
 //////////////////////////////////////////////////////////////////////////
// MT
 //888888888888888888888888888888888888888888888888888888888888888888888888   
assign cache_wdata = write_from_victim_i ? victim2cache_data : cache_line_wr_i ? mem2dcache_data_i : cache_wr_i ? cache_line_write : '0;
assign cache_data_wr_sel = ( write_from_victim_i || cache_line_wr_i) ? 16'hFFFF : cache_wr_i ? cache_line_sel_byte : '0;
 //888888888888888888888888888888888888888888888888888888888888888888888888   
 //////////////////////////////////////////////////////////////////////////


always_ff@(posedge clk) begin
   if(!rst_n) begin
        dcache2lsummu_data_ff <= '0;
    end else begin
        dcache2lsummu_data_ff <= dcache2lsummu_data_next;
    end
end

always_ff@(posedge clk) begin
    if(!rst_n) begin
        addr_tag_ff    <= '0;
        addr_index_ff  <= '0;
    end else begin
        addr_tag_ff    <= addr_tag;
        addr_index_ff  <= lsummu2dcache_addr_i[DCACHE_TAG_LSB-1:DCACHE_OFFSET_BITS];
    end
end

dcache_data_ram dcache_data_ram_module (
    .clk                  (clk), 
    .rst_n                (rst_n),

    .req                  (lsummu2dcache_req_i),
    .wr_en                (cache_data_wr_sel),
    .addr                 (addr_index),
    .wdata                (cache_wdata),
    .rdata                (cache_line_read)  
);

dcache_tag_ram dcache_tag_ram_module (
    .clk                  (clk), 
    .rst_n                (rst_n),

    .req                  (lsummu2dcache_req_i),
    .wr_en                (cache_tag_wr_sel),
    .addr                 (addr_index),
    .wdata                (cache_tag_write),
    .rdata                (cache_tag_read)  
);

 //////////////////////////////////////////////////////////////////////////
 //888888888888888888888888888888888888888888888888888888888888888888888888   
victim_cache victim_cache_module (
    .clk                      (clk),
    .rst                      (rst_n),
    .cache_to_victim_data     (cache_line_read),
    .cache_to_victim_tag      (cache_tag_read.tag[DCACHE_TAG_BITS-1:0]),
    .write_to_victim_i          (write_to_victim_i),
    .victim_to_cache_data     (victim2cache_data),
    .victim_to_cache_tag      (victim2cache_tag),
    .victim_hit_o               (victim_hit_o)
);
 //888888888888888888888888888888888888888888888888888888888888888888888888   
 //////////////////////////////////////////////////////////////////////////


// Output signals update
assign dcache2lsummu_data_next = cache_word_read;   // Read data from cache to LSU/MMU 

assign cache_hit_o          = (addr_tag_ff == cache_tag_read.tag[DCACHE_TAG_BITS-1:0]) && cache_tag_read.valid;
assign cache_evict_req_o    = cache_tag_read.dirty[0]; // & cache_tag_read.valid;
assign dcache2mem_addr_o    = dcache2mem_addr;
assign dcache2mem_data_o    = cache_line_read;


////////////////////////////////////////////////////////////////////////
//8888888888888888888888888888888888888888888888888888888888888888888888
// data goes to lsu
// assign dcache2lsummu_data_o = dcache2lsummu_data_next;

// goes to controller for control victim cache
// assign dcache2lsummu_data_o = lsu_victim_mux_sel_i ? victim2cache_data : dcache2lsummu_data_next;

assign dcache_valid_o = cache_tag_read.valid;  // data in dcache is valid or not, for write in victim cache  

always_comb begin

    if (lsu_victim_mux_sel_i) begin
        if (addr_offset_ff == 2'b00) begin
            dcache2lsummu_data_o = victim2cache_data[31:0];
        end
        else if (addr_offset_ff == 2'b01) begin
            dcache2lsummu_data_o = victim2cache_data[63:32];
        end
        else if (addr_offset_ff == 2'b10) begin
            dcache2lsummu_data_o = victim2cache_data[95:64];
        end
        else if (addr_offset_ff == 2'b11)begin
            dcache2lsummu_data_o = victim2cache_data[127:96];
        end
    end

    else begin
        dcache2lsummu_data_o = dcache2lsummu_data_next;
    end

end
//8888888888888888888888888888888888888888888888888888888888888888888888
////////////////////////////////////////////////////////////////////////

endmodule