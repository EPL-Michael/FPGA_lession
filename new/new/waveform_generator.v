`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/29 23:29:36
// Design Name: 
// Module Name: waveform_generator
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


module waveform_generator(
    input wire clk,                    // 10MHz时钟输入
    input wire rst_n,                  // 复位信号，高电平有效
    input wire [7:0] freq_word,        // 频率控制字K(SW7-SW0)
    input wire [1:0] waveform_sel,     // 波形选择(DIP3-DIP2或其他开关)
    output reg [13:0] dac_out,         // 14位D/A转换器数据输出
    output wire clk_dac,               // D/A转换器时钟输出
    output reg [3:0] waveform_type     // 当前波形类型(用于数码管显示)
    );

    // 相位累加器（8位）
    reg [7:0] phase_acc;
    
    // 波形数据（8位）
    reg [7:0] waveform_data;
    
    // 方波生成参数
    parameter SQUARE_HIGH = 8'd255;
    parameter SQUARE_LOW = 8'd0;
    
    // 相位累加器逻辑
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            phase_acc <= 8'd0;
        end else begin
            phase_acc <= phase_acc + freq_word;
        end
    end
    
    // 波形生成逻辑
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            waveform_data <= 8'd128;
            waveform_type <= 4'd0;
        end else begin
            case (waveform_sel)
                // 方波: 占空比50%
                2'b00: begin
                    waveform_type <= 4'd0;  // 显示"0"表示方波
                    if (phase_acc < 8'd128)
                        waveform_data <= SQUARE_HIGH;
                    else
                        waveform_data <= SQUARE_LOW;
                end
                
                // 三角波: 0→255→0线性变化
                2'b01: begin
                    waveform_type <= 4'd1;  // 显示"1"表示三角波
                    if (phase_acc < 8'd128)
                        // 上升沿: 0→255
                        waveform_data <= {phase_acc[6:0], 1'b0};
                    else
                        // 下降沿: 255→0
                        waveform_data <= {~phase_acc[6:0], 1'b0};
                end
                
                // 锯齿波: 0→255线性上升
                2'b10: begin
                    waveform_type <= 4'd2;  // 显示"2"表示锯齿波
                    waveform_data <= phase_acc;
                end
                
                // 反向锯齿波: 255→0线性下降
                2'b11: begin
                    waveform_type <= 4'd3;  // 显示"3"表示反向锯齿波
                    waveform_data <= ~phase_acc;
                end
                
                default: begin
                    waveform_type <= 4'd0;
                    waveform_data <= 8'd128;
                end
            endcase
        end
    end
    
    // D/A转换器输出（扩展到14位）
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            dac_out <= 14'd8192;  // 中间值
        end else begin
            dac_out <= {waveform_data, 6'b0};  // 8位扩展到14位
        end
    end
    
    // D/A时钟输出（与系统时钟同步）
    assign clk_dac = clk;

endmodule
