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


//module freq_meter(
//    // ʱ���븴λ
//    input wire clk_10m,           // 10MHz��ʱ��
//    input wire rst,                // ��λ�źţ��ߵ�ƽ��Ч��
    
//    // ADC�ӿ�
//    input wire [9:0] adc_data,     // ADC�������� (AD_D9~AD_D0)
//                                   // ���ݷ�Χ��0~1023 ��Ӧ 0~2V
//                                   // 512��Ӧ1V�������ź�����ֵ��
    
//    // բ��ʱ������
//    input wire gate_clk,           // բ��ʱ�ӣ�1Hz�����ڲ���1��բ��ʱ�䣩
    
//    // Ƶ�ʲ���������
//    output reg [31:0] frequency,   // �����õ���Ƶ��ֵ����λ��Hz��
//    output reg freq_valid,         // Ƶ�ʲ�����ɱ�־���ߵ�ƽ��Ч������1��ʱ�����ڣ�
//    output wire clk_adc           // A/Dת����ʱ�����
    
//    //output reg measuring          // ���������б�־���ߵ�ƽ��ʾ���ڲ�����
//    );
    
//    reg measuring;
    
//    assign clk_adc = clk_10m;
    
//    // ADC��ֵ�����ڹ�����
//    // ADC���Ϊ10λ�������룺0V->0, 1V->512, 2V->1023
//    // �����ź�����ֵΪ1V����ӦADCֵ512
//    parameter THRESHOLD = 10'd512;
    
//    // ״̬��״̬����
//    localparam IDLE     = 2'd0;    // ����״̬���ȴ�բ�ſ���
//    localparam COUNTING = 2'd1;    // ����״̬����բ��ʱ���ڼ�������
//    localparam DONE     = 2'd2;    // ���״̬������������
    
//    // ����������ź�
//    reg [9:0] adc_data_d1;         // ADC�����ӳ�1�ģ����ڱ��ؼ�⣩
//    reg [9:0] adc_data_d2;         // ADC�����ӳ�2�ģ����ڱ��ؼ�⣩
//    wire cross_up;                 // �����ع����־
//    reg signal_pulse;              // �������������ź�
    
//    // բ��ʱ�ӱ��ؼ���ź�
//    reg gate_clk_d1;               // բ��ʱ���ӳ�1��
//    reg gate_clk_d2;               // բ��ʱ���ӳ�2��
//    wire gate_posedge;             // բ��ʱ�������ر�־
    
//    // Ƶ�ʲ�������ź�
//    reg [31:0] pulse_counter;      // ������������ۼ�բ��ʱ���ڵ���������
    
//    reg [31:0] pulse_counter_temp; // ��ʱ�����������ڴ���߽�������
    
//    reg [1:0] state;               // ״̬����ǰ״̬
//    reg counting_enable;           // ����ʹ���ź�
    
//    // �����ع����⣺ǰһ�������� < ��ֵ����ǰ������ >= ��ֵ
//    assign cross_up = (adc_data_d2 < THRESHOLD) && (adc_data_d1 >= THRESHOLD);
    
//    // �������߼�
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            adc_data_d1 <= 10'd0;
//            adc_data_d2 <= 10'd0;
//            signal_pulse <= 1'b0;
//        end else begin
//            // �����ӳ��������ڱ��ؼ��
//            adc_data_d1 <= adc_data;
//            adc_data_d2 <= adc_data_d1;
            
//            // ֻ�������ع���ʱ�������壨ÿ���������ڲ���һ�����壩
//            signal_pulse <= cross_up;
//        end
//    end
    
//    // բ��ʱ�ӱ��ؼ��
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            gate_clk_d1 <= 1'b0;
//            gate_clk_d2 <= 1'b0;
//        end else begin
//            gate_clk_d1 <= gate_clk;
//            gate_clk_d2 <= gate_clk_d1;
//        end
//    end
    
//    // բ��ʱ�������ر�־
//    assign gate_posedge = gate_clk_d1 && !gate_clk_d2;
    
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            state <= IDLE;
//            pulse_counter <= 32'd0;
            
//            pulse_counter_temp <= 32'd0;
            
//            frequency <= 32'd0;
//            freq_valid <= 1'b0;
//            counting_enable <= 1'b0;
//        end else begin
//            case (state)
//                //--------------------------------------------------------------
//                // ״̬0��IDLE - ����״̬
//                // ���ܣ��ȴ�բ��ʱ�������أ�׼����ʼ��һ�ֲ���
//                //--------------------------------------------------------------
//                IDLE: begin
//                    //freq_valid <= 1'b0;              // ���������ɱ�־
//                    measuring <= 1'b0;               // ������������б�־
                    
//                    if (gate_posedge) begin          // ��⵽բ�ſ���
//                        pulse_counter <= 32'd0;      // �������������
                        
//                        pulse_counter_temp <= 32'd0; // ������ʱ������
                        
//                        counting_enable <= 1'b1;     // ʹ�ܼ���
//                        state <= COUNTING;           // �������״̬
                        
//                        measuring <= 1'b1;           // ��λ���������б�־
//                        freq_valid <= 1'b0;          // ����ϴβ�����ɱ�־
//                    end
//                end
                
//                //--------------------------------------------------------------
//                // ״̬1��COUNTING - ����״̬
//                // ���ܣ���1��բ��ʱ���ڣ��Թ����������������м���
//                //       ����ֵNs��Ϊ�ź���1���ڵ���������Ҳ����Ƶ��ֵ��Hz��
//                //--------------------------------------------------------------
//                COUNTING: begin
//                    // �Թ���������м���
                    
//                    measuring <= 1'b1;               // ���ֲ��������б�־
                    
//                    if (signal_pulse && counting_enable) begin
//                        pulse_counter_temp <= pulse_counter_temp + 1'b1;
//                    end
                    
//                    // ÿ��ʱ�����ڸ�����������
//                    pulse_counter <= pulse_counter_temp;
                    
//                    // ���բ�Ž�������һ�������ص�����
//                    if (gate_posedge) begin
                        
//                        if (signal_pulse && counting_enable) begin
//                            frequency <= pulse_counter_temp + 1'b1;
//                        end else begin
//                            frequency <= pulse_counter_temp;
//                        end
                        
//                        measuring <= 1'b0;           // ������������б�־
                        
//                        //frequency <= pulse_counter;  // ���Ƶ��ֵ��Hz��
//                        counting_enable <= 1'b0;     // ֹͣ����
//                        freq_valid <= 1'b1;          // ��λ������ɱ�־
//                        state <= DONE;               // �������״̬
//                    end
//                end
                
//                //--------------------------------------------------------------
//                // ״̬2��DONE - ���״̬
//                // ���ܣ����ֲ�����������freq_valid�źţ�Ȼ�󷵻ؿ���״̬
//                //       �ȴ���һ�β���
//                //--------------------------------------------------------------
//                DONE: begin
//                    //freq_valid <= 1'b0;              // ���������ɱ�־
//                    state <= IDLE;                   // ���ؿ���״̬
//                end
                
//                //--------------------------------------------------------------
//                // Ĭ��״̬�����ؿ���״̬
//                //--------------------------------------------------------------
//                default: begin
//                    state <= IDLE;
                    
//                    measuring <= 1'b0;
//                    freq_valid <= 1'b0;
                    
//                end
//            endcase
//        end
//    end
    
//endmodule



//`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////////////////
//// �ۺ�Ƶ�ʲ���ģ�� - �����������������ڲ�����
//// ������Χ��0 ~ 2MHz
//// �������� 1Hz
////////////////////////////////////////////////////////////////////////////////////
//module freq_meter(
//    // ʱ���븴λ
//    input wire clk_10m,           // 10MHz��ʱ��
//    input wire rst,               // ��λ�źţ��ߵ�ƽ��Ч��
    
//    // ADC�ӿ�
//    input wire [9:0] adc_data,    // ADC��������(AD_D9~AD_D0)
    
//    // բ��ʱ������
//    input wire gate_clk,          // բ��ʱ�ӣ�1Hz��
    
//    // Ƶ�ʲ���������
//    output reg [31:0] frequency,  // �����õ���Ƶ��ֵ����λ��Hz��
//    output reg freq_valid,        // Ƶ�ʲ�����ɱ�־
//    output wire clk_adc           // A/Dת����ʱ�����
//);

//    assign clk_adc = clk_10m;
    
//    parameter THRESHOLD_HIGH = 10'd550;  // ��������ֵ��Լ1.07V��
//    parameter THRESHOLD_LOW = 10'd474;   // �½�����ֵ��Լ0.93V��
//    parameter VALID_WIDTH = 16'd20000;   // ����չ��2ms
    
//    // ״̬��״̬����
//    localparam IDLE = 2'd0;        // ����״̬���ȴ�բ�ſ���
//    localparam COUNTING = 2'd1;    // ����״̬����բ��ʱ���ڼ�������
//    localparam DONE = 2'd2;        // ���״̬������������
    
//    reg [9:0] adc_data_d1;
//    reg signal_level;              // ��ǰ�źŵ�ƽ��0=�ͣ�1=�ߣ�
//    reg signal_level_d1;           // �ӳ�һ�����ڱ��ؼ��
//    wire rising_edge;              // �����ر�־
    
//    // բ��ʱ�ӱ��ؼ��
//    reg gate_clk_d1, gate_clk_d2;
//    wire gate_posedge, gate_negedge;
    
//    reg [31:0] pulse_counter;      // ���������
//    reg [1:0] state;               // ״̬��
//    reg counting_enable;           // ����ʹ��
    
//    // ����չ�����
//    reg [31:0] frequency_internal; // �ڲ�������
//    reg freq_valid_pulse;          // �ڲ�����������
//    reg [15:0] valid_counter;      // ����չ�������
//    reg data_locked;               // ����������־
    
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            adc_data_d1 <= 10'd512;
//            signal_level <= 1'b0;
//            signal_level_d1 <= 1'b0;
//        end else begin
//            adc_data_d1 <= adc_data;
//            signal_level_d1 <= signal_level;
            
//            // �ͻرȽϣ�����ʱ��Ҫ��������ֵ���½�ʱ��Ҫ���ڵ���ֵ
//            if (adc_data_d1 >= THRESHOLD_HIGH) begin
//                signal_level <= 1'b1;
//            end else if (adc_data_d1 <= THRESHOLD_LOW) begin
//                signal_level <= 1'b0;
//            end
//            // ��������ֵ֮�䱣��ԭ״̬
//        end
//    end
    
//    // ��������أ�ÿ���������ڲ���һ�����壩
//    assign rising_edge = signal_level && !signal_level_d1;
    
//    // բ��ʱ�ӱ��ؼ��
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            gate_clk_d1 <= 1'b0;
//            gate_clk_d2 <= 1'b0;
//        end else begin
//            gate_clk_d1 <= gate_clk;
//            gate_clk_d2 <= gate_clk_d1;
//        end
//    end
    
//    assign gate_posedge = gate_clk_d1 && !gate_clk_d2;
//    assign gate_negedge = !gate_clk_d1 && gate_clk_d2;
    
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            state <= IDLE;
//            pulse_counter <= 32'd0;
//            frequency_internal <= 32'd0;
//            freq_valid_pulse <= 1'b0;
//            counting_enable <= 1'b0;
//        end else begin
//            freq_valid_pulse <= 1'b0;  // Ĭ������
            
//            case (state)
//                // ����״̬���ȴ�բ��������
//                IDLE: begin
//                    if (gate_posedge && !data_locked) begin
//                        pulse_counter <= 32'd0;
//                        counting_enable <= 1'b1;
//                        state <= COUNTING;
//                    end
//                end
                
//                // ����״̬����բ�Ÿߵ�ƽ�ڼ�������ؼ���
//                COUNTING: begin
//                    if (rising_edge && counting_enable) begin
//                        pulse_counter <= pulse_counter + 1'b1;
//                    end
                    
//                    // ���բ���½��أ�1�������ɣ�
//                    if (gate_negedge) begin
//                        frequency_internal <= pulse_counter;
//                        freq_valid_pulse <= 1'b1;
//                        counting_enable <= 1'b0;
//                        state <= DONE;
//                    end
//                end
                
//                // ���״̬���ȴ����ݱ������󷵻ؿ���
//                DONE: begin
//                    if (!data_locked) begin
//                        state <= IDLE;
//                    end
//                end
                
//                default: begin
//                    state <= IDLE;
//                end
//            endcase
//        end
//    end
    
//    // ����չ���߼�����100ns������չ��2ms
//    always @(posedge clk_10m or posedge rst) begin
//        if (rst) begin
//            freq_valid <= 1'b0;
//            frequency <= 32'd0;
//            valid_counter <= 16'd0;
//            data_locked <= 1'b0;
//        end else begin
//            if (freq_valid_pulse) begin
//                // ��⵽�µĲ������������չ��
//                freq_valid <= 1'b1;
//                frequency <= frequency_internal;  // ��������
//                valid_counter <= VALID_WIDTH;
//                data_locked <= 1'b1;  // �������ݣ���ֹ�²���
//            end else if (valid_counter > 16'd0) begin
//                // ���� freq_valid �ߵ�ƽ
//                valid_counter <= valid_counter - 1'b1;
//                freq_valid <= 1'b1;
//                data_locked <= 1'b1;  // ��������״̬
//            end else begin
//                // չ�����
//                freq_valid <= 1'b0;
//                data_locked <= 1'b0;  // ��������������²���
//            end
//        end
//    end

//endmodule



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
    
    parameter THRESHOLD_HIGH = 10'd550;  // ��������ֵ��Լ1.07V��
    parameter THRESHOLD_LOW = 10'd474;   // �½�����ֵ��Լ0.93V��
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

