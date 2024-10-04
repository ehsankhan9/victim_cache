parameter TAG_WIDTH  = 32
parameter DATA_WIDTH = 128

module victim_cache (
    input logic [DATA_WIDTH-1 : 0]  cache_to_victim_data,  //incomming_data
    input logic [TAG_WIDTH-1  : 0]  cache_to_victim_tag,   //incomming_tag
    input logic                     write_to_victim,

    output logic [DATA_WIDTH-1 : 0] victim_to_cache_data   ,//outgoing_data
    output logic [TAG_WIDTH-1  : 0] victim_to_cache_tag    ,//out_going_tag
    output logic                    victim_hit,
);

//////////////    VICTIM_CACHE      ///////////////    
logic [DATA_WIDTH-1 : 0]  victim_cache_data  [3:0];
logic [TAG_WIDTH-1  : 0]  victim_cache_tag   [3:0];
///////////////////////////////////////////////////

logic [3:0] write_counter;

always_comb begin 
    if (cache_to_victim_tag == victim_cache_tag[0]) begin
        victim_to_cache_data = victim_cache_data[0];
        victim_hit = 1;
    end 
    else if (cache_to_victim_tag == victim_cache_tag[1]) begin
        victim_to_cache_data = victim_cache_data[1];
        victim_hit = 1;
    end
    else if (cache_to_victim_tag == victim_cache_tag[2]) begin
        victim_to_cache_data = victim_cache_data[2];
        victim_hit = 1;
    end
    else if (cache_to_victim_tag == victim_cache_tag[3]) begin
        victim_to_cache_data = victim_cache_data[3];
        victim_hit = 1;
    end
    else begin
        victim_hit = 0; 
    end
end

always_ff @(posedge clk or negedge rst) begin 
    if (!rst) begin
        write_counter <= 2'b00;
        genvar j;
        generate
        for (j=0; j<4; j++) begin
            victim_cache_tag[i] = 0;    
        end
        endgenerate
    end
    else if (write_to_victim) begin
        victim_cache_data[write_counter] <= cache_to_victim_data;
        victim_cache_tag [write_counter] <= cache_to_victim_tag;
        write_counter                    <= write_counter + 1;
    end
end

endmodule
