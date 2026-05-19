`include "baud_clkgen.v"
`include "reciever.v"
`include "transmitter.v"
module uart_top
#(
    parameter baud = 9600,
    parameter data_width = 8,
    parameter clk_freq =100000000
)
(
    output uart_XMIT_dataH,
    output xmit_doneH,
    output xmit_active,

    output rec_readyH,
    output rec_busy,
    output [data_width-1:0] rec_dataH,

    input xmitH,
    input sys_clk,
    input sys_rst_l,
    input uart_REC_dataH,

    input [data_width-1:0] xmit_dataH
);

wire baud_clk;

baud_clkgen #(
    .baud(baud),
    .clk_value(clk_freq)
)
baud_clkgen
(
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst_l),
    .uart_clk(baud_clk)
);

transmitter #(
    .baud(baud),
    .data_width(data_width)
)
t1
(
    .baud_clk(baud_clk),
    .rst(sys_rst_l),

    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),

    .uart_XMIT_dataH(uart_XMIT_dataH),
    .xmit_doneH(xmit_doneH),
    .xmit_active(xmit_active)
);

reciever #(
    .baud(baud),
    .data_width(data_width)
)
r1
(
    .baud_clk(baud_clk),
    .rst(sys_rst_l),

    .uart_REC_dataH(uart_REC_dataH),

    .rec_readyH(rec_readyH),
    .rec_busy(rec_busy),
    .rec_dataH(rec_dataH)
);

endmodule

