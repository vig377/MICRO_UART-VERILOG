module reciever #(parameter baud =9600,parameter data_width =8,parameter sys_clk=5000000)(input clk,rst,baud_clk,uart_REC_dataH,output reg rec_readyH,rec_busy,output reg[data_width-1:0]rec_dataH);
 localparam idle=0;
 localparam start=1;
 localparam data=2;
 localparam stop=3;
 reg[1:0]c_st,n_st;
 reg[$clog2(data_width)-1:0]bit_count;
 reg [3:0]samp_count;
 reg [(data_width)-1:0]temp;
 reg F1,F2;

always @(posedge baud_clk or negedge rst)
begin
if(!rst)
begin
F1<=1'b1;
F2<=1'b1;
end
else
begin
F1<=uart_REC_dataH;
F2<=F1;
end
end
always@(posedge baud_clk or negedge rst)
begin
if(!rst)
c_st<=idle;
else
c_st<=n_st;
end
always@(*)
begin
case(c_st)
idle:begin
    if(F2==1'b0)
        n_st=start;
    else
        n_st=idle;
    end
start:begin
        if(samp_count==4'd5)
            begin
                if(F2==1'b0)
                    n_st=data;
                else
                    n_st=idle;
            end
        else
            n_st=start;
       end
data:begin
        if(samp_count==4'd15 && (bit_count==data_width-1))
            n_st=stop;
        else
            n_st=data;
     end
stop:begin
        if(samp_count==4'd15)
            n_st=idle;
        else
            n_st=stop;
     end
default:n_st=idle;
endcase
end
always@(posedge baud_clk or negedge rst)
begin
if(!rst)
begin
rec_dataH<=0;
rec_readyH<=1'b1;
rec_busy<=0;
temp<=0;
bit_count<=0;
samp_count<=0;
end
else
begin
case(c_st)
idle:begin
        rec_busy<=0;
        samp_count<=0;
        bit_count<=0;
        rec_readyH<=1'b1;
        if(F2==0)
            rec_busy<=1;
        end
start:begin
        rec_busy<=1;
            if(samp_count==4'd5)
                samp_count<=0;
            else
                samp_count<=samp_count+1;
      end
data:begin
        rec_busy<=1;
        if(samp_count==4'd15)
            begin
                samp_count<=0;
                temp[bit_count]<=F2;
                if(bit_count==data_width-1)
                    bit_count<=0;
                else
                    bit_count<=bit_count+1;
                end
         else
         samp_count<=samp_count+1;
      end
stop:begin
        rec_busy<=1;
            if(samp_count==4'd15)
                begin
                    samp_count<=0;
                    rec_readyH <= 1'b1;
                     if(F2==1)
                        begin
                            rec_dataH<=temp;
                            rec_readyH<=1'b1;
                        end
                        else
                        rec_dataH<={data_width{1'b0}};
                     rec_busy<=0;
                 end
             else
             samp_count<=samp_count+1;
         end
default:rec_busy<=0;
endcase
end
end
endmodule
