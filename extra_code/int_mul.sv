// 32 bit integer multiplication unit

module int_mul
import tricycle_pkg::*;
(
    input l32 op1, op2,
    input mul_op_t opsel,
    output l32 result
);

// Registers for 32 bit multiplier, 64 bit result
l64 mul_result;
l32 op1_neg;

always_comb begin 
    op1_neg = (~op1) + 1;

    case (opsel)
        MUL_OP_MULHSU: begin
            // High Signed x Unsigned
            if (op1[31]) begin
                mul_result = op1_neg * op2;
                mul_result = (~mul_result) + 1;
            end
            else begin 
                mul_result = op1 * op2;
            end
            result = mul_result[1];
        end

        MUL_OP_MULHU: begin
            // TODO Complete
        end

        MUL_OP_MULH: begin 
            // TODO Complete
        end

        MUL_OP_MUL: begin 
            // TODO Complete
        end
    endcase

end

endmodule
