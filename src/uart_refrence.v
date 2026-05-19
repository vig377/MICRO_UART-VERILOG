module uart_refrence #(parameter clk_value= 100000000,parameter baud=9600,parameter data_width=8)(input wire sys_clk,sys_rst_l,xmitH,input wire [data_width-1:0]xmit_dataH,input wire uart_REC_dataH,output reg uart_XMIT_dataH,xmit_doneH,xmit_active,rec_readyH,rec_busyH,output reg [data_width-1:0]rec_dataH,output wire uart_clk_out);
localparam BAUD_DIV=(clk_value/(baud*16*2));
reg uart_clk;
reg [$clog2(BAUD_DIV):0]clk_cnt;
assign uart_clk_out=uart_clk;
//baud_clk generation
always@(posedge sys_clk or negedge sys_rst_l)
begin
if(!sys_rst_l)
begin
uart_clk<=1'b0;
clk_cnt<=0;
end
else
begin
if(clk_cnt==BAUD_DIV)
begin
uart_clk<=~uart_clk;
clk_cnt<=0;
end
else
clk_cnt<=clk_cnt+1'b1;
end
end
//transmitter
integer tx;
reg [data_width-1:0]tx_data;
initial begin
uart_XMIT_dataH=1'b1;
xmit_doneH=1'b0;
xmit_active=1'b0;
end
always@(posedge xmitH)
begin
tx_data=xmit_dataH;
xmit_active=1'b1;
xmit_doneH=1'b0;
uart_XMIT_dataH=1'b0;//start bit
repeat(16)@(posedge uart_clk);
//data
for(tx=0;tx<=data_width-1;tx=tx+1)
begin
uart_XMIT_dataH=tx_data[0];
tx_data=tx_data>>1;
repeat(16)@(posedge uart_clk);
end
//stopbit
uart_XMIT_dataH=1'b1;
repeat(16)@(posedge uart_clk);
xmit_active=1'b0;
xmit_doneH=1'b1;
end
//synchronzer
reg f1,f2;
always@(posedge uart_clk or negedge sys_rst_l)
begin
if(!sys_rst_l)
begin
f1<=1'b1;
f2<=1'b1;
end
else
begin
f1<=uart_REC_dataH;
f2<=f1;
end
end
//reset
always@(negedge sys_rst_l)
begin
rec_readyH<=1'b1;
rec_busyH<=1'b0;
rec_dataH<={data_width{1'b0}};
end
//reciver
integer rx;
reg [data_width-1:0]rx_temp;
initial begin
rec_readyH=1'b1;
rec_busyH=1'b0;
rec_dataH={data_width{1'b0}};
rx_temp={data_width{1'b0}};
end
always@(posedge uart_clk)
begin
if(f2==1'b0)
begin
rec_busyH<=1'b1;
rec_readyH<=1'b0;
repeat (6)@(posedge uart_clk);
if(f2==1'b0)
begin
for(rx=0;rx<=data_width-1;rx=rx+1)
begin
repeat(16)@(posedge uart_clk);
rx_temp={f2,rx_temp[data_width-1:1]};
end
//stopbit
repeat(16)@(posedge uart_clk);
if(f2==1'b1)
begin
rec_dataH<=rx_temp;
rec_readyH<=1'b1;
rec_busyH<=1'b0;
end
else 
begin ///suppose framing error then reset your rec data
rec_dataH<={data_width{1'b0}};
rec_readyH<=1'b1;
rec_busyH<=1'b0;
end
end
else begin
rec_busyH<=1'b0;//return to idle
rec_readyH<=1'b1;
end
end
end
endmodule
