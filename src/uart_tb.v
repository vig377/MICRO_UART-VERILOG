`timescale 1ns / 1ps

`include "uart_refrence.v"
`include "uart_top.v"

module uart_tb;
parameter data_width=8;


reg sys_clk;
reg sys_rst;

reg xmitH;
reg [data_width-1:0] xmit_dataH;

reg uart_rec_datah;

wire dut_xmit_doneH;
wire dut_xmit_active;
wire dut_uart_xmit_datah;
wire dut_rec_readyh;
wire dut_rec_busyh;
wire [data_width-1:0] dut_rec_datah;

wire ref_xmit_doneH;
wire ref_xmit_active;
wire ref_uart_xmit_datah;
wire ref_rec_readyh;
wire ref_rec_busyh;
wire [data_width-1:0] ref_rec_datah;

wire ref_uart_clk;



uart_top dut(
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst),

    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),

    .uart_REC_dataH(dut_uart_xmit_datah),

    .uart_XMIT_dataH(dut_uart_xmit_datah),
    .xmit_doneH(dut_xmit_doneH),
    .xmit_active(dut_xmit_active),

    .rec_readyH(dut_rec_readyh),
    .rec_busy(dut_rec_busyh),
    .rec_dataH(dut_rec_datah)
);



uart_refrence ref(
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst),

    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),

    .uart_REC_dataH(ref_uart_xmit_datah),

    .uart_XMIT_dataH(ref_uart_xmit_datah),
    .xmit_doneH(ref_xmit_doneH),
    .xmit_active(ref_xmit_active),

    .rec_readyH(ref_rec_readyh),
    .rec_busyH(ref_rec_busyh),
    .rec_dataH(ref_rec_datah),

    .uart_clk_out(ref_uart_clk)
);



integer pass_count;
integer fail_count;
integer test_count;



initial
begin
    sys_clk = 0;
    forever #5 sys_clk = ~sys_clk;
end



initial
begin
    $dumpfile("uart_tb.vcd");
    $dumpvars(0, uart_tb);
end



function compare_tx;
input dut_done;
input dut_active;
input dut_serial;

input ref_done;
input ref_active;
input ref_serial;

begin
    compare_tx =
        (dut_done   === ref_done)   &&
        (dut_active === ref_active) &&
        (dut_serial === ref_serial);
end
endfunction



function compare_rx;
input dut_ready;
input dut_busy;
input [data_width-1:0] dut_data;

input ref_ready;
input ref_busy;
input [data_width-1:0] ref_data;

begin
    compare_rx =
        (dut_ready === ref_ready) &&
        (dut_busy  === ref_busy)  &&
        (dut_data  === ref_data);
end
endfunction



task display_tx_mismatch;
begin
    $display("DUT TX : done=%b active=%b serial=%b",
              dut_xmit_doneH,
              dut_xmit_active,
              dut_uart_xmit_datah);

    $display("REF TX : done=%b active=%b serial=%b",
              ref_xmit_doneH,
              ref_xmit_active,
              ref_uart_xmit_datah);
end
endtask



task display_rx_mismatch;
begin
    $display("DUT RX : ready=%b busy=%b data=0x%02X",
              dut_rec_readyh,
              dut_rec_busyh,
              dut_rec_datah);

    $display("REF RX : ready=%b busy=%b data=0x%02X",
              ref_rec_readyh,
              ref_rec_busyh,
              ref_rec_datah);
end
endtask



task wait_tx_complete;
begin
    wait(dut_xmit_active == 0);
    wait(ref_xmit_active == 0);

    repeat(4) @(posedge ref_uart_clk);
end
endtask



task apply_test_tx;

input [data_width-1:0] data;
input [200:1] test_name;

begin

    wait(dut_xmit_active == 0);
    wait(ref_xmit_active == 0);

    @(posedge ref_uart_clk);

    xmit_dataH = data;
    xmitH = 1'b1;

    @(posedge ref_uart_clk);

    xmitH = 1'b0;

    wait_tx_complete;

    test_count = test_count + 1;

    if(compare_tx(
        dut_xmit_doneH,
        dut_xmit_active,
        dut_uart_xmit_datah,

        ref_xmit_doneH,
        ref_xmit_active,
        ref_uart_xmit_datah
    ))
    begin
        $display("[PASS] %s data=0x%02X", test_name, data);
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] %s data=0x%02X", test_name, data);

        display_tx_mismatch;

        fail_count = fail_count + 1;
    end

end
endtask



task send_frame;

input [data_width-1:0] data;

integer i;

reg [data_width-1:0] temp;

begin

    temp = data;

    uart_rec_datah = 1'b0;

    repeat(16) @(posedge ref_uart_clk);

    for(i=0;i<data_width;i=i+1)
    begin

        uart_rec_datah = temp[0];

        temp = temp >> 1;

        repeat(16) @(posedge ref_uart_clk);

    end

    uart_rec_datah = 1'b1;

    repeat(16) @(posedge ref_uart_clk);

end
endtask



task apply_test_rx;

input [data_width-1:0] data;
input [200:1] test_name;

begin

    send_frame(data);

    wait_rx_ready;

    repeat(4) @(posedge ref_uart_clk);

    test_count = test_count + 1;

    if(compare_rx(
        dut_rec_readyh,
        dut_rec_busyh,
        dut_rec_datah,

        ref_rec_readyh,
        ref_rec_busyh,
        ref_rec_datah
    ))
    begin
        $display("[PASS] %s data=0x%02X", test_name, data);

        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] %s data=0x%02X", test_name, data);

        display_rx_mismatch;

        fail_count = fail_count + 1;
    end

end
endtask



task test_transmitter;

begin

    apply_test_tx(8'hCD, "TX Normal ");
    apply_test_tx(8'h00, "TX All Zeros");
    apply_test_tx(8'hFF, "TX All Ones");
    apply_test_tx(8'h77, "TX Pattern 0x77");
    apply_test_tx(8'h10, "TX Pattern 0x10");



    test_count = test_count + 1;

    if(dut_uart_xmit_datah == 1'b1)
    begin
        $display("[PASS] TX Idle Line = 1");

        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] TX Idle Line != 1");

        fail_count = fail_count + 1;
    end



    xmitH = 0;

    xmit_dataH = 8'hDE;

    repeat(10) @(posedge ref_uart_clk);

    test_count = test_count + 1;

    if(dut_xmit_active == 0)
    begin
        $display("[PASS] xmitH=0 does not start TX");

        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] xmitH=0 started TX");

        fail_count = fail_count + 1;
    end



    wait(dut_xmit_active == 0);

    @(posedge ref_uart_clk);

    xmitH = 1;
    xmit_dataH = 8'hAA;

    @(posedge ref_uart_clk);

    xmitH = 0;

    repeat(50) @(posedge ref_uart_clk);

    xmit_dataH = 8'hFF;

    wait_tx_complete;

    test_count = test_count + 1;

    if(dut_uart_xmit_datah == ref_uart_xmit_datah)
    begin
        $display("[PASS] Mid TX data change ignored");

        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] Mid TX data change affected transfer");

        fail_count = fail_count + 1;
    end

end
endtask
task wait_rx_ready;

integer timeout;

begin

    timeout = 0;

    while(
        (dut_rec_readyh != 1'b1) ||
        (ref_rec_readyh != 1'b1)
    )
    begin

        @(posedge ref_uart_clk);

        timeout = timeout + 1;

        if(timeout > 5000)
        begin
            $display("ERROR : RX timeout");
            disable wait_rx_ready;
        end

    end

end
endtask


task test_receiver;

integer b;

reg [7:0] fdata;

begin

    apply_test_rx(8'hCD, "RX Normal 0xCD");
    apply_test_rx(8'h00, "RX All Zeros");
    apply_test_rx(8'hFF, "RX All Ones");
    apply_test_rx(8'hA5, "RX Pattern 0xA5");



    uart_rec_datah = 1'b1;

    repeat(20) @(posedge ref_uart_clk);

    test_count = test_count + 1;

    if(dut_rec_readyh == 1'b1 && dut_rec_busyh == 1'b0)
    begin
        $display("[PASS] RX Idle State");

        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] RX Idle State");

        fail_count = fail_count + 1;
    end



    fdata = 8'h55;

    uart_rec_datah = 1'b0;

    repeat(16) @(posedge ref_uart_clk);

    for(b=0;b<data_width;b=b+1)
    begin

        uart_rec_datah = fdata[0];

        fdata = fdata >> 1;

        repeat(16) @(posedge ref_uart_clk);

    end



    uart_rec_datah = 1'b0;

    repeat(16) @(posedge ref_uart_clk);

    uart_rec_datah = 1'b1;

    repeat(20) @(posedge ref_uart_clk);



    test_count = test_count + 1;

    if(dut_rec_datah == ref_rec_datah)
    begin
        $display("[PASS] Framing Error Test");

        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] Framing Error Test");

        fail_count = fail_count + 1;
    end

end
endtask



initial
begin

    pass_count = 0;
    fail_count = 0;
    test_count = 0;

    sys_rst = 0;

    xmitH = 0;

    xmit_dataH = 8'h00;

    uart_rec_datah = 1'b1;

    #200;

    sys_rst = 1;
#200;

    sys_rst = 0;
#200;

    sys_rst = 1;


    repeat(10) @(posedge ref_uart_clk);

    $display("--------------------------------");
    $display("UART TRANSMITTER TESTS");
    $display("--------------------------------");

    test_transmitter;



    $display("--------------------------------");
    $display("UART RECEIVER TESTS");
    $display("--------------------------------");

    uart_rec_datah = 1'b1;

    test_receiver;



    $display("--------------------------------");
    $display("TOTAL TESTS : %0d", test_count);
    $display("PASS        : %0d", pass_count);
    $display("FAIL        : %0d", fail_count);

    if(fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");

    $display("--------------------------------");

    #100;

    $finish;

end



initial
begin

    #50000000;

    $display("[WATCHDOG] Simulation Timeout");

    $finish;

end

endmodule
