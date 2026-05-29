/* verilator lint_off UNUSEDSIGNAL */

module decoder
import tricycle_pkg::*;
(
    input rv_instr_t instr,
    output control_t control
);

logic is_srai;

always_comb begin
    // Logic for detecting SRAI instruction
    is_srai = 0;
    // Default signals NOP Setup add x0, x0, 0;
    control = create_nop_ctrl();

    unique case(instr.opcode)
        // Load upper imm
        // RD = U_IMM
        OPCODE_LUI: begin
            // TODO Complete
        end

        // Load upper imm+pc
        // ALU: PC + U_IMM
        // RD = ALU
        OPCODE_AUIPC: begin
            // TODO Complete
        end

        // Jump and link
        // ALU: PC + J_IMM
        // PC = ALU
        // RD = PC + (4 or 2)
        OPCODE_JAL: begin
            control.imm = IMM_J;
            control.branch_op = OP_J;
            control.int_alu_input = ALU_IN_PC_IMM;
            control.wb_result_src = WB_PC4;
            control.rf_write = 1;
        end

        // Jump and link using register
        // ALU: R1 + J_IMM
        // PC = ALU
        // RD = PC + (4 or 2)
        OPCODE_JALR: begin
            control.imm = IMM_I;
            control.branch_op = OP_J;
            control.int_alu_input = ALU_IN_R1_IMM;
            control.wb_result_src = WB_PC4;
            control.rf_write = 1;
        end

        // Branch instruction
        // ALU: PC + B_IMM
        // PC = ALU
        // B_UNIT: R1, R2
        OPCODE_BRANCH: begin
            control.imm = IMM_B;
            control.branch_op = branch_op_t'({1'b0, instr.funct3});
            control.int_alu_input = ALU_IN_PC_IMM;
        end

        // Integer Immediate arithmetic
        // ALU: R1, I_IMM
        // RD = ALU
        OPCODE_INTEGER_IMM: begin
            // SRAI instr is the only that sets alu_op to 1xxx
            if (instr.funct3 == 3'b101 && instr.funct7[5]) is_srai = 1;
            else is_srai = 0;
            control.imm = IMM_I;
            control.int_alu_op = int_alu_op_t'({is_srai, instr.funct3});
            control.int_alu_input = ALU_IN_R1_IMM;
            control.rf_write = 1;
        end

        // Integer register op register arithmetic
        // ALU: R1, R2
        // RD = ALU or MUL
        OPCODE_INTEGER_REG: begin
            // TODO Complete
        end

        // Store
        // ALU: R1 + S_IMM
        // MEM @ ALU <- R2
        OPCODE_STORE: begin
            control.imm = IMM_S;
            control.int_alu_input = ALU_IN_R1_IMM;
            control.mem_op = mem_op_t'({1'b1, instr.funct3});
            control.is_store = 1;
        end

        // Load
        // ALU: R1 + I_IMM
        // RD = MEM @ ALU
        OPCODE_LOAD: begin
            control.imm = IMM_I;
            control.int_alu_input = ALU_IN_R1_IMM;
            control.mem_op = mem_op_t'({1'b0, instr.funct3});
            control.wb_result_src = WB_LOAD;
            control.rf_write = 1;
        end

        default: begin
            // All unrecognized instructions behave as NOPs
        end
    endcase

    if (instr.rd == 0) control.rf_write = 0;
end


endmodule
