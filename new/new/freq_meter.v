//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 2025/10/24 10:52:27
//// Design Name: 
//// Module Name: freq_meter
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// 综合频率测量模块 - 结合脉冲计数法和周期测量法
// 测量范围：0 ~ 2MHz
// 测量误差：≤ 1Hz
//////////////////////////////////////////////////////////////////////////////////
module freq_meter(
    // 时钟与复位
    input wire clk_10m,           // 10MHz主时钟
    input wire rst,               // 复位信号（高电平有效）
    
    // ADC接口
    input wire [9:0] adc_data,    // ADC数据输入(AD_D9~AD_D0)
    
    // 闸门时钟输入
    input wire gate_clk,          // 闸门时钟（1Hz）
    
    // 频率测量结果输出
    output reg [31:0] frequency,  // 测量得到的频率值（单位：Hz）
    output reg freq_valid,        // 频率测量完成标志
    output wire clk_adc           // A/D转换器时钟输出
);

    assign clk_adc = clk_10m;
    
    parameter THRESHOLD_HIGH = 10'd522; //10'd550;  // 上升沿阈值（约1.07V）
    parameter THRESHOLD_LOW = 10'd502; //10'd474;   // 下降沿阈值（约0.93V）
    parameter VALID_WIDTH = 16'd20000;   // 脉冲展宽到2ms
    
    // 状态机状态定义
    localparam IDLE = 2'd0;        // 空闲状态：等待闸门开启
    localparam COUNTING = 2'd1;    // 计数状态：在闸门时间内计数脉冲
    localparam DONE = 2'd2;        // 完成状态：输出测量结果
    
    reg [9:0] adc_data_d1;
    reg signal_level;              // 当前信号电平（0=低，1=高）
    reg signal_level_d1;           // 延迟一拍用于边沿检测
    wire rising_edge;              // 上升沿标志
    
    // 闸门时钟边沿检测
    reg gate_clk_d1, gate_clk_d2;
    wire gate_posedge;
    
    reg [31:0] pulse_counter;      // 脉冲计数器
    reg [1:0] state;               // 状态机
    reg counting_enable;           // 计数使能
    
    // 脉冲展宽相关
    reg [31:0] frequency_internal; // 内部计算结果
    reg freq_valid_pulse;          // 内部单周期脉冲
    reg [15:0] valid_counter;      // 脉冲展宽计数器
    reg data_locked;               // 数据锁定标志
    
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            adc_data_d1 <= 10'd512;
            signal_level <= 1'b0;
            signal_level_d1 <= 1'b0;
        end else begin
            adc_data_d1 <= adc_data;
            signal_level_d1 <= signal_level;
            
            // 滞回比较：上升时需要超过高阈值，下降时需要低于低阈值
            if (adc_data_d1 >= THRESHOLD_HIGH) begin
                signal_level <= 1'b1;
            end else if (adc_data_d1 <= THRESHOLD_LOW) begin
                signal_level <= 1'b0;
            end
            // 在两个阈值之间保持原状态
        end
    end
    
    // 检测上升沿（每个正弦周期产生一个脉冲）
    assign rising_edge = signal_level && !signal_level_d1;
    
    // 闸门时钟边沿检测
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            gate_clk_d1 <= 1'b0;
            gate_clk_d2 <= 1'b0;
        end else begin
            gate_clk_d1 <= gate_clk;
            gate_clk_d2 <= gate_clk_d1;
        end
    end
    
    assign gate_posedge = gate_clk_d1 && !gate_clk_d2;
    
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            pulse_counter <= 32'd0;
            frequency_internal <= 32'd0;
            freq_valid_pulse <= 1'b0;
            counting_enable <= 1'b0;
        end else begin
            freq_valid_pulse <= 1'b0;  // 默认清零
            
            case (state)
                // 空闲状态：等待闸门上升沿
                IDLE: begin
                    if (gate_posedge && !data_locked) begin
                        pulse_counter <= 32'd0;
                        counting_enable <= 1'b1;
                        state <= COUNTING;
                    end
                end
                
                COUNTING: begin
                    if (rising_edge && counting_enable) begin
                        pulse_counter <= pulse_counter + 1'b1;
                    end
                    
                    // 检测下一个闸门上升沿（1秒计数完成）
                    if (gate_posedge) begin
                        frequency_internal <= pulse_counter;
                        freq_valid_pulse <= 1'b1;
                        counting_enable <= 1'b0;
                        state <= DONE;
                    end
                end
                
                // 完成状态：等待数据被采样后返回空闲
                DONE: begin
                    if (!data_locked) begin
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // 脉冲展宽逻辑：将100ns的脉冲展宽到2ms
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            freq_valid <= 1'b0;
            frequency <= 32'd0;
            valid_counter <= 16'd0;
            data_locked <= 1'b0;
        end else begin
            if (freq_valid_pulse) begin
                // 检测到新的测量结果，启动展宽
                freq_valid <= 1'b1;
                frequency <= frequency_internal;  // 锁存数据
                valid_counter <= VALID_WIDTH;
                data_locked <= 1'b1;  // 锁定数据，禁止新测量
            end else if (valid_counter > 16'd0) begin
                // 保持 freq_valid 高电平
                valid_counter <= valid_counter - 1'b1;
                freq_valid <= 1'b1;
                data_locked <= 1'b1;  // 保持锁定状态
            end else begin
                // 展宽结束
                freq_valid <= 1'b0;
                data_locked <= 1'b0;  // 解除锁定，允许新测量
            end
        end
    end

endmodule

