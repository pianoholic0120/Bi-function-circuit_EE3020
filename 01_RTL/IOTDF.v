`timescale 1ns/10ps


// IoT data filtering module
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);

// Input Ports
input        clk;
input        rst;
input        in_en;
input  [7:0] iot_in;
input  [2:0] fn_sel;

 // Output Ports
output     busy;
output reg valid;
output reg [127:0] iot_out;

// 7 functions for data filtering
parameter GRAY2BIN = 3'b001; 
parameter FIR      = 3'b010; 


// 16 byte * 60 round = 960 < 2^10
// 0-3 for iot_in
reg [9:0] counter;
reg [9:0] counter_delay1;
reg [9:0] counter_delay2;


// 128-bit data register
reg [127:0] iot_data;
reg [127:0] prep_to_out;
reg [127:0] prep_to_output;
reg [127:0] wait_to;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter <= 0;
    end else if(in_en) begin
        if (counter == 960) counter <= 0;
        else counter <= counter + 1;
    end else begin
        counter <= counter;
    end 
end

always @(posedge clk) begin
    // add dummy mux to avoid timing violation
    if(in_en) begin
        counter_delay1 <= counter;
        counter_delay2 <= counter_delay1;
    end else begin
        counter_delay1 <= counter_delay1;
        counter_delay2 <= counter_delay2;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        iot_data <= 0;
    end else if(in_en) begin
        // each iot_in data is 8-bit
        iot_data[7:0] <= iot_in;
        // shift register
        iot_data[127:8] <= iot_data[119:0];
        wait_to <= iot_data;
    end else begin
        iot_data <= iot_data;
        wait_to <= wait_to;
    end
end

integer idx;

always @(*) begin
    if(rst) begin
        prep_to_out = 0;
        prep_to_output = 0;
    // input enable
    end else if(in_en) begin
        if(fn_sel == GRAY2BIN) begin
            // read iot_data every 16 cycles
            if (counter_delay1[3:0] == 15) begin
                prep_to_output = 0;
                prep_to_out[127] = iot_data[127];
                for (idx = 126; idx >= 0; idx = idx - 1) begin
                    prep_to_out[idx] = prep_to_out[idx + 1] ^ iot_data[idx];
                end
            end else begin
                prep_to_out = 0;
                prep_to_output = 0;
            end
        end else if(fn_sel == FIR) begin
            // read iot_data every 16 cycles
            if (counter_delay1[3:0] == 15) begin
                prep_to_out = iot_data;
                prep_to_output = 0;
            end else if (counter_delay2[3:0] == 15) begin
                prep_to_out = wait_to;
                prep_to_output[127:120] = (((prep_to_out[127:120] * 8'd5) >> 3)+ 1) >> 1;
                prep_to_output[119:112] = ((((prep_to_out[119:112] * 8'd5)+(prep_to_out[127:120] * 8'd9)) >> 3)+ 1) >> 1;
                prep_to_output[111:104] = ((((prep_to_out[111:104] * 8'd5)+(prep_to_out[119:112] * 8'd9)+(prep_to_out[127:120] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[103:96] = ((((prep_to_out[103:96] * 8'd5)+(prep_to_out[111:104] * 8'd9)+(prep_to_out[119:112] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[95:88] = ((((prep_to_out[95:88] * 8'd5)+(prep_to_out[103:96] * 8'd9)+(prep_to_out[111:104] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[87:80] = ((((prep_to_out[87:80] * 8'd5)+(prep_to_out[95:88] * 8'd9)+(prep_to_out[103:96] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[79:72] = ((((prep_to_out[79:72] * 8'd5)+(prep_to_out[87:80] * 8'd9)+(prep_to_out[95:88] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[71:64] = ((((prep_to_out[71:64] * 8'd5)+(prep_to_out[79:72] * 8'd9)+(prep_to_out[87:80] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[63:56] = ((((prep_to_out[63:56] * 8'd5)+(prep_to_out[71:64] * 8'd9)+(prep_to_out[79:72] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[55:48] = ((((prep_to_out[55:48] * 8'd5)+(prep_to_out[63:56] * 8'd9)+(prep_to_out[71:64] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[47:40] = ((((prep_to_out[47:40] * 8'd5)+(prep_to_out[55:48] * 8'd9)+(prep_to_out[63:56] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[39:32] = ((((prep_to_out[39:32] * 8'd5)+(prep_to_out[47:40] * 8'd9)+(prep_to_out[55:48] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[31:24] = ((((prep_to_out[31:24] * 8'd5)+(prep_to_out[39:32] * 8'd9)+(prep_to_out[47:40] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[23:16] = ((((prep_to_out[23:16] * 8'd5)+(prep_to_out[31:24] * 8'd9)+(prep_to_out[39:32] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[15:8] = ((((prep_to_out[15:8] * 8'd5)+(prep_to_out[23:16] * 8'd9)+(prep_to_out[31:24] * 8'd2)) >>3)+ 1) >> 1;
                prep_to_output[7:0] = ((((prep_to_out[7:0] * 8'd5)+(prep_to_out[15:8] * 8'd9)+(prep_to_out[23:16] * 8'd2)) >>3)+ 1) >> 1;
            end else begin
                prep_to_out = 0;
                prep_to_output = 0;
            end
        end else begin
            prep_to_out = 0;
            prep_to_output = 0;
        end
    end else begin
        prep_to_out = 0;
        prep_to_output = 0;
    end
end

// busy always 0
assign busy = 0;

// valid
always @(posedge clk or posedge rst) begin
    if(rst) begin
        valid <= 0;
    end else if(in_en) begin
        case(fn_sel)
            GRAY2BIN: begin
                if (counter_delay1[3:0] == 15) begin
                    valid <= 1;
                end else begin
                    valid <= 0;
                end
            end
            FIR: begin
                if (counter_delay2[3:0] == 15) begin
                    valid <= 1;
                end else begin
                    valid <= 0;
                end
            end
            default: begin
                valid <= 0;
            end
        endcase
    end
end

// iot_out
always @(posedge clk or posedge rst) begin
    if(rst) begin
        iot_out <= 0;
    end else if(in_en) begin
        case(fn_sel)
            GRAY2BIN: begin
                if (counter_delay1[3:0] == 15) begin
                    iot_out <= prep_to_out;
                end
            end
            FIR: begin
                if (counter_delay2[3:0] == 15) begin
                    iot_out <= prep_to_output;
                end 
            end
            default: begin
                iot_out <= 1'b0;
            end
        endcase
    end
end

endmodule