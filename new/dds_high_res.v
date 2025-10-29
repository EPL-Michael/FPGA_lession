`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/28 10:21:45
// Design Name: 
// Module Name: dds_high_res
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


module dds_high_res(
    input wire clk,              // 10MHz时钟输入
    input wire rst_n,            // 复位信号，高电平有效
    input wire [7:0] freq_word,  // 基础频率控制字K (SW7-SW0)
    input wire btn_up,           // 按键S0：频率步进增加
    input wire btn_down,         // 按键S3：频率步进减少
    output reg [13:0] dac_sum,   // 14位D/A转换器数据输出
    output wire clk_dac,         // D/A转换器时钟输出
    output reg [2:0] fine_step,  // 当前微调步进值（0-7）
    output reg [31:0] current_freq // 当前输出频率（单位：Hz×1000，用于精确显示）
    );
    
    // 相位累加器（11位：8位主控制字 + 3位微调控制字）
    reg [10:0] phase_acc;
    
    // 完整的频率控制字（11位）
    wire [10:0] freq_word_full;
    assign freq_word_full = {freq_word, fine_step};
    
    // ROM存储正弦波形数据(256个采样点，8位二进制偏移码)
    reg [7:0] sine_rom [0:255];
    
    // D/A转换器8位数据
    reg [7:0] dac_data;
    
    // 按键消抖相关信号
    reg [19:0] btn_up_cnt;      // 按键S0消抖计数器（约100ms）
    reg [19:0] btn_down_cnt;    // 按键S3消抖计数器
    reg btn_up_stable;          // 消抖后的按键S0状态
    reg btn_down_stable;        // 消抖后的按键S3状态
    reg btn_up_prev;            // 按键S0前一状态
    reg btn_down_prev;          // 按键S3前一状态
    wire btn_up_posedge;        // 按键S0上升沿
    wire btn_down_posedge;      // 按键S3上升沿
    
    // 消抖时间参数（10MHz时钟，1000000个周期 = 100ms）
    parameter DEBOUNCE_TIME = 20'd1000000;
    
    // 初始化ROM - 正弦波形数据（二进制偏移码：0-255）
    initial begin
        sine_rom[0]=8'd128; sine_rom[1]=8'd131; sine_rom[2]=8'd134; sine_rom[3]=8'd137;
        sine_rom[4]=8'd140; sine_rom[5]=8'd144; sine_rom[6]=8'd147; sine_rom[7]=8'd150;
        sine_rom[8]=8'd153; sine_rom[9]=8'd156; sine_rom[10]=8'd159; sine_rom[11]=8'd162;
        sine_rom[12]=8'd165; sine_rom[13]=8'd168; sine_rom[14]=8'd171; sine_rom[15]=8'd174;
        sine_rom[16]=8'd177; sine_rom[17]=8'd179; sine_rom[18]=8'd182; sine_rom[19]=8'd185;
        sine_rom[20]=8'd188; sine_rom[21]=8'd191; sine_rom[22]=8'd193; sine_rom[23]=8'd196;
        sine_rom[24]=8'd199; sine_rom[25]=8'd201; sine_rom[26]=8'd204; sine_rom[27]=8'd206;
        sine_rom[28]=8'd209; sine_rom[29]=8'd211; sine_rom[30]=8'd213; sine_rom[31]=8'd216;
        sine_rom[32]=8'd218; sine_rom[33]=8'd220; sine_rom[34]=8'd222; sine_rom[35]=8'd224;
        sine_rom[36]=8'd226; sine_rom[37]=8'd228; sine_rom[38]=8'd230; sine_rom[39]=8'd232;
        sine_rom[40]=8'd234; sine_rom[41]=8'd235; sine_rom[42]=8'd237; sine_rom[43]=8'd239;
        sine_rom[44]=8'd240; sine_rom[45]=8'd241; sine_rom[46]=8'd243; sine_rom[47]=8'd244;
        sine_rom[48]=8'd245; sine_rom[49]=8'd246; sine_rom[50]=8'd248; sine_rom[51]=8'd249;
        sine_rom[52]=8'd250; sine_rom[53]=8'd250; sine_rom[54]=8'd251; sine_rom[55]=8'd252;
        sine_rom[56]=8'd253; sine_rom[57]=8'd253; sine_rom[58]=8'd254; sine_rom[59]=8'd254;
        sine_rom[60]=8'd254; sine_rom[61]=8'd255; sine_rom[62]=8'd255; sine_rom[63]=8'd255;
        sine_rom[64]=8'd255; sine_rom[65]=8'd255; sine_rom[66]=8'd255; sine_rom[67]=8'd255;
        sine_rom[68]=8'd254; sine_rom[69]=8'd254; sine_rom[70]=8'd254; sine_rom[71]=8'd253;
        sine_rom[72]=8'd253; sine_rom[73]=8'd252; sine_rom[74]=8'd251; sine_rom[75]=8'd250;
        sine_rom[76]=8'd250; sine_rom[77]=8'd249; sine_rom[78]=8'd248; sine_rom[79]=8'd246;
        sine_rom[80]=8'd245; sine_rom[81]=8'd244; sine_rom[82]=8'd243; sine_rom[83]=8'd241;
        sine_rom[84]=8'd240; sine_rom[85]=8'd239; sine_rom[86]=8'd237; sine_rom[87]=8'd235;
        sine_rom[88]=8'd234; sine_rom[89]=8'd232; sine_rom[90]=8'd230; sine_rom[91]=8'd228;
        sine_rom[92]=8'd226; sine_rom[93]=8'd224; sine_rom[94]=8'd222; sine_rom[95]=8'd220;
        sine_rom[96]=8'd218; sine_rom[97]=8'd216; sine_rom[98]=8'd213; sine_rom[99]=8'd211;
        sine_rom[100]=8'd209; sine_rom[101]=8'd206; sine_rom[102]=8'd204; sine_rom[103]=8'd201;
        sine_rom[104]=8'd199; sine_rom[105]=8'd196; sine_rom[106]=8'd193; sine_rom[107]=8'd191;
        sine_rom[108]=8'd188; sine_rom[109]=8'd185; sine_rom[110]=8'd182; sine_rom[111]=8'd179;
        sine_rom[112]=8'd177; sine_rom[113]=8'd174; sine_rom[114]=8'd171; sine_rom[115]=8'd168;
        sine_rom[116]=8'd165; sine_rom[117]=8'd162; sine_rom[118]=8'd159; sine_rom[119]=8'd156;
        sine_rom[120]=8'd153; sine_rom[121]=8'd150; sine_rom[122]=8'd147; sine_rom[123]=8'd144;
        sine_rom[124]=8'd140; sine_rom[125]=8'd137; sine_rom[126]=8'd134; sine_rom[127]=8'd131;
        sine_rom[128]=8'd128; sine_rom[129]=8'd125; sine_rom[130]=8'd122; sine_rom[131]=8'd119;
        sine_rom[132]=8'd116; sine_rom[133]=8'd112; sine_rom[134]=8'd109; sine_rom[135]=8'd106;
        sine_rom[136]=8'd103; sine_rom[137]=8'd100; sine_rom[138]=8'd97; sine_rom[139]=8'd94;
        sine_rom[140]=8'd91; sine_rom[141]=8'd88; sine_rom[142]=8'd85; sine_rom[143]=8'd82;
        sine_rom[144]=8'd79; sine_rom[145]=8'd77; sine_rom[146]=8'd74; sine_rom[147]=8'd71;
        sine_rom[148]=8'd68; sine_rom[149]=8'd65; sine_rom[150]=8'd63; sine_rom[151]=8'd60;
        sine_rom[152]=8'd57; sine_rom[153]=8'd55; sine_rom[154]=8'd52; sine_rom[155]=8'd50;
        sine_rom[156]=8'd47; sine_rom[157]=8'd45; sine_rom[158]=8'd43; sine_rom[159]=8'd40;
        sine_rom[160]=8'd38; sine_rom[161]=8'd36; sine_rom[162]=8'd34; sine_rom[163]=8'd32;
        sine_rom[164]=8'd30; sine_rom[165]=8'd28; sine_rom[166]=8'd26; sine_rom[167]=8'd24;
        sine_rom[168]=8'd22; sine_rom[169]=8'd21; sine_rom[170]=8'd19; sine_rom[171]=8'd17;
        sine_rom[172]=8'd16; sine_rom[173]=8'd15; sine_rom[174]=8'd13; sine_rom[175]=8'd12;
        sine_rom[176]=8'd11; sine_rom[177]=8'd10; sine_rom[178]=8'd8; sine_rom[179]=8'd7;
        sine_rom[180]=8'd6; sine_rom[181]=8'd6; sine_rom[182]=8'd5; sine_rom[183]=8'd4;
        sine_rom[184]=8'd3; sine_rom[185]=8'd3; sine_rom[186]=8'd2; sine_rom[187]=8'd2;
        sine_rom[188]=8'd2; sine_rom[189]=8'd1; sine_rom[190]=8'd1; sine_rom[191]=8'd1;
        sine_rom[192]=8'd1; sine_rom[193]=8'd1; sine_rom[194]=8'd1; sine_rom[195]=8'd1;
        sine_rom[196]=8'd2; sine_rom[197]=8'd2; sine_rom[198]=8'd2; sine_rom[199]=8'd3;
        sine_rom[200]=8'd3; sine_rom[201]=8'd4; sine_rom[202]=8'd5; sine_rom[203]=8'd6;
        sine_rom[204]=8'd6; sine_rom[205]=8'd7; sine_rom[206]=8'd8; sine_rom[207]=8'd10;
        sine_rom[208]=8'd11; sine_rom[209]=8'd12; sine_rom[210]=8'd13; sine_rom[211]=8'd15;
        sine_rom[212]=8'd16; sine_rom[213]=8'd17; sine_rom[214]=8'd19; sine_rom[215]=8'd21;
        sine_rom[216]=8'd22; sine_rom[217]=8'd24; sine_rom[218]=8'd26; sine_rom[219]=8'd28;
        sine_rom[220]=8'd30; sine_rom[221]=8'd32; sine_rom[222]=8'd34; sine_rom[223]=8'd36;
        sine_rom[224]=8'd38; sine_rom[225]=8'd40; sine_rom[226]=8'd43; sine_rom[227]=8'd45;
        sine_rom[228]=8'd47; sine_rom[229]=8'd50; sine_rom[230]=8'd52; sine_rom[231]=8'd55;
        sine_rom[232]=8'd57; sine_rom[233]=8'd60; sine_rom[234]=8'd63; sine_rom[235]=8'd65;
        sine_rom[236]=8'd68; sine_rom[237]=8'd71; sine_rom[238]=8'd74; sine_rom[239]=8'd77;
        sine_rom[240]=8'd79; sine_rom[241]=8'd82; sine_rom[242]=8'd85; sine_rom[243]=8'd88;
        sine_rom[244]=8'd91; sine_rom[245]=8'd94; sine_rom[246]=8'd97; sine_rom[247]=8'd100;
        sine_rom[248]=8'd103; sine_rom[249]=8'd106; sine_rom[250]=8'd109; sine_rom[251]=8'd112;
        sine_rom[252]=8'd116; sine_rom[253]=8'd119; sine_rom[254]=8'd122; sine_rom[255]=8'd125;
    end
    
    // 按键S0消抖逻辑
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            btn_up_cnt <= 20'd0;
            btn_up_stable <= 1'b0;
        end else begin
            if (btn_up == btn_up_stable) begin
                btn_up_cnt <= 20'd0;
            end else begin
                btn_up_cnt <= btn_up_cnt + 1'b1;
                if (btn_up_cnt >= DEBOUNCE_TIME) begin
                    btn_up_stable <= btn_up;
                    btn_up_cnt <= 20'd0;
                end
            end
        end
    end
    
    // 按键S3消抖逻辑
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            btn_down_cnt <= 20'd0;
            btn_down_stable <= 1'b0;
        end else begin
            if (btn_down == btn_down_stable) begin
                btn_down_cnt <= 20'd0;
            end else begin
                btn_down_cnt <= btn_down_cnt + 1'b1;
                if (btn_down_cnt >= DEBOUNCE_TIME) begin
                    btn_down_stable <= btn_down;
                    btn_down_cnt <= 20'd0;
                end
            end
        end
    end
    
    // 边沿检测
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            btn_up_prev <= 1'b0;
            btn_down_prev <= 1'b0;
        end else begin
            btn_up_prev <= btn_up_stable;
            btn_down_prev <= btn_down_stable;
        end
    end
    
    assign btn_up_posedge = btn_up_stable && !btn_up_prev;
    assign btn_down_posedge = btn_down_stable && !btn_down_prev;
    
    // 微调步进控制逻辑（0-7循环）
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            fine_step <= 3'd0;
        end else begin
            if (btn_up_posedge) begin
                // 正向步进：0→1→2→...→7→0
                if (fine_step == 3'd7)
                    fine_step <= 3'd0;
                else
                    fine_step <= fine_step + 1'b1;
            end else if (btn_down_posedge) begin
                // 负向步进：0→7→6→...→1→0
                if (fine_step == 3'd0)
                    fine_step <= 3'd7;
                else
                    fine_step <= fine_step - 1'b1;
            end
        end
    end
    
    // 计算当前频率（单位：Hz×1000，用于精确显示）
    // f = (K×8 + fine_step) × (10MHz / 2048) = (K×8 + fine_step) × 4882.8125 Hz
    // 为了精确计算，使用 f×1000 = (K×8 + fine_step) × 4882812.5 / 1000
    // 简化为：f×1000 = (K×8 + fine_step) × 4882813 / 1000
    always @(*) begin
        current_freq = ({freq_word, fine_step} * 32'd4882813) / 32'd1000;
    end
    
    // 相位累加器逻辑（11位）
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            phase_acc <= 11'd0;
        end else begin
            phase_acc <= phase_acc + freq_word_full;
        end
    end
    
    // ROM查找表输出（使用相位累加器的高8位作为地址）
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            dac_data <= 8'd128;
        end else begin
            dac_data <= sine_rom[phase_acc[10:3]]; // 使用高8位作为ROM地址
        end
    end
    
    // D/A转换器输出（扩展到14位）
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            dac_sum <= 14'd0;
        end else begin
            dac_sum <= {dac_data, 6'b0};
        end
    end
    
    // D/A时钟输出（与系统时钟同步）
    assign clk_dac = clk;

endmodule
