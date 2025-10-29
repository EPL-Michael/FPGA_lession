`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/20 14:27:05
// Design Name: 
// Module Name: freq_division
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module freq_division(
    input wire clk,
    input wire clr,
    output reg clk_10MHz,
    output reg clk_1kHz,
    output reg clk_1hz             // 1Hz时钟输出（用于频率测量闸门）
    );
    parameter CNT_10MHz=5;
    parameter CNT_1kHz=50000;
    
    reg [2:0] cnt_10mhz;
    reg [16:0] cnt_1khz;
    
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            cnt_10mhz <= 3'd0;
            clk_10MHz <= 1'b0;
        end
        else begin
            if(cnt_10mhz==CNT_10MHz-1) begin
                cnt_10mhz <= 3'd0;
                clk_10MHz <= ~clk_10MHz;
            end
            else begin
               cnt_10mhz <= cnt_10mhz + 1'b1;
            end
         end
     end
    
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            cnt_1khz <= 17'd0;
            clk_1kHz <= 1'b0;
        end
        else begin
            if(cnt_1khz == CNT_1kHz-1) begin
                cnt_1khz <=17'd0;
                clk_1kHz <= ~clk_1kHz;
            end
            else begin
                cnt_1khz <= cnt_1khz + 1'b1;
            end
        end
    end
    
    reg [26:0] cnt_1hz;            // 1Hz分频计数器
    
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            cnt_1hz <= 27'd0;
            clk_1hz <= 1'b0;
        end else begin
            if (cnt_1hz == 27'd49999999) begin
                cnt_1hz <= 27'd0;
                clk_1hz <= ~clk_1hz;   // 每50000000个时钟周期翻转一次
            end else begin
                cnt_1hz <= cnt_1hz + 1'b1;
            end
        end
    end
            
endmodule
