module gcd #(parameter W=16)(
  
  input clk,reset,
  input data_rdy,
  input[W-1:0] operands_bits_A,operands_bits_B,
  input result_taken,
  output result_rdy,
  output[W-1:0] result_bits_data
);
  wire[W-1:0] A,B;
  wire clear,init,swap,subtract,set_done,done;
  gcd_controller ctrl(clk,reset,data_rdy,result_taken,A,B,done,clear,init,swap,subtract,set_done);
  datapath #(W) data(clk,operands_bits_A,operands_bits_B,clear,init,swap,subtract,set_done,A,B,done,result_rdy,result_bits_data);
endmodule

module gcd_controller #(parameter W=16)(
  input clk,reset,
  input data_rdy,
  input result_taken,
  
  input[W-1:0] A,B,
  input done,
  
  output reg clear, init, swap, subtract, set_done
);
  
  reg [1:0] state;
  
  parameter idle=2'b00;
  parameter compute=2'b01;
  parameter read_data=2'b10;
  
  always @(posedge clk)
    begin
      if(reset) state<=idle;
      else
        begin
          if(state==idle)
            begin
              state<=(data_rdy)?compute:idle;
            end
          else if(state==compute)
            begin
              if(done) state<=read_data;
              else
                begin
                  if(A<B) state<=compute;
                  else  state<=(B!=0)?compute:read_data;
                end
            end
          else
            begin
              state<=(result_taken)?idle:read_data;
            end
        end
    end
  always @(*)
    begin
      if(reset)
        begin
          clear=1;
          init=0;
          swap=0;
          subtract=0;
          set_done=0;
        end
      else
        begin
        case (state)
          idle:
            begin
              if(data_rdy) begin clear=0;init=1;swap=0;subtract=0;set_done=0;end
              else  begin clear=0; init=0; swap=0; subtract=0;set_done=0; end
            end
          compute:
            begin
              if (done) begin clear=0; init=0; swap=0; subtract=0;set_done=0; end
              else
                begin
                  if(A<B) begin clear=0; init=0; swap=1; subtract=0;set_done=0; end
                  else
                    begin
                      if(B!=0) begin clear=0; init=0; swap=0; subtract=1;set_done=0; end
                      else begin clear=0; init=0; swap=0; subtract=0;set_done=1; end
                    end
                end
            end
          read_data:
            begin
              if(result_taken) begin clear=1; init=0; swap=0; subtract=0;set_done=0; end
              else begin clear=0; init=0; swap=0; subtract=0;set_done=0; end
            end
          default: begin clear=0; init=0; swap=0; subtract=0;set_done=0; end
        endcase
        end
    end  
endmodule

module datapath #(parameter W=16)(
  input clk,
  input[W-1:0] operands_bits_A, operands_bits_B,
  input clear,init,swap,subtract,set_done,
  output reg [W-1:0] A,B,
  output reg done,
  output result_rdy,
  output[W-1:0] result_bits_data
); 
  always @(posedge clk)
    begin
      if(clear) begin A<=0; B<=0; done<=0; end
      else if(init) begin A<=operands_bits_A; B<=operands_bits_B; end
      else if (swap) begin A<=B; B<=A; end
      else if (subtract) begin A<=A-B; end
      else if (set_done) begin done<=1; end
    end
  assign result_rdy=done;
  assign result_bits_data=(done)?A:0;
endmodule






