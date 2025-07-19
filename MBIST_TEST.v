
 `timescale 1ns / 1ps

module tb_top_mbist_single_fault();

 
    reg clk;
    reg reset;
    reg start;
    reg [1:0] fault;
    
 
    wire [2:0] addr;
    wire [2:0] colum_bit;
    wire [2:0] estate;
    wire ebist;
    wire [2:0] em_signal_out;
    wire [2:0] wr_addr;
    wire [2:0] rd_addr;
    wire [2:0] coloum_b;
    wire wr_en;
    wire rd_en;
    wire top_data_out;
    wire top_error;
    wire [2:0] top_fault_addr;
    wire [2:0] top_fault_bit;
    
    // Instantiate the MBIST system
    top_mbist uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .fault(fault),
        .addr(addr),
        .colum_bit(colum_bit),
        .estate(estate),
        .ebist(ebist),
        .em_signal_out(em_signal_out),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .coloum_b(coloum_b),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .top_data_out(top_data_out),
        .top_error(top_error),
        .top_fault_addr(top_fault_addr),
        .top_fault_bit(top_fault_bit)
    );
    
 
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
   
    
    
    initial begin
 
    reset = 1;
    start = 0;
    fault = 2'b01; //inject mode for fault
      //00 for stuck at fault
      //01 for transition fault
      //10 for inverse coupling fault
      //11 for normal operation
    #100;
    
   
    reset = 0;
    #50;
    
 
    start = 1;
    
  
    $monitor("Time: %t ns | State: %b | Addr: %d | Bit: %d | Data: %b | Error: %b",
            $time, estate, addr, coloum_b, top_data_out, top_error);
    
 
    wait(ebist == 1);
    #100;
    
    if (top_error) begin
        $display("TEST PASSED: Fault detected at address %d, bit %d", 
                top_fault_addr, top_fault_bit);
    end else begin
        $display("TEST FAILED: No fault detected");
    end
    
    #100;
    $finish;
end
    
 
 
   
    always @(posedge clk) begin
        if (wr_en) begin
            $display("WRITE: Addr=%d, Bit=%d, Data=%b (Time: %t ns)", 
                    wr_addr, coloum_b, uut.memory_inst.memory[wr_addr][coloum_b], $time);
        end
        if (rd_en) begin
            $display("READ: Addr=%d, Bit=%d, Data=%b (Time: %t ns)", 
                    rd_addr, coloum_b, top_data_out, $time);
        end
    end
    
  
    
endmodule
  
