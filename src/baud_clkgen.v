module baud_clkgen #(parameter baud=9600, clk_value= 50000000)( input sys_clk,sys_rst_l,output reg uart_clk );
localparam  baudcount=(clk_value/(baud*16*2));
integer count =0;
always @(posedge sys_clk or negedge sys_rst_l)
begin
if(!sys_rst_l)
begin
uart_clk<=0;
count<=0;
end
else if(count == baudcount-1)
begin
uart_clk<=~uart_clk;
count<=0;
end
else
begin
count<=count+1;
end
end
endmodule

