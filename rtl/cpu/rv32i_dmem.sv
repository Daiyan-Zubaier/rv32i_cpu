module rv32i_dmem #(
  parameter int unsigned Depth = 1024
) (
  input logic [31:0]  addr_i,
  input logic [31:0]  data_w_i,
  input logic [2:0]   funct3_i,
  input logic         mem_write_en_i,
  input logic         clk_i,

  output logic [31:0] data_r_o
);
  logic [31:0] memory [Depth];

  logic [$clog2(Depth)-1:0] word_addr;
  logic [31:0] read_word;
  logic unused_addr;

  assign word_addr = addr_i[$clog2(Depth)+1:2];
  assign unused_addr = ^addr_i[31:$clog2(Depth)+2];
  assign read_word = memory[word_addr];

  always_comb begin
    unique case (funct3_i)
      3'h0: begin // lb
        unique case (addr_i[1:0])
          2'b00: data_r_o = {{24{read_word[7]}}, read_word[7:0]};
          2'b01: data_r_o = {{24{read_word[15]}}, read_word[15:8]};
          2'b10: data_r_o = {{24{read_word[23]}}, read_word[23:16]};
          2'b11: data_r_o = {{24{read_word[31]}}, read_word[31:24]};
        endcase
      end

      3'h1: begin // lh
        if (addr_i[1] == 1'b0) begin
          data_r_o = {{16{read_word[15]}}, read_word[15:0]};
        end else begin
          data_r_o = {{16{read_word[31]}}, read_word[31:16]};
        end
      end

      3'h2: begin // lw
        data_r_o = read_word;
      end

      3'h4: begin // lbu
        unique case (addr_i[1:0])
          2'b00: data_r_o = {24'b0, read_word[7:0]};
          2'b01: data_r_o = {24'b0, read_word[15:8]};
          2'b10: data_r_o = {24'b0, read_word[23:16]};
          2'b11: data_r_o = {24'b0, read_word[31:24]};
        endcase
      end

      3'h5: begin // lhu
        if (addr_i[1] == 1'b0) begin
          data_r_o = {16'b0, read_word[15:0]};
        end else begin
          data_r_o = {16'b0, read_word[31:16]};
        end
      end

      default: begin
        data_r_o = 32'b0;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (mem_write_en_i) begin
      unique case (funct3_i)
        3'b000: begin // sb
          unique case (addr_i[1:0])
            2'b00: memory[word_addr][7:0]   <= data_w_i[7:0];
            2'b01: memory[word_addr][15:8]  <= data_w_i[7:0];
            2'b10: memory[word_addr][23:16] <= data_w_i[7:0];
            2'b11: memory[word_addr][31:24] <= data_w_i[7:0];
          endcase
        end

        3'b001: begin // sh
          if (addr_i[1] == 1'b0) begin
            memory[word_addr][15:0] <= data_w_i[15:0];
          end else begin
            memory[word_addr][31:16] <= data_w_i[15:0];
          end
        end

        3'b010: begin // sw
          memory[word_addr] <= data_w_i;
        end

        default: begin
          // Do nothing
        end
      endcase
    end
  end

endmodule : rv32i_dmem
