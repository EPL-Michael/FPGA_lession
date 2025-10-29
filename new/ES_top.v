`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/22 15:20:39
// Design Name: 
// Module Name: ES_top
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


module ES_top(
    input wire clk_t,
    input wire clr_t,
    input wire [7:0] sw_t,
    input wire [1:0] dip_t,
    
    input wire [9:0] ad_data_t,      // ADC数据输入 (AD_D9~AD_D0)
    
    output wire clk_10MHz_t,
    output wire clk_1kHz_t,
    
    output wire [7:0] seg_left_t,
    output wire [7:0] seg_right_t,
    output wire [3:0] an_left_t,
    output wire [3:0] an_right_t,
    
    output wire [13:0] dac_sum_t,   // D/A转换器数据输出 (DA_D0~DA_D13)
    output wire clk_dac_t,          // D/A转换器时钟输出
    output wire clk_adc_t,
    //output wire [31:0] frequency_t
    
    input wire btn_up_t,           
    input wire btn_down_t
    );
    
    // 内部信号
//    wire clk_10m;                  // 10MHz时钟（ADC采样时钟）
    wire clk_1hz_t;                  // 1Hz时钟（频率测量闸门）
    
    wire [31:0] frequency_t;         // 测量得到的频率值（Hz）
    wire freq_valid_t;               // 频率测量完成标志
    
    wire [15:0] duty_cycle_t;         // 占空比值（单位：0.01%）
    wire duty_valid_t;                // 占空比测量完成标志
    
    wire [2:0] fine_step_t;  // 当前微调步进值（0-7）
    wire [31:0] current_freq_t;  // 当前输出频率（单位：Hz×1000，用于精确显示）
    
    freq_division u_freq_division(
        .clk(clk_t),
        .clr(clr_t),
        .clk_10MHz(clk_10MHz_t),
        .clk_1kHz(clk_1kHz_t),
        .clk_1hz(clk_1hz_t)
    );
    
    number u_number(
        //.ad_freq(clk_10MHz_t),
        .freq_source(clk_1kHz_t),
        .rst(clr_t),
        .sw(sw_t),
        .dip(dip_t),
        .seg_left(seg_left_t),
        .seg_right(seg_right_t),
        .an_left(an_left_t),
        .an_right(an_right_t),
        .freq_data(frequency_t),
        .freq_valid(freq_valid_t),
        .duty_data(duty_cycle_t),     // 连接占空比数据
        .duty_valid(duty_valid_t),     // 连接占空比有效标志
        .high_res_freq(current_freq_t),
        .fine_step(fine_step_t)
    );
    
//    dds u_dds(
//        .clk(clk_10MHz_t),              // 10MHz时钟输入
//        .rst_n(clr_t),            // 复位信号，低电平有效
//        .freq_word(sw_t),  // 频率控制字K (0-63对应0-2.5MHz)
//        .dac_sum(dac_sum_t),   // D/A转换器数据输出 (DA_D0~DA_D7)
//        .clk_dac(clk_dac_t)           // D/A转换器时钟输出
//        );
        
    freq_meter u_freq_meter(
        .clk_10m(clk_10MHz_t),
        .rst(clr_t),
        .adc_data(ad_data_t),
        .gate_clk(clk_1hz_t),
        .frequency(frequency_t),
        .freq_valid(freq_valid_t),
        .clk_adc(clk_adc_t)
    );
    
    duty_cycle_meter u_duty_cycle_meter(
        .clk_10m(clk_10MHz_t),
        .rst(clr_t),
        .adc_data(ad_data_t),
        .duty_cycle(duty_cycle_t),
        .duty_valid(duty_valid_t)
        //.measuring()                  // 测量进行中标志（未使用）
    );
    
    dds_high_res u_dds_high_res(
    .clk(clk_10MHz_t),              // 10MHz时钟输入
    .rst_n(clr_t),            // 复位信号，高电平有效
    .freq_word(sw_t),  // 基础频率控制字K (SW7-SW0)
    .btn_up(btn_up_t),           // 按键S0：频率步进增加
    .btn_down(btn_down_t),         // 按键S3：频率步进减少
    .dac_sum(dac_sum_t),   // 14位D/A转换器数据输出
    .clk_dac(clk_dac_t),         // D/A转换器时钟输出
    .fine_step(fine_step_t),  // 当前微调步进值（0-7）
    .current_freq(current_freq_t) // 当前输出频率（单位：Hz×1000，用于精确显示）
    );
    
    ila_0 your_instance_name (
	.clk(clk_t), // input wire clk


	.probe0(ad_data_t) // input wire [9:0] probe0
);

endmodule
