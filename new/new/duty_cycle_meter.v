`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: duty_cycle_meter
// Description: 脉冲信号占空比测量模块（修复版 - 解决跨时钟域问题）
// 修复内容：
// 1. 将 duty_valid 信号展宽，确保慢速时钟域能够捕获
// 2. 添加数据锁存机制，避免数据在传输过程中变化
//////////////////////////////////////////////////////////////////////////////////

module duty_cycle_meter(
    input wire clk_10m,           // 10MHz时钟
    input wire rst,               // 复位信号（高电平有效）
    input wire [9:0] adc_data,    // ADC数据输入(0~1023对应0~2V)
    output reg [15:0] duty_cycle, // 占空比值(单位: 0.01%, 范围2000~8000表示20.00%~80.00%)
    output reg duty_valid         // 占空比测量完成标志（展宽后的信号）
);

    // ADC阈值设置（滞回比较器）
    parameter THRESHOLD_HIGH = 10'd520; //10'd550;  // 约1.07V（上升沿阈值）
    parameter THRESHOLD_LOW  = 10'd504; //10'd474;  // 约0.93V（下降沿阈值）
    
    // 状态机状态定义
    localparam IDLE         = 3'd0;  // 空闲状态
    localparam WAIT_LOW     = 3'd1;  // 等待低电平
    localparam WAIT_RISING  = 3'd2;  // 等待上升沿
    localparam COUNT_HIGH   = 3'd3;  // 计数高电平时间
    localparam COUNT_LOW    = 3'd4;  // 计数低电平时间
    localparam CALCULATE    = 3'd5;  // 计算占空比
    localparam DATA_LOCKED  = 3'd6;  //  新增：数据锁定状态，等待展宽结束
    
    reg [2:0] state;
    
    reg [31:0] high_counter;   // 高电平时间计数器
    reg [31:0] period_counter; // 周期计数器
    
    //  添加内部信号用于脉冲展宽
    reg [15:0] duty_cycle_internal;  // 内部计算结果
    reg duty_valid_pulse;             // 内部单周期脉冲
    reg [15:0] valid_counter;         // 脉冲展宽计数器
    parameter VALID_WIDTH = 16'd20000; // 展宽到2ms（20000个10MHz时钟周期）
    
     //  添加数据锁定标志
    reg data_locked;  // 当为1时，禁止更新 duty_cycle 和 duty_valid
    
    reg [9:0] adc_d1;
    
    wire is_high, is_low;
    assign is_high = (adc_d1 >= THRESHOLD_HIGH);
    assign is_low  = (adc_d1 <= THRESHOLD_LOW);
    
    reg prev_is_high;
    wire rising_edge, falling_edge;
    
    // ADC数据采样和边沿检测
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            adc_d1 <= 10'd512;
            prev_is_high <= 1'b0;
        end else begin
            adc_d1 <= adc_data;
            prev_is_high <= is_high;
        end
    end
    
    assign rising_edge  = is_high && !prev_is_high;
    assign falling_edge = !is_high && prev_is_high;
    
    reg [27:0] timeout_counter;
    parameter TIMEOUT_MAX = 28'd10_000_000; // 1秒超时（10MHz时钟）
    
    // 占空比测量状态机
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            high_counter <= 32'd0;
            period_counter <= 32'd0;
            duty_cycle_internal <= 16'd0;
            duty_valid_pulse <= 1'b0;
            timeout_counter <= 28'd0;
            
            //data_locked <= 1'b0; //  初始化数据锁定标志
             
        end else begin
            duty_valid_pulse <= 1'b0;  // 默认清零
            
            case (state)
                IDLE: begin
                    if (!data_locked) begin
                        high_counter <= 32'd0;
                        period_counter <= 32'd0;
                        timeout_counter <= 28'd0;
                        state <= WAIT_LOW;
                    end
                end
                
                WAIT_LOW: begin
                    timeout_counter <= timeout_counter + 1'b1;
                    
                    if (is_low) begin
                        state <= WAIT_RISING;
                        timeout_counter <= 28'd0;
                    end else if (timeout_counter >= TIMEOUT_MAX) begin
                        state <= IDLE;
                    end
                end
                
                WAIT_RISING: begin
                    timeout_counter <= timeout_counter + 1'b1;
                    
                    if (rising_edge) begin
                        high_counter <= 32'd0;
                        period_counter <= 32'd0;
                        state <= COUNT_HIGH;
                        timeout_counter <= 28'd0;
                    end else if (timeout_counter >= TIMEOUT_MAX) begin
                        state <= IDLE;
                    end
                end
                
                COUNT_HIGH: begin
                    timeout_counter <= timeout_counter + 1'b1;
                    high_counter <= high_counter + 1'b1;
                    period_counter <= period_counter + 1'b1;
                    
                    if (falling_edge) begin
                        state <= COUNT_LOW;
                        timeout_counter <= 28'd0;
                    end else if (timeout_counter >= TIMEOUT_MAX) begin
                        state <= IDLE;
                    end
                end
                
                COUNT_LOW: begin
                    timeout_counter <= timeout_counter + 1'b1;
                    period_counter <= period_counter + 1'b1;
                    
                    if (rising_edge) begin
                        state <= CALCULATE;
                        timeout_counter <= 28'd0;
                    end else if (timeout_counter >= TIMEOUT_MAX) begin
                        state <= IDLE;
                    end
                end
                
                CALCULATE: begin
                    if (period_counter > 32'd100) begin
                        // 占空比 = (高电平时间 / 周期) × 10000
                        duty_cycle_internal <= (high_counter * 64'd10000) / period_counter;
                        duty_valid_pulse <= 1'b1;  //  产生单周期脉冲
                    end else begin
                        duty_cycle_internal <= 16'd0;
                    end
                    
                    //state <= IDLE;
                    state <= DATA_LOCKED;
                end
                
                //  新增状态：等待数据展宽结束
                DATA_LOCKED: begin
                    // 等待 data_locked 标志被清除（由脉冲展宽逻辑控制）
                    if (!data_locked) begin
                        state <= IDLE;  // 数据已被采样，可以开始新测量
                    end
                    // 否则保持在此状态，阻止新测量开始
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    //  脉冲展宽逻辑：将100ns的脉冲展宽到2ms
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            duty_valid <= 1'b0;
            duty_cycle <= 16'd0;
            valid_counter <= 16'd0;
            data_locked <= 1'b0;
        end else begin
            if (duty_valid_pulse) begin
                // 检测到新的测量结果，启动展宽
                duty_valid <= 1'b1;
                duty_cycle <= duty_cycle_internal;  // 锁存数据
                valid_counter <= VALID_WIDTH;
                data_locked <= 1'b1;  //  锁定数据，禁止新测量更新
            end else if (valid_counter > 16'd0) begin
                // 保持 duty_valid 高电平
                valid_counter <= valid_counter - 1'b1;
                duty_valid <= 1'b1;
                data_locked <= 1'b1;  //  保持锁定状态
            end else begin
                // 展宽结束
                duty_valid <= 1'b0;
                data_locked <= 1'b0;  //  解除锁定，允许新测量
            end
        end
    end

endmodule
