`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: duty_cycle_meter
// Description: �����ź�ռ�ձȲ���ģ�飨�޸��� - �����ʱ�������⣩
// �޸����ݣ�
// 1. �� duty_valid �ź�չ��ȷ������ʱ�����ܹ�����
// 2. �������������ƣ����������ڴ�������б仯
//////////////////////////////////////////////////////////////////////////////////

module duty_cycle_meter(
    input wire clk_10m,           // 10MHzʱ��
    input wire rst,               // ��λ�źţ��ߵ�ƽ��Ч��
    input wire [9:0] adc_data,    // ADC��������(0~1023��Ӧ0~2V)
    output reg [15:0] duty_cycle, // ռ�ձ�ֵ(��λ: 0.01%, ��Χ2000~8000��ʾ20.00%~80.00%)
    output reg duty_valid         // ռ�ձȲ�����ɱ�־��չ�����źţ�
);

    // ADC��ֵ���ã��ͻرȽ�����
    parameter THRESHOLD_HIGH = 10'd520; //10'd550;  // Լ1.07V����������ֵ��
    parameter THRESHOLD_LOW  = 10'd504; //10'd474;  // Լ0.93V���½�����ֵ��
    
    // ״̬��״̬����
    localparam IDLE         = 3'd0;  // ����״̬
    localparam WAIT_LOW     = 3'd1;  // �ȴ��͵�ƽ
    localparam WAIT_RISING  = 3'd2;  // �ȴ�������
    localparam COUNT_HIGH   = 3'd3;  // �����ߵ�ƽʱ��
    localparam COUNT_LOW    = 3'd4;  // �����͵�ƽʱ��
    localparam CALCULATE    = 3'd5;  // ����ռ�ձ�
    localparam DATA_LOCKED  = 3'd6;  //  ��������������״̬���ȴ�չ�����
    
    reg [2:0] state;
    
    reg [31:0] high_counter;   // �ߵ�ƽʱ�������
    reg [31:0] period_counter; // ���ڼ�����
    
    //  ����ڲ��ź���������չ��
    reg [15:0] duty_cycle_internal;  // �ڲ�������
    reg duty_valid_pulse;             // �ڲ�����������
    reg [15:0] valid_counter;         // ����չ�������
    parameter VALID_WIDTH = 16'd20000; // չ��2ms��20000��10MHzʱ�����ڣ�
    
     //  �������������־
    reg data_locked;  // ��Ϊ1ʱ����ֹ���� duty_cycle �� duty_valid
    
    reg [9:0] adc_d1;
    
    wire is_high, is_low;
    assign is_high = (adc_d1 >= THRESHOLD_HIGH);
    assign is_low  = (adc_d1 <= THRESHOLD_LOW);
    
    reg prev_is_high;
    wire rising_edge, falling_edge;
    
    // ADC���ݲ����ͱ��ؼ��
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
    parameter TIMEOUT_MAX = 28'd10_000_000; // 1�볬ʱ��10MHzʱ�ӣ�
    
    // ռ�ձȲ���״̬��
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            high_counter <= 32'd0;
            period_counter <= 32'd0;
            duty_cycle_internal <= 16'd0;
            duty_valid_pulse <= 1'b0;
            timeout_counter <= 28'd0;
            
            //data_locked <= 1'b0; //  ��ʼ������������־
             
        end else begin
            duty_valid_pulse <= 1'b0;  // Ĭ������
            
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
                        // ռ�ձ� = (�ߵ�ƽʱ�� / ����) �� 10000
                        duty_cycle_internal <= (high_counter * 64'd10000) / period_counter;
                        duty_valid_pulse <= 1'b1;  //  ��������������
                    end else begin
                        duty_cycle_internal <= 16'd0;
                    end
                    
                    //state <= IDLE;
                    state <= DATA_LOCKED;
                end
                
                //  ����״̬���ȴ�����չ�����
                DATA_LOCKED: begin
                    // �ȴ� data_locked ��־�������������չ���߼����ƣ�
                    if (!data_locked) begin
                        state <= IDLE;  // �����ѱ����������Կ�ʼ�²���
                    end
                    // ���򱣳��ڴ�״̬����ֹ�²�����ʼ
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    //  ����չ���߼�����100ns������չ��2ms
    always @(posedge clk_10m or posedge rst) begin
        if (rst) begin
            duty_valid <= 1'b0;
            duty_cycle <= 16'd0;
            valid_counter <= 16'd0;
            data_locked <= 1'b0;
        end else begin
            if (duty_valid_pulse) begin
                // ��⵽�µĲ������������չ��
                duty_valid <= 1'b1;
                duty_cycle <= duty_cycle_internal;  // ��������
                valid_counter <= VALID_WIDTH;
                data_locked <= 1'b1;  //  �������ݣ���ֹ�²�������
            end else if (valid_counter > 16'd0) begin
                // ���� duty_valid �ߵ�ƽ
                valid_counter <= valid_counter - 1'b1;
                duty_valid <= 1'b1;
                data_locked <= 1'b1;  //  ��������״̬
            end else begin
                // չ�����
                duty_valid <= 1'b0;
                data_locked <= 1'b0;  //  ��������������²���
            end
        end
    end

endmodule
