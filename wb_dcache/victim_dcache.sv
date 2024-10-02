`ifndef CACHE_DEFS
`define CACHE_DEFS

`include "cache_defs.svh"

module victim_dcache (
    input  logic                         clk,
    input  logic                         rst,
    input  logic [DCACHE_TAG_BITS-1:0]   v_tag,
    input  logic [DCACHE_LINE_WIDTH-1:0] data_cache2victim,
    input  logic                         v_wr_en,
    output logic                         v_hit,
    output logic [DCACHE_LINE_WIDTH-1:0] data_victim2cache
);

typedef struct packed {
    logic [DCACHE_LINE_WIDTH-1:0] data;
    logic [DCACHE_TAG_BITS-1:0]   tag;
} victim_cache_line;

victim_cache_line v_cache[1:0];

logic [1:0] write_counter;    // Fifo Counter

always_comb begin 
    if (v_cache[0].tag == v_tag) begin
        data_victim2cache = v_cache[0].data;
        v_hit = 1;
    end
    else if (v_cache[1].tag == v_tag) begin
        data_victim2cache = v_cache[1].data;
        v_hit = 1;
    end
    else if (v_cache[2].tag == v_tag) begin
        data_victim2cache = v_cache[2].data;
        v_hit = 1;
    end
    else if (v_cache[3].tag == v_tag) begin
        data_victim2cache = v_cache[3].data;
        v_hit = 1;
    end
    else begin
        data_victim2cache = 0;
        v_hit = 0;
    end
end

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        for (int i=0; i<4; i++) begin
            v_cache[i].tag  <= 0;
            v_cache[i].data <= 0;
        end
        write_counter <= 0;
    end
    else if (v_wr_en) begin
        v_cache[write_counter].data <= data_cache2victim;
        v_cache[write_counter].tag  <= v_tag;
        write_counter <= write_counter + 1;
    end
end
endmodule













// parameter VICTIM_CACHE_LINE_SIZE = 128;
// parameter VICTIM_CACHE_LINES = 4;
// parameter VICTIM_CACHE_TAG = 20;

// module victim_cache (
//     input logic clk,
//     input logic rst,
//     input logic [] v_tag,
//     input logic [127:0] data_cache2victim,

//     output logic v_hit,
//     output logic [127:0] data_victim2cache,
// );
// logic [1:0] counter;
// typedef struct packed {
//     logic [127:0]  data;
//     logic [20:0] tag;
// } victim_cache_line;

// logic [1:0] lru_counter [1:0];    // LRU Policy
// logic [1:0] write_counter;    // LRU Policy
// victim_cache_line v_cache[1:0];

// // assign camp[0] = (v_cache[0].tag == v_tag);
// // assign camp[1] = (v_cache[1].tag == v_tag);
// // assign camp[2] = (v_cache[2].tag == v_tag);
// // assign camp[3] = (v_cache[3].tag == v_tag);

// // always_comb begin 
// //     if (v_cache[0].tag == v_tag) begin
// //         data_victim2cache = v_cache[0].data;
// //         v_hit = 1;
// //     end
// //     else if (v_cache[1].tag == v_tag) begin
// //         data_victim2cache = v_cache[1].data;
// //         v_hit = 1;
// //     end
// //     else if (v_cache[2].tag == v_tag) begin
// //         data_victim2cache = v_cache[2].data;
// //         v_hit = 1;
// //     end
// //     else if (v_cache[3].tag == v_tag) begin
// //         data_victim2cache = v_cache[3].data;
// //         v_hit = 1;
// //     end
// //     else begin
// //         v_hit = 0;
// //     end
// // end

// always_ff @(posedge clk or negedge rst) begin
//     if (!rst) begin
//         for (int i=0; i<4; i++) begin
//             v_cache[i].tag  <= 0;
//             v_cache[i].data <= 0;
//             lru_counter[i]  <= 0;
//         end
//         write_counter <= 0;
//     end
//     else if (v_wr_en) begin
//         write_counter               <= max(lru_counter[0],lru_counter[1],lru_counter[2],lru_counter[3]);
//         v_cache[write_counter].data <= data_cache2victim;
//         v_cache[write_counter].tag  <= v_tag;
//     end

    
//     if (v_cache[0].tag == v_tag) begin
//         data_victim2cache = v_cache[0].data;
//         v_hit      = 1;
//         if (lru_counter[0] == 2'b11) begin
//             lru_counter[0] = lru_counter[0]; 
//         end
//         else begin
//             lru_counter[0] = lru_counter[0] + 1; 
//         end
//     end

//     else if (v_cache[1].tag == v_tag) begin
//         data_victim2cache = v_cache[1].data;
//         v_hit      = 1;
//         if (lru_counter[1] == 2'b11) begin
//             lru_counter[1] = lru_counter[1]; 
//         end
//         else begin
//             lru_counter[1] = lru_counter[1] + 1; 
//         end
//     end

//     else if (v_cache[2].tag == v_tag) begin
//         data_victim2cache = v_cache[2].data;
//         v_hit      = 1;
//         if (lru_counter[2] == 2'b11) begin
//             lru_counter[2] = lru_counter[2]; 
//         end
//         else begin
//             lru_counter[2] = lru_counter[2] + 1; 
//         end
//     end

//     else if (v_cache[3].tag == v_tag) begin
//         data_victim2cache = v_cache[3].data;
//         v_hit      = 1;
//         if (lru_counter[3] == 2'b11) begin
//             lru_counter[3] = lru_counter[3]; 
//         end
//         else begin
//             lru_counter[3] = lru_counter[3] + 1; 
//         end
//     end

//     else begin
//         v_hit = 0;
//     end
// end
// endmodule
