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
    input wire [7:0] sw,         // Ƶ�ʿ�����K (SW7-SW0)
    input wire [1:0] dip,        // ��ʾģʽѡ�� (DIP1-DIP0)
    
    input wire [31:0] freq_data,   // Ƶ�����ݣ�Hz��
    input wire freq_valid,         // ������Ч��־
    
    input wire [15:0] duty_data,      // ���ռ�ձ��������루��λ��0.01%��
    input wire duty_valid,            // ռ�ձ�������Ч��־
    
    input wire [31:0] high_res_freq,  // �߷ֱ���Ƶ�ʣ���λ��Hz��1000��
    input wire [2:0] fine_step,       // ΢������ֵ��0-7��
    
    output reg [7:0] seg_left,
    output reg [7:0] seg_right,
    output reg [3:0] an_left,
    output reg [3:0] an_right
    );
    reg [1:0] scan_counter;   //λѡ
    reg [3:0] current_digit;   //��ʼ����
    reg current_dp;  //С����
    reg [6:0] seg_pattern;   //���������
    reg group_sel;               // ��ѡ��: 0=�����, 1=�Ҳ���
    
    //λѡ�ݼ�
    always @(posedge freq_source or posedge rst) begin
        if (rst) begin
            scan_counter <= 2'd0;
            group_sel <=1'b0;
        end else begin
            if (scan_counter == 2'd3)begin
                scan_counter <= 2'd0;
                group_sel <= ~group_sel;  // �л���
            end
            else
                scan_counter <= scan_counter + 1'b1;
        end
    end
    
    //���Ƶ����ʾ
//    reg [31:0] freq_value;  // Ƶ��ֵ (��λ: Hz)
//    reg [3:0] freq_digits [7:0];  // 8λƵ����ʾ����
    
    reg [31:0] high_res_freq_hz;      // �߷ֱ���Ƶ�ʣ���λ��Hz��
    reg [3:0] high_res_digits[7:0];   // 8λ�߷ֱ���Ƶ����ʾ����
    
//    always @(*) begin
//        // ����Ƶ��: f = K �� 39062.5 Hz
//        // Ϊ�˱��⸡�����㣬���� f �� 10 = K �� 390625
//        freq_value = sw * 32'd39062;  // ����ֵ
//    end
    
    // ���߷ֱ���Ƶ�ʴ�Hz��1000ת��ΪHz
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
    
    //����Ƶ����ʾ
    reg [3:0] bcd[7:0];            // 8λBCD�루ÿλ0~9��
    reg [31:0] freq_display;       // ��ǰ��ʾ��Ƶ��ֵ
    
    // ��freq_validΪ��ʱ�������µ�Ƶ��ֵ
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
            bcd[j] = temp_meter % 10;        // ȡ��λ��
            temp_meter = temp_meter / 10;          // ����һλ������10��
        end
    end
    
    //ռ�ձ���ʾ
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
    
    //��������
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
            default: seg_pattern = 7'b0000000;  // ȫ��
        endcase
    end
    
    //λѡʵ��
    always @(*) begin
        if (group_sel == 1'b0) begin
            // ����鼤��Ҳ���ȫ���ر�
            case (scan_counter)
                2'd0: an_left = 4'b0001;  // ѡ�� an0_left
                2'd1: an_left = 4'b0010;  // ѡ�� an1_left
                2'd2: an_left = 4'b0100;  // ѡ�� an2_left
                2'd3: an_left = 4'b1000;  // ѡ�� an3_left
                default: an_left = 4'b0000;
            endcase
            an_right = 4'b0000;  // �Ҳ���ȫ���ر�
        end else begin
            // �Ҳ��鼤������ȫ���ر�
            an_left = 4'b0000;   // �����ȫ���ر�
            case (scan_counter)
                2'd0: an_right = 4'b0001;  // ѡ�� an0_right
                2'd1: an_right = 4'b0010;  // ѡ�� an1_right
                2'd2: an_right = 4'b0100;  // ѡ�� an2_right
                2'd3: an_right = 4'b1000;  // ѡ�� an3_right
                default: an_right = 4'b0000;
            endcase
        end
    end

    reg [3:0] display_left [3:0];   //��ʾ����
    reg [3:0] display_right [3:0];
    reg [3:0] dp_left;   //��ʾС����
    reg [3:0] dp_right;
    
    always @(*) begin
        if (dip == 2'b00) begin
            // �����: "2025" (������)
            display_left[3] = 4'd2;  // an3_left (����)
            display_left[2] = 4'd0;  // an2_left
            display_left[1] = 4'd2;  // an1_left
            display_left[0] = 4'd5;  // an0_left (����), С������
            
            // �Ҳ���: "0211" (������)
            display_right[3] = 4'd0; // an3_right (����)
            display_right[2] = 4'd2; // an2_right
            display_right[1] = 4'd1; // an1_right
            display_right[0] = 4'd1; // an0_right (����)
            
            dp_left = 4'b0001;       // ֻ�� an0_left С������
            dp_right = 4'b0000;      // �Ҳ�����С����
        end else if (dip == 2'b01) begin
            // ģʽ01: ��ʾƵ��ֵ����5λС������
            // 8λ��ʾ: [7][6][5][4].[3][2][1][0]
            display_left[3] = high_res_digits[7];  // ���λ
            display_left[2] = high_res_digits[6];
            display_left[1] = high_res_digits[5];
            display_left[0] = high_res_digits[4];  
            
            display_right[3] = high_res_digits[3];  // С����λ��
            display_right[2] = high_res_digits[2];
            display_right[1] = high_res_digits[1];
            display_right[0] = high_res_digits[0];  // ���λ
            
            dp_left = 4'b0000;       // ��5λС������ (an0_left)
            dp_right = 4'b1000;
        end else if (dip == 2'b10) begin
            display_left[3] = bcd[7];  // ���λ
            display_left[2] = bcd[6];
            display_left[1] = bcd[5];
            display_left[0] = bcd[4];  
            
            display_right[3] = bcd[3];  // С����λ��
            display_right[2] = bcd[2];
            display_right[1] = bcd[1];
            display_right[0] = bcd[0];  // ���λ
            
            dp_left = 4'b0000;       // ��5λС������ (an0_left)
            dp_right = 4'b1000;
        end else if (dip == 2'b11) begin
            display_left[3] = 4'd0;           // ���λ
            display_left[2] = 4'd0;
            display_left[1] = 4'd0;    // ʮλ
            display_left[0] = 4'd0;    // ��λ
            display_right[3] = 4'd0;   // С������1λ
            display_right[2] = 4'd0;   // С������2λ
            display_right[1] = duty_bcd[3];
            display_right[0] = duty_bcd[2];          // ���λ
            dp_left = 4'b0000;                // ��6λС������(an0_left)
            dp_right = 4'b0100;
        end
    end
    
    //����Ҫ��������ʾ
    always @(*) begin
        if (group_sel == 1'b0) begin
            // �����
            current_digit = display_left[scan_counter];
            current_dp = dp_left[scan_counter];
        end else begin
            // �Ҳ���
            current_digit = display_right[scan_counter];
            current_dp = dp_right[scan_counter];
        end
    end
        
    //С������������
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
