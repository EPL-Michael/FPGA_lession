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
// �ۺ�Ƶ�ʲ���ģ�� - �����������������ڲ�����
// ������Χ��0 ~ 2MHz
// �������� 1Hz
//////////////////////////////////////////////////////////////////////////////////
module freq_meter(
    // ʱ���븴λ
    input wire clk_10m,           // 10MHz��ʱ��
    input wire rst,               // ��λ�źţ��ߵ�ƽ��Ч��
    
    // ADC�ӿ�
    input wire [9:0] adc_data,    // ADC��������(AD_D9~AD_D0)
    
    // բ��ʱ������
    input wire gate_clk,          // բ��ʱ�ӣ�1Hz��
    
    // Ƶ�ʲ���������
    output reg [31:0] frequency,  // �����õ���Ƶ��ֵ����λ��Hz��
    output reg freq_valid,        // Ƶ�ʲ�����ɱ�־
    output wire clk_adc           // A/Dת����ʱ�����
);

    assign clk_adc = clk_10m;
    
    parameter THRESHOLD_HIGH = 10'd522; //10'd550;  // ��������ֵ��Լ1.07V��
    parameter THRESHOLD_LOW = 10'd502; //10'd474;   // �½�����ֵ��Լ0.93V��
    parameter VALID_WIDTH = 16'd20000;   // ����չ��2ms
    
    // ״̬��״̬����
    localparam IDLE = 2'd0;        // ����״̬���ȴ�բ�ſ���
    localparam COUNTING = 2'd1;    // ����״̬����բ��ʱ���ڼ�������
    localparam DONE = 2'd2;        // ���״̬������������
    
    reg [9:0] adc_data_d1;
    reg signal_level;              // ��ǰ�źŵ�ƽ��0=�ͣ�1=�ߣ�
    reg signal_level_d1;           // �ӳ�һ�����ڱ��ؼ��
    wire rising_edge;              // �����ر�־
    
    // բ��ʱ�ӱ��ؼ��
    reg gate_clk_d1, gate_clk_d2;
    wire gate_posedge;
    
    reg [31:0] pulse_counter;      // ���������
    reg [1:0] state;               // ״̬��
    reg counting_enable;           // ����ʹ��
    
    // ����չ�����
    reg [31:0] frequency_internal; // �ڲ�������
    reg freq_valid_pulse;          // �ڲ�����������
    reg [15:0] valid_counter;      // ����չ�������
    reg data_locked;               // ����������־
    
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            adc_data_d1 <= 10'd512;
            signal_level <= 1'b0;
            signal_level_d1 <= 1'b0;
        end else begin
            adc_data_d1 <= adc_data;
            signal_level_d1 <= signal_level;
            
            // �ͻرȽϣ�����ʱ��Ҫ��������ֵ���½�ʱ��Ҫ���ڵ���ֵ
            if (adc_data_d1 >= THRESHOLD_HIGH) begin
                signal_level <= 1'b1;
            end else if (adc_data_d1 <= THRESHOLD_LOW) begin
                signal_level <= 1'b0;
            end
            // ��������ֵ֮�䱣��ԭ״̬
        end
    end
    
    // ��������أ�ÿ���������ڲ���һ�����壩
    assign rising_edge = signal_level && !signal_level_d1;
    
    // բ��ʱ�ӱ��ؼ��
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
            freq_valid_pulse <= 1'b0;  // Ĭ������
            
            case (state)
                // ����״̬���ȴ�բ��������
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
                    
                    // �����һ��բ�������أ�1�������ɣ�
                    if (gate_posedge) begin
                        frequency_internal <= pulse_counter;
                        freq_valid_pulse <= 1'b1;
                        counting_enable <= 1'b0;
                        state <= DONE;
                    end
                end
                
                // ���״̬���ȴ����ݱ������󷵻ؿ���
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
    
    // ����չ���߼�����100ns������չ��2ms
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            freq_valid <= 1'b0;
            frequency <= 32'd0;
            valid_counter <= 16'd0;
            data_locked <= 1'b0;
        end else begin
            if (freq_valid_pulse) begin
                // ��⵽�µĲ������������չ��
                freq_valid <= 1'b1;
                frequency <= frequency_internal;  // ��������
                valid_counter <= VALID_WIDTH;
                data_locked <= 1'b1;  // �������ݣ���ֹ�²���
            end else if (valid_counter > 16'd0) begin
                // ���� freq_valid �ߵ�ƽ
                valid_counter <= valid_counter - 1'b1;
                freq_valid <= 1'b1;
                data_locked <= 1'b1;  // ��������״̬
            end else begin
                // չ�����
                freq_valid <= 1'b0;
                data_locked <= 1'b0;  // ��������������²���
            end
        end
    end

endmodule

