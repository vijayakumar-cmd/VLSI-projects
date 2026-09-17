module rv32i_core (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    output logic        dmem_valid,
    output logic        dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_wstrb,
    input  logic [31:0] dmem_rdata,
    output logic        halted
);
    localparam logic [6:0] OP_OP=7'b0110011, OP_IMM=7'b0010011, OP_LOAD=7'b0000011;
    localparam logic [6:0] OP_STORE=7'b0100011, OP_BRANCH=7'b1100011, OP_JAL=7'b1101111;
    localparam logic [6:0] OP_JALR=7'b1100111, OP_LUI=7'b0110111, OP_AUIPC=7'b0010111;
    localparam logic [6:0] OP_SYSTEM=7'b1110011;

    logic [31:0] regs [0:31];
    logic [31:0] pc;
    logic [31:0] ifid_pc, ifid_insn;
    logic ifid_valid;
    logic [31:0] idex_pc, idex_rs1v, idex_rs2v, idex_imm;
    logic [4:0] idex_rs1, idex_rs2, idex_rd;
    logic [2:0] idex_funct3;
    logic [6:0] idex_opcode;
    logic [6:0] idex_funct7;
    logic idex_valid, idex_regwrite, idex_memread, idex_memwrite, idex_branch, idex_jal, idex_jalr, idex_alu_imm;
    logic [31:0] exmem_result, exmem_store_data, exmem_pc4;
    logic [4:0] exmem_rd;
    logic [3:0] exmem_wstrb;
    logic exmem_valid, exmem_regwrite, exmem_memread, exmem_memwrite;
    logic [31:0] memwb_value;
    logic [4:0] memwb_rd;
    logic memwb_valid, memwb_regwrite;

    logic [31:0] id_imm, id_rs1v, id_rs2v;
    logic [4:0] id_rs1, id_rs2, id_rd;
    logic [2:0] id_funct3;
    logic [6:0] id_opcode, id_funct7;
    logic id_regwrite, id_memread, id_memwrite, id_branch, id_jal, id_jalr, id_alu_imm;
    logic stall, ex_taken;
    logic [31:0] ex_target, ex_result, ex_store_data, ex_pc4;
    logic [31:0] fwd_rs1, fwd_rs2;
    logic [31:0] wb_value;
    integer i;

    assign imem_addr = pc;
    assign id_opcode = ifid_insn[6:0];
    assign id_rd = ifid_insn[11:7];
    assign id_funct3 = ifid_insn[14:12];
    assign id_rs1 = ifid_insn[19:15];
    assign id_rs2 = ifid_insn[24:20];
    assign id_funct7 = ifid_insn[31:25];
    assign id_rs1v = (id_rs1 == 0) ? 32'b0 : regs[id_rs1];
    assign id_rs2v = (id_rs2 == 0) ? 32'b0 : regs[id_rs2];
    assign wb_value = memwb_value;

    always_comb begin
        id_imm = 32'b0;
        case (id_opcode)
            OP_IMM, OP_LOAD, OP_JALR: id_imm = {{20{ifid_insn[31]}}, ifid_insn[31:20]};
            OP_STORE: id_imm = {{20{ifid_insn[31]}}, ifid_insn[31:25], ifid_insn[11:7]};
            OP_BRANCH: id_imm = {{19{ifid_insn[31]}}, ifid_insn[31], ifid_insn[7], ifid_insn[30:25], ifid_insn[11:8], 1'b0};
            OP_LUI, OP_AUIPC: id_imm = {ifid_insn[31:12], 12'b0};
            OP_JAL: id_imm = {{11{ifid_insn[31]}}, ifid_insn[31], ifid_insn[19:12], ifid_insn[20], ifid_insn[30:21], 1'b0};
            default: id_imm = 32'b0;
        endcase
    end

    always_comb begin
        id_regwrite = 0; id_memread = 0; id_memwrite = 0; id_branch = 0; id_jal = 0; id_jalr = 0; id_alu_imm = 0;
        case (id_opcode)
            OP_OP, OP_LUI, OP_AUIPC: id_regwrite = 1;
            OP_IMM: begin id_regwrite = 1; id_alu_imm = 1; end
            OP_LOAD: begin id_regwrite = 1; id_memread = 1; id_alu_imm = 1; end
            OP_STORE: begin id_memwrite = 1; id_alu_imm = 1; end
            OP_BRANCH: id_branch = 1;
            OP_JAL: begin id_regwrite = 1; id_jal = 1; end
            OP_JALR: begin id_regwrite = 1; id_jalr = 1; id_alu_imm = 1; end
            default: begin end
        endcase
    end

    assign stall = idex_valid && idex_memread && (idex_rd != 0) && ((idex_rd == id_rs1) || (idex_rd == id_rs2)) &&
                   ((id_opcode == OP_OP) || (id_opcode == OP_IMM) || (id_opcode == OP_LOAD) || (id_opcode == OP_STORE) || (id_opcode == OP_BRANCH) || (id_opcode == OP_JALR));

    always_comb begin
        fwd_rs1 = idex_rs1v;
        fwd_rs2 = idex_rs2v;
        if (exmem_valid && exmem_regwrite && !exmem_memread && exmem_rd != 0 && exmem_rd == idex_rs1) fwd_rs1 = exmem_result;
        else if (memwb_valid && memwb_regwrite && memwb_rd != 0 && memwb_rd == idex_rs1) fwd_rs1 = wb_value;
        if (exmem_valid && exmem_regwrite && !exmem_memread && exmem_rd != 0 && exmem_rd == idex_rs2) fwd_rs2 = exmem_result;
        else if (memwb_valid && memwb_regwrite && memwb_rd != 0 && memwb_rd == idex_rs2) fwd_rs2 = wb_value;
    end

    always_comb begin
        ex_pc4 = idex_pc + 32'd4;
        ex_store_data = fwd_rs2;
        ex_target = idex_pc + idex_imm;
        if (idex_jalr) ex_target = (fwd_rs1 + idex_imm) & 32'hffff_fffe;
        ex_taken = idex_jal || idex_jalr;
        if (idex_branch) begin
            case (idex_funct3)
                3'b000: ex_taken = (fwd_rs1 == fwd_rs2);
                3'b001: ex_taken = (fwd_rs1 != fwd_rs2);
                3'b100: ex_taken = ($signed(fwd_rs1) < $signed(fwd_rs2));
                3'b101: ex_taken = ($signed(fwd_rs1) >= $signed(fwd_rs2));
                3'b110: ex_taken = (fwd_rs1 < fwd_rs2);
                3'b111: ex_taken = (fwd_rs1 >= fwd_rs2);
                default: ex_taken = 1'b0;
            endcase
        end
        ex_result = idex_alu_imm ? idex_imm : fwd_rs2;
        if (idex_opcode == OP_OP) begin
            case ({idex_funct7[5], idex_funct3})
                4'b0000: ex_result = fwd_rs1 + fwd_rs2;
                4'b1000: ex_result = fwd_rs1 - fwd_rs2;
                4'b0111: ex_result = fwd_rs1 & fwd_rs2;
                4'b0110: ex_result = fwd_rs1 | fwd_rs2;
                4'b0100: ex_result = fwd_rs1 ^ fwd_rs2;
                4'b0001: ex_result = fwd_rs1 << fwd_rs2[4:0];
                4'b0101: ex_result = fwd_rs1 >> fwd_rs2[4:0];
                4'b1101: ex_result = $signed(fwd_rs1) >>> fwd_rs2[4:0];
                4'b0010: ex_result = ($signed(fwd_rs1) < $signed(fwd_rs2));
                4'b0011: ex_result = (fwd_rs1 < fwd_rs2);
                default: ex_result = 32'b0;
            endcase
        end else if (idex_opcode == OP_IMM) begin
            case (idex_funct3)
                3'b000: ex_result = fwd_rs1 + idex_imm;
                3'b111: ex_result = fwd_rs1 & idex_imm;
                3'b110: ex_result = fwd_rs1 | idex_imm;
                3'b100: ex_result = fwd_rs1 ^ idex_imm;
                3'b001: ex_result = fwd_rs1 << idex_imm[4:0];
                3'b101: ex_result = idex_funct7[5] ? ($signed(fwd_rs1) >>> idex_imm[4:0]) : (fwd_rs1 >> idex_imm[4:0]);
                3'b010: ex_result = ($signed(fwd_rs1) < $signed(idex_imm));
                3'b011: ex_result = (fwd_rs1 < idex_imm);
                default: ex_result = 32'b0;
            endcase
        end else if (idex_opcode == OP_LUI) ex_result = idex_imm;
        else if (idex_opcode == OP_AUIPC) ex_result = idex_pc + idex_imm;
        else if (idex_jal || idex_jalr) ex_result = ex_pc4;
        else if (idex_memread || idex_memwrite) ex_result = fwd_rs1 + idex_imm;
    end

    assign dmem_valid = exmem_valid && (exmem_memread || exmem_memwrite);
    assign dmem_we = exmem_valid && exmem_memwrite;
    assign dmem_addr = exmem_result;
    assign dmem_wdata = exmem_store_data;
    assign dmem_wstrb = exmem_memwrite ? 4'b1111 : 4'b0000;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 0; ifid_valid <= 0; idex_valid <= 0; exmem_valid <= 0; memwb_valid <= 0; halted <= 0;
            for (i=0; i<32; i=i+1) regs[i] <= 0;
        end else begin
            regs[0] <= 0;
            if (memwb_valid && memwb_regwrite && memwb_rd != 0) regs[memwb_rd] <= memwb_value;
            memwb_valid <= exmem_valid; memwb_regwrite <= exmem_regwrite; memwb_rd <= exmem_rd;
            memwb_value <= exmem_memread ? dmem_rdata : exmem_result;
            exmem_valid <= idex_valid; exmem_regwrite <= idex_regwrite; exmem_memread <= idex_memread; exmem_memwrite <= idex_memwrite;
            exmem_rd <= idex_rd; exmem_result <= ex_result; exmem_store_data <= ex_store_data; exmem_pc4 <= ex_pc4;
            if (ex_taken && idex_valid) begin
                pc <= ex_target; ifid_valid <= 0; idex_valid <= 0;
            end else if (stall) begin
                pc <= pc; ifid_valid <= ifid_valid; idex_valid <= 0;
            end else begin
                pc <= pc + 32'd4; ifid_pc <= pc; ifid_insn <= imem_rdata; ifid_valid <= 1;
                idex_valid <= ifid_valid; idex_pc <= ifid_pc; idex_rs1v <= id_rs1v; idex_rs2v <= id_rs2v; idex_imm <= id_imm;
                idex_rs1 <= id_rs1; idex_rs2 <= id_rs2; idex_rd <= id_rd; idex_funct3 <= id_funct3; idex_opcode <= id_opcode; idex_funct7 <= id_funct7;
                idex_regwrite <= id_regwrite; idex_memread <= id_memread; idex_memwrite <= id_memwrite; idex_branch <= id_branch; idex_jal <= id_jal; idex_jalr <= id_jalr; idex_alu_imm <= id_alu_imm;
            end
            if (ifid_valid && ifid_insn == 32'b0) halted <= 1;
        end
    end
endmodule
