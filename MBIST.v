
  `timescale 1ns / 1ps

module address_generator(
    input [2:0] estate,
    input clk,
    input start,
    output reg [2:0] addr,
    output reg [2:0] colum_bit,
    output reg [2:0] em
);
    reg dir;
    
    always @(posedge clk) begin
        if (start) begin 
            if (estate == 3'b001) begin
                addr <= 3'd0;
                colum_bit <= 3'd0;
                em <= 3'b000;
                dir <= 1'b0;
            end 
            else if (estate == 3'b010) begin
                if (addr == 3'b111 && colum_bit == 3'b111) begin
                    em <= 3'b001;
                end else begin
                    if (colum_bit == 3'b111) begin
                        addr <= addr + 1'b1;
                        colum_bit <= 3'b000;
                    end else begin
                        colum_bit <= colum_bit + 1'b1;
                    end
                end
            end 
            else if (estate == 3'b011) begin
                if (dir == 1'b0) begin
                    addr <= 3'b000;
                    colum_bit <= 3'b000;
                    dir <= 1'b1;
                end else begin
                    if (addr == 3'b111 && colum_bit == 3'b111) begin
                        em <= 3'b010;
                        dir <= 1'b0;
                    end else begin
                        if (colum_bit == 3'b111) begin
                            addr <= addr + 1'b1;
                            colum_bit <= 3'b000;
                        end else begin
                            colum_bit <= colum_bit + 1'b1;
                        end
                    end
                end
            end 
            else if (estate == 3'b100) begin
                if (dir == 1'b0) begin
                    addr <= 3'b000;
                    colum_bit <= 3'd0;
                    dir <= 1'b1;
                end else begin
                    if (addr == 3'b111 && colum_bit == 3'b111) begin
                        em <= 3'b011;
                        dir <= 1'b1;
                    end else begin
                        if (colum_bit == 3'b111) begin
                            addr <= addr + 1'b1;
                            colum_bit <= 3'b000;
                        end else begin
                            colum_bit <= colum_bit + 1'b1;
                        end
                    end
                end
            end 
            else if (estate == 3'b101) begin
                if (dir == 1'b1) begin
                    if (addr == 3'b000 && colum_bit == 3'b000) begin
                        em <= 3'b100;
                        dir <= 1'b0;
                    end else begin
                        if (colum_bit == 3'b000) begin
                            addr <= addr - 1'b1;
                            colum_bit <= 3'b111;
                        end else begin
                            colum_bit <= colum_bit - 1'b1;
                        end
                    end
                end
            end 
            else if (estate == 3'b110) begin
                if (dir == 1'b0) begin
                    addr <= 3'b111;
                    colum_bit <= 3'd7;
                    dir <= 1'b1;
                end else begin
                    if (addr == 3'b000 && colum_bit == 3'b000) begin
                        em <= 3'b101;
                        dir <= 1'b0;
                    end else begin
                        if (colum_bit == 3'b000) begin
                            addr <= addr - 1'b1;
                            colum_bit <= 3'b111;
                        end else begin
                            colum_bit <= colum_bit - 1'b1;
                        end
                    end
                end
            end 
            else if (estate == 3'b111) begin
                if (dir == 1'b0) begin
                    addr <= 3'b111;
                    colum_bit <= 3'd7;
                    dir <= 1'b1;
                end else begin
                    if (addr == 3'b000 && colum_bit == 3'b000) begin
                        em <= 3'b110;
                        dir <= 1'b0;
                    end else begin
                        if (colum_bit == 3'b000) begin
                            addr <= addr - 1'b1;
                            colum_bit <= 3'b111;
                        end else begin
                            colum_bit <= colum_bit - 1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule

module fsm_controller(
    input start,
    input clk,
    input [2:0] em,
    output reg [2:0] estate,
    output reg ebist
);
    reg [2:0] state;
    parameter idle = 3'b001, 
              write0 = 3'b010, 
              read0 = 3'b011, 
              write1 = 3'b100, 
              read1 = 3'b101, 
              write02 = 3'b110, 
              read02 = 3'b111, 
              finish = 3'b000;
    
    always @(posedge clk) begin
        if (start == 0) begin
            state <= idle;
        end else begin
            case (state)
                idle: if (em == 3'b000) state <= write0;
                write0: if (em == 3'b001) state <= read0;
                read0: if (em == 3'b010) state <= write1;
                write1: if (em == 3'b011) state <= read1;
                read1: if (em == 3'b100) state <= write02;
                write02: if (em == 3'b101) state <= read02;
                read02: if (em == 3'b110) state <= finish;
                finish: state <= finish;
                default: state <= finish;
            endcase
        end
    end
    
    always @(*) begin
        estate = finish;
        ebist = 1'b1;
        
        case (state)
            idle: begin
                estate = idle;
                ebist = 1'b0;
            end
            write0: begin
                estate = write0;
                ebist = 1'b0;
            end
            read0: begin
                estate = read0;
                ebist = 1'b0;
            end
            write1: begin
                estate = write1;
                ebist = 1'b0;
            end
            read1: begin
                estate = read1;
                ebist = 1'b0;
            end
            write02: begin
                estate = write02;
                ebist = 1'b0;
            end
            read02: begin
                estate = read02;
                ebist = 1'b0;
            end
            finish: begin
                estate = finish;
                ebist = 1'b1;
            end
        endcase
    end
endmodule

module read_write_controller(
    input [2:0] addr,
    input [2:0] colum_bits,
    input [2:0] estate,
    input start,
    output reg data_in,
    output reg wr_en,
    output reg rd_en,
    output reg [2:0] wr_addr,
    output reg [2:0] rd_addr,
    output reg [2:0] coloum_b
);
    always @(*) begin
        if (start) begin
            case (estate)
                3'b010: begin 
                    wr_addr = addr; 
                    rd_addr = 3'b000; 
                    coloum_b = colum_bits; 
                    rd_en = 1'b0; 
                    wr_en = 1'b1; 
                    data_in = 1'b0; 
                end
                3'b011: begin 
                    wr_addr = 3'b000; 
                    rd_addr = addr; 
                    coloum_b = colum_bits; 
                    rd_en = 1'b1; 
                    wr_en = 1'b0; 
                    data_in = 1'b0; 
                end
                3'b100: begin 
                    wr_addr = addr; 
                    rd_addr = 3'b000; 
                    coloum_b = colum_bits; 
                    rd_en = 1'b0; 
                    wr_en = 1'b1; 
                    data_in = 1'b1; 
                end
                3'b101: begin 
                    wr_addr = 3'b000; 
                    rd_addr = addr; 
                    coloum_b = colum_bits; 
                    rd_en = 1'b1; 
                    wr_en = 1'b0; 
                    data_in = 1'b1; 
                end
                3'b110: begin 
                    wr_addr = addr; 
                    rd_addr = 3'b000; 
                    coloum_b = colum_bits; 
                    rd_en = 1'b0; 
                    wr_en = 1'b1; 
                    data_in = 1'b0; 
                end
                3'b111: begin 
                    wr_addr = 3'b000; 
                    rd_addr = addr; 
                    coloum_b = colum_bits; 
                    rd_en = 1'b1; 
                    wr_en = 1'b0; 
                    data_in = 1'b0; 
                end
                default: begin 
                    wr_addr = 3'b000; 
                    rd_addr = 3'b000; 
                    coloum_b = 3'b000; 
                    rd_en = 1'b0; 
                    wr_en = 1'b0; 
                    data_in = 1'b0; 
                end
            endcase
        end
        else begin
            wr_addr = 3'b000; 
            rd_addr = 3'b000; 
            coloum_b = 3'b000; 
            rd_en = 1'b0; 
            wr_en = 1'b0; 
            data_in = 1'b0;
        end
    end
endmodule

//Here memory module is created and faults like 
//stuck-at-fault(0 & 1 both) are injected at some particular location
//transition-fault(0 - > 1 & 1 -> 0 both) are injected at some particular location
//inverse-copling-fault is  injected at some particular location

module memory_module(
    input we,
    input re,
    input clk,
    input reset,
    input [1:0] fault,
    input [2:0] wr_addr,
    input [2:0] rd_addr,
    input data_in,
    output reg data_out,
    input [2:0] fault_bit
);
    integer i;
    reg [7:0] memory[0:7];
 
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i <= 7; i = i + 1) begin
                memory[i] <= 8'b0;
            end
        end
        else begin
            // Write operation with fault injection
            if (we) begin
                case (fault) 
                    2'b00: begin // Stuck-at Fault
                        // Apply stuck-at fault to the exact location being written
                        if (wr_addr == 3'd1 && fault_bit == 3'd2) begin
                            memory[wr_addr][fault_bit] <= 1'b0; // Force stuck-at 0
                        end
                        else if (wr_addr == 3'd4 && fault_bit == 3'd5) begin
                            memory[wr_addr][fault_bit] <= 1'b1; // Force stuck-at 1
                        end
                        else begin
                            memory[wr_addr][fault_bit] <= data_in;
                        end
                    end
                    2'b01: begin // Transition Fault
                        if (wr_addr == 3'd5 && fault_bit == 3'd3)
                            memory[5][3] <= memory[5][3] & data_in; // AND with new data
                        else if (wr_addr == 3'd6 && fault_bit == 3'd5)
                            memory[6][5] <= memory[6][5] | data_in; // OR with new data
                        else
                            memory[wr_addr][fault_bit] <= data_in;
                    end
                    2'b10: begin // Inverse Coupling Fault
                        if (wr_addr == 3'd2 && fault_bit == 3'd3) begin
                            memory[2][2] <= memory[2][2] ^ (~memory[2][4] & data_in);
                            memory[2][3] <= data_in;
                        end else begin
                            memory[wr_addr][fault_bit] <= data_in;
                        end
                    end
//just check for other cell location
//            2'b10: begin // Inverse Coupling Fault
//                        if (wr_addr == 3'd3 && fault_bit == 3'd4) begin
//                            memory[3][3] <= memory[3][3] ^ (~memory[3][4] & data_in);
//                            memory[3][4] <= data_in;
//                        end else begin
//                            memory[wr_addr][fault_bit] <= data_in;
//                        end
//                    end
                    2'b11: begin // Normal Operation
                        memory[wr_addr][fault_bit] <= data_in;
                    end
                endcase
            end
        end
    end
    
    // Combinational read with fault injection during read
    always @(*) begin
        if (reset) begin
            data_out = 1'b0;
        end else if (re) begin
 
                    data_out = memory[rd_addr][fault_bit];
  
        end else begin
            data_out = 1'b0;
        end
    end
endmodule

 
module comparator (
    input clk,
    input start,
    input [2:0] addr,
    input [2:0] colum_bit,
    input data_out,
    input [2:0] estate,
    input rd_en,   
    output reg error,
    output reg [2:0] fault_addr,
    output reg [2:0] fault_bit
);
    parameter zero = 1'b0, one = 1'b1;
    
    // Combinational logic for immediate error detection
    always @(*) begin
        error = 1'b0;
        fault_addr = 3'd0;
        fault_bit = 3'b000; 
        if (start && rd_en) begin
            case (estate)
                3'b011: begin  
                    if (data_out != zero) begin
                        error = 1'b1;
                        fault_addr = addr;
                        fault_bit = colum_bit;
                    end
                end
                3'b101: begin  
                    if (data_out != one) begin
                        error = 1'b1;
                        fault_addr = addr;
                        fault_bit = colum_bit;
                    end
                end
                3'b111: begin   
                    if (data_out != zero) begin
                        error = 1'b1;
                        fault_addr = addr;
                        fault_bit = colum_bit;
                    end
                end
                default: begin
                  error = 0;
                end
            endcase
        end
    end
endmodule

module top_mbist(
    input clk,
    input reset,
    input start,
    input [1:0] fault,
    output [2:0] addr,
    output [2:0] colum_bit,
    output [2:0] estate,
    output ebist,
    output [2:0] em_signal_out,
    output [2:0] wr_addr,
    output [2:0] rd_addr,
    output [2:0] coloum_b,
    output wr_en,
    output rd_en,
    output top_data_out,
    output top_error,
    output [2:0] top_fault_addr,
    output [2:0] top_fault_bit
);
    wire [2:0] fsm_estate;
    wire [2:0] em_signal;
    wire [2:0] addr_signal;
    wire [2:0] colum_bit_signal;
    wire data_in;

 
    always @(posedge clk) begin
        if (rd_en) begin
            $display("Time=%t: READ_REQ Addr=%d Bit=%d Data=%b Error=%b", 
                     $time, addr_signal, colum_bit_signal, top_data_out, top_error);
        end
    end

    fsm_controller fsm_inst (
        .start(start),
        .em(em_signal),
        .clk(clk),
        .estate(fsm_estate),
        .ebist(ebist)
    );

    address_generator addr_gen_inst (
        .estate(fsm_estate),
        .clk(clk),
        .start(start),
        .addr(addr_signal),
        .colum_bit(colum_bit_signal),
        .em(em_signal)
    );

    read_write_controller rw_ctrl_inst (
        .addr(addr_signal),
        .colum_bits(colum_bit_signal),
        .estate(fsm_estate),
        .start(start),
        .data_in(data_in),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .coloum_b(coloum_b)
    );

    mbist memory_inst (
        .we(wr_en),
        .re(rd_en),
        .clk(clk),
        .reset(reset),
        .fault(fault),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .data_in(data_in),
        .data_out(top_data_out),
        .fault_bit(coloum_b)
    );

    comparator comparator_inst (
        .clk(clk),
        .start(start),
        .addr(addr_signal),
        .colum_bit(colum_bit_signal),
        .data_out(top_data_out),
        .estate(fsm_estate),
         .rd_en(rd_en),  
        .error(top_error),
        .fault_addr(top_fault_addr),
        .fault_bit(top_fault_bit)
    );

    assign addr = addr_signal;
    assign colum_bit = colum_bit_signal;
    assign estate = fsm_estate;
    assign em_signal_out = em_signal;
endmodule

