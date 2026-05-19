module transmitter #(
    parameter baud = 9600,
    parameter data_width = 8,
    parameter sys_clk = 5000000
)
(
    input clk,
    input rst,
    input xmitH,
    input [data_width-1:0] xmit_dataH,
    input baud_clk,

    output reg uart_XMIT_dataH,
    output reg xmit_doneH,
    output reg xmit_active
);

localparam idle  = 2'd0;
localparam start = 2'd1;
localparam data  = 2'd2;
localparam stop  = 2'd3;




reg [1:0] c_st, n_st;

reg [$clog2(data_width)-1:0] bit_count;

reg [data_width-1:0] temp;

reg [3:0] samp_count;




always @(posedge baud_clk or negedge rst)
begin
    if(!rst)
        c_st <= idle;
    else
        c_st <= n_st;  
end

always @(*)
begin

    case(c_st)

        idle:
        begin
            if(xmitH)
                n_st = start;
            else
                n_st = idle;
        end
        start:
        begin
            if(samp_count == 15)
                n_st = data;
            else
                n_st = start;
        end
        data:
        begin
            if((samp_count == 15) && (bit_count == data_width-1))
                n_st = stop;
            else
                n_st = data;
        end
        stop:
        begin
            if(samp_count == 15)
                n_st = idle;
            else
                n_st = stop;
        end

        default:
            n_st = idle;

    endcase
end
always @(posedge baud_clk or negedge rst)
begin

    if(!rst)
    begin
        uart_XMIT_dataH <= 1'b1;
        xmit_doneH      <= 1'b0;//1
        xmit_active     <= 1'b0;
        samp_count      <= 4'd0;
        bit_count       <= 0;
        temp            <= 0;
    end
    else
    begin


        case(c_st)
        idle:
        begin
            uart_XMIT_dataH <= 1'b1;

           
            xmit_active <= 1'b0;

            samp_count <= 0;
            bit_count  <= 0;

            if(xmitH)
            begin
                temp <= xmit_dataH;
                xmit_active <= 1'b1;
                 xmit_doneH  <= 1'b0;
            end
        end

        start:
        begin
            uart_XMIT_dataH <= 1'b0;
            xmit_active <= 1'b1;

            if(samp_count == 15)
                samp_count <= 0;
            else
                samp_count <= samp_count + 1;
        end
        data:
        begin

            uart_XMIT_dataH <= temp[0];
            xmit_active <= 1'b1;

            if(samp_count == 15)
            begin

                samp_count <= 0;

                temp <= temp >> 1;

                if(bit_count == data_width-1)
                    bit_count <= 0;
                else
                    bit_count <= bit_count + 1;

            end

            else
                samp_count <= samp_count + 1;

        end
        stop:
        begin

            uart_XMIT_dataH <= 1'b1;

            xmit_active <= 1'b1;

            if(samp_count == 15)
            begin
                samp_count <= 0;
                xmit_doneH <= 1'b1;
                xmit_active <= 1'b0;
            end
            else
                samp_count <= samp_count + 1;

        end

        default:
        begin
            uart_XMIT_dataH <= 1'b1;
        end

        endcase

    end

end

endmodule
