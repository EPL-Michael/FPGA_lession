`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 15:43:10
// Design Name: 
// Module Name: number
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


module number(
    //input ad_freq,
    input freq_source,
    input rst,
    input wire [7:0] sw,         // 频率控制字K (SW7-SW0)
    input wire [1:0] dip,        // 显示模式选择 (DIP1-DIP0)
    
    input wire [31:0] freq_data,   // 频率数据（Hz）
    input wire freq_valid,         // 数据有效标志
    
    input wire [15:0] duty_data,      // 添加占空比数据输入（单位：0.01%）
    input wire duty_valid,            // 占空比数据有效标志
    
    input wire [31:0] high_res_freq,  // 高分辨率频率（单位：Hz×1000）
    input wire [2:0] fine_step,       // 微调步进值（0-7）
    
    output reg [7:0] seg_left,
    output reg [7:0] seg_right,
    output reg [3:0] an_left,
    output reg [3:0] an_right
    );
    reg [1:0] scan_counter;   //位选
    reg [3:0] current_digit;   //初始数字
    reg current_dp;  //小数点
    reg [6:0] seg_pattern;   //数码管数字
    reg group_sel;               // 组选择: 0=左侧组, 1=右侧组
    
    //位选递加
    always @(posedge freq_source or posedge rst) begin
        if (rst) begin
            scan_counter <= 2'd0;
            group_sel <=1'b0;
        end else begin
            if (scan_counter == 2'd3)begin
                scan_counter <= 2'd0;
                group_sel <= ~group_sel;  // 切换组
            end
            else
                scan_counter <= scan_counter + 1'b1;
        end
    end
    
    //输出频率显示
//    reg [31:0] freq_value;  // 频率值 (单位: Hz)
//    reg [3:0] freq_digits [7:0];  // 8位频率显示数字
    
    reg [31:0] high_res_freq_hz;      // 高分辨率频率（单位：Hz）
    reg [3:0] high_res_digits[7:0];   // 8位高分辨率频率显示数字
    
//    always @(*) begin
//        // 计算频率: f = K × 39062.5 Hz
//        // 为了避免浮点运算，计算 f × 10 = K × 390625
//        freq_value = sw * 32'd39062;  // 近似值
//    end
    
    // 将高分辨率频率从Hz×1000转换为Hz
    always @(*) begin
        high_res_freq_hz = high_res_freq;   // / 32'd1000;
    end
    
    integer i;
//    reg [31:0] temp_freq;
    reg [31:0] temp_high_res;
    
    always @(*) begin
//        temp_freq = freq_value;
//        for (i = 0; i < 8; i = i + 1) begin
//            freq_digits[i] = temp_freq % 10;
//            temp_freq = temp_freq / 10;
//        end
        temp_high_res = high_res_freq_hz;
        for (i = 0; i < 8; i = i + 1) begin
            high_res_digits[i] = temp_high_res % 10;
            temp_high_res = temp_high_res / 10;
        end
    end
    
    //输入频率显示
    reg [3:0] bcd[7:0];            // 8位BCD码（每位0~9）
    reg [31:0] freq_display;       // 当前显示的频率值
    
    // 当freq_valid为高时，锁存新的频率值
    always @(posedge freq_source or posedge rst) begin
        if (rst) begin
            freq_display <= 32'd0;
        end else if (freq_valid) begin
            freq_display <= freq_data;
        end
    end
    
    integer j;
    reg [31:0] temp_meter;
    
    always @(*) begin
        temp_meter = freq_display;
        for (j = 0; j < 8; j = j + 1) begin
            bcd[j] = temp_meter % 10;        // 取个位数
            temp_meter = temp_meter / 10;          // 右移一位（除以10）
        end
    end
    
    //占空比显示
    reg [3:0] duty_bcd[3:0];
    reg [15:0] duty_display;
    
    always @(posedge freq_source or posedge rst) begin
        if (rst) begin
            duty_display <= 16'd0;
        end else if (duty_valid) begin
            duty_display <= duty_data;
        end
    end
    
    integer k;
    reg [15:0] temp_duty;
    always @(*) begin
        temp_duty = duty_display;
        for (k = 0; k < 4; k = k + 1) begin
            duty_bcd[k] = temp_duty % 10;
            temp_duty = temp_duty / 10;
        end
    end
    
    //数字译码
    always @(*) begin
        case (current_digit)
            4'd0: seg_pattern = 7'b0111111;  // 0
            4'd1: seg_pattern = 7'b0000110;  // 1
            4'd2: seg_pattern = 7'b1011011;  // 2
            4'd3: seg_pattern = 7'b1001111;  // 3
            4'd4: seg_pattern = 7'b1100110;  // 4
            4'd5: seg_pattern = 7'b1101101;  // 5
            4'd6: seg_pattern = 7'b1111101;  // 6
            4'd7: seg_pattern = 7'b0000111;  // 7
            4'd8: seg_pattern = 7'b1111111;  // 8
            4'd9: seg_pattern = 7'b1101111;  // 9
            default: seg_pattern = 7'b0000000;  // 全灭
        endcase
    end
    
    //位选实现
    always @(*) begin
        if (group_sel == 1'b0) begin
            // 左侧组激活，右侧组全部关闭
            case (scan_counter)
                2'd0: an_left = 4'b0001;  // 选中 an0_left
                2'd1: an_left = 4'b0010;  // 选中 an1_left
                2'd2: an_left = 4'b0100;  // 选中 an2_left
                2'd3: an_left = 4'b1000;  // 选中 an3_left
                default: an_left = 4'b0000;
            endcase
            an_right = 4'b0000;  // 右侧组全部关闭
        end else begin
            // 右侧组激活，左侧组全部关闭
            an_left = 4'b0000;   // 左侧组全部关闭
            case (scan_counter)
                2'd0: an_right = 4'b0001;  // 选中 an0_right
                2'd1: an_right = 4'b0010;  // 选中 an1_right
                2'd2: an_right = 4'b0100;  // 选中 an2_right
                2'd3: an_right = 4'b1000;  // 选中 an3_right
                default: an_right = 4'b0000;
            endcase
        end
    end

    reg [3:0] display_left [3:0];   //显示数字
    reg [3:0] display_right [3:0];
    reg [3:0] dp_left;   //显示小数点
    reg [3:0] dp_right;
    
    always @(*) begin
        if (dip == 2'b00) begin
            // 左侧组: "2025" (从左到右)
            display_left[3] = 4'd2;  // an3_left (最左)
            display_left[2] = 4'd0;  // an2_left
            display_left[1] = 4'd2;  // an1_left
            display_left[0] = 4'd5;  // an0_left (最右), 小数点亮
            
            // 右侧组: "0211" (从左到右)
            display_right[3] = 4'd0; // an3_right (最左)
            display_right[2] = 4'd2; // an2_right
            display_right[1] = 4'd1; // an1_right
            display_right[0] = 4'd1; // an0_right (最右)
            
            dp_left = 4'b0001;       // 只有 an0_left 小数点亮
            dp_right = 4'b0000;      // 右侧组无小数点
        end else if (dip == 2'b01) begin
            // 模式01: 显示频率值，第5位小数点亮
            // 8位显示: [7][6][5][4].[3][2][1][0]
            display_left[3] = high_res_digits[7];  // 最高位
            display_left[2] = high_res_digits[6];
            display_left[1] = high_res_digits[5];
            display_left[0] = high_res_digits[4];  
            
            display_right[3] = high_res_digits[3];  // 小数点位置
            display_right[2] = high_res_digits[2];
            display_right[1] = high_res_digits[1];
            display_right[0] = high_res_digits[0];  // 最低位
            
            dp_left = 4'b0000;       // 第5位小数点亮 (an0_left)
            dp_right = 4'b1000;
        end else if (dip == 2'b10) begin
            display_left[3] = bcd[7];  // 最高位
            display_left[2] = bcd[6];
            display_left[1] = bcd[5];
            display_left[0] = bcd[4];  
            
            display_right[3] = bcd[3];  // 小数点位置
            display_right[2] = bcd[2];
            display_right[1] = bcd[1];
            display_right[0] = bcd[0];  // 最低位
            
            dp_left = 4'b0000;       // 第5位小数点亮 (an0_left)
            dp_right = 4'b1000;
        end else if (dip == 2'b11) begin
            display_left[3] = 4'd0;           // 最高位
            display_left[2] = 4'd0;
            display_left[1] = 4'd0;    // 十位
            display_left[0] = 4'd0;    // 个位
            display_right[3] = 4'd0;   // 小数点后第1位
            display_right[2] = 4'd0;   // 小数点后第2位
            display_right[1] = duty_bcd[3];
            display_right[0] = duty_bcd[2];          // 最低位
            dp_left = 4'b0000;                // 第6位小数点亮(an0_left)
            dp_right = 4'b0100;
        end
    end
    
    //将需要的数字显示
    always @(*) begin
        if (group_sel == 1'b0) begin
            // 左侧组
            current_digit = display_left[scan_counter];
            current_dp = dp_left[scan_counter];
        end else begin
            // 右侧组
            current_digit = display_right[scan_counter];
            current_dp = dp_right[scan_counter];
        end
    end
        
    //小数点和数字组合
    always @(*) begin
        if (group_sel == 1'b0) begin
            seg_left = {current_dp, seg_pattern};  // {dp, g, f, e, d, c, b, a}
            seg_right = 8'b00000000;
        end
        else begin
            seg_right = {current_dp, seg_pattern};
            seg_left = 8'b00000000;
        end
    end
    
endmodule
