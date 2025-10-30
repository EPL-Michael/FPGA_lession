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
    input wire clk,                    // 10MHzʱ������
    input wire rst_n,                  // ��λ�źţ��ߵ�ƽ��Ч
    input wire [7:0] freq_word,        // Ƶ�ʿ�����K(SW7-SW0)
    input wire [1:0] waveform_sel,     // ����ѡ��(DIP3-DIP2����������)
    output reg [13:0] dac_out,         // 14λD/Aת�����������
    output wire clk_dac,               // D/Aת����ʱ�����
    output reg [3:0] waveform_type     // ��ǰ��������(�����������ʾ)
    );

    // ��λ�ۼ�����8λ��
    reg [7:0] phase_acc;
    
    // �������ݣ�8λ��
    reg [7:0] waveform_data;
    
    // �������ɲ���
    parameter SQUARE_HIGH = 8'd255;
    parameter SQUARE_LOW = 8'd0;
    
    // ��λ�ۼ����߼�
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            phase_acc <= 8'd0;
        end else begin
            phase_acc <= phase_acc + freq_word;
        end
    end
    
    // ���������߼�
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            waveform_data <= 8'd128;
            waveform_type <= 4'd0;
        end else begin
            case (waveform_sel)
                // ����: ռ�ձ�50%
                2'b00: begin
                    waveform_type <= 4'd0;  // ��ʾ"0"��ʾ����
                    if (phase_acc < 8'd128)
                        waveform_data <= SQUARE_HIGH;
                    else
                        waveform_data <= SQUARE_LOW;
                end
                
                // ���ǲ�: 0��255��0���Ա仯
                2'b01: begin
                    waveform_type <= 4'd1;  // ��ʾ"1"��ʾ���ǲ�
                    if (phase_acc < 8'd128)
                        // ������: 0��255
                        waveform_data <= {phase_acc[6:0], 1'b0};
                    else
                        // �½���: 255��0
                        waveform_data <= {~phase_acc[6:0], 1'b0};
                end
                
                // ��ݲ�: 0��255��������
                2'b10: begin
                    waveform_type <= 4'd2;  // ��ʾ"2"��ʾ��ݲ�
                    waveform_data <= phase_acc;
                end
                
                // �����ݲ�: 255��0�����½�
                2'b11: begin
                    waveform_type <= 4'd3;  // ��ʾ"3"��ʾ�����ݲ�
                    waveform_data <= ~phase_acc;
                end
                
                default: begin
                    waveform_type <= 4'd0;
                    waveform_data <= 8'd128;
                end
            endcase
        end
    end
    
    // D/Aת�����������չ��14λ��
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            dac_out <= 14'd8192;  // �м�ֵ
        end else begin
            dac_out <= {waveform_data, 6'b0};  // 8λ��չ��14λ
        end
    end
    
    // D/Aʱ���������ϵͳʱ��ͬ����
    assign clk_dac = clk;

endmodule
