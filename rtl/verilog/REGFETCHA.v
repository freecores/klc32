// ============================================================================
// (C) 2011 Robert Finch
// All Rights Reserved.
// robfinch<remove>@opencores.org
//
// KLC32 - 32 bit CPU
// REGFETCHA.v - fetch register A / execute some instructions
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
REGFETCHA:
	begin
		a <= rfo;
		b <= 32'd0;
		Rn <= ir[20:16];
		if (opcode==`RR || opcode==`RRR || opcode==`SW || opcode==`SH || opcode==`SB) begin
			state <= REGFETCHB;
		end
		else begin
			// RIX format ?
			if ((hasConst16 && ir[15:0]==16'h8000) || (isStop))
				state <= FETCH_IMM32;
			else begin
				imm <= {{16{ir[15]}},ir[15:0]};
				state <= EXECUTE;
			end
		end
		case(opcode)
		`MISC:
			case(func)
			`TRACE_ON:
					if (!sf) begin
						vector <= `PRIVILEGE_VIOLATION;
						state <= TRAP;
					end
					else begin
						tf <= 1'b1;
						state <= IFETCH;
					end
			`TRACE_OFF:
					if (!sf) begin
						vector <= `PRIVILEGE_VIOLATION;
						state <= TRAP;
					end
					else begin
						tf <= 1'b0;
						state <= IFETCH;
					end
			`SET_IM:
					if (!sf) begin
						vector <= `PRIVILEGE_VIOLATION;
						state <= TRAP;
					end
					else begin
						im <= ir[2:0];
						state <= IFETCH;
					end
			`USER_MODE: begin sf <= 1'b0; state <= IFETCH; end
			`JMP32:	state <= JMP32;
			`JSR32:	state <= JSR32;
			`RTS: state <= RTS;
			`RTI:
				if (!sf) begin
					vector <= `PRIVILEGE_VIOLATION;
					state <= TRAP;
				end
				else
					state <= RTI1;
			`RST:
				if (!sf) begin
					vector <= `PRIVILEGE_VIOLATION;
					state <= TRAP;
				end
				else begin
					rst_o <= 1'b1;
					state <= IFETCH;
				end
			endcase
		`R:
			case(func)
			`UNLK:	state <= UNLK;
			endcase
		`NOP: state <= IFETCH;
		`JSR: begin tgt <= {pc[31:26],ir[25:2],2'b00}; state <= JSR1; end
		`JMP: begin pc[25:2] <= ir[25:2]; state <= IFETCH; end
		`Bcc:
			case(cond)
			`BRA:	begin pc <= pc + brdisp; state <= IFETCH; end
			`BEQ:	begin if ( cr_zf) pc <= pc + brdisp; state <= IFETCH; end
			`BNE:	begin if (!cr_zf) pc <= pc + brdisp; state <= IFETCH; end
			`BMI:	begin if ( cr_nf) pc <= pc + brdisp; state <= IFETCH; end
			`BPL:	begin if (!cr_zf) pc <= pc + brdisp; state <= IFETCH; end
			`BHI:	begin if (!cr_cf & !cr_zf) pc <= pc + brdisp; state <= IFETCH; end
			`BLS:	begin if (cf |zf) pc <= pc + brdisp; state <= IFETCH; end
			`BHS:	begin if (!cr_cf) pc <= pc + brdisp; state <= IFETCH; end
			`BLO:	begin if ( cr_cf) pc <= pc + brdisp; state <= IFETCH; end
			`BGT:	begin if ((cr_nf & cr_vf & !cr_zf)|(!cr_nf & !cr_vf & !cr_zf)) pc <= pc + brdisp; state <= IFETCH; end
			`BLE:	begin if (cr_zf | (cr_nf & !cr_vf) | (!cr_nf & cr_vf)) pc <= pc + brdisp; state <= IFETCH; end
			`BGE:	begin if ((cr_nf & cr_vf)|(!cr_nf & !cr_vf)) pc <= pc + brdisp; state <= IFETCH; end
			`BLT:	begin if ((cr_nf & !cr_vf)|(!cr_nf & cr_vf)) pc <= pc + brdisp; state <= IFETCH; end
			`BVS:	begin if ( cr_vf) pc <= pc + brdisp; state <= IFETCH; end
			`BVC:	begin if (!cr_vf) pc <= pc + brdisp; state <= IFETCH; end
			endcase
		`TRAPcc:
			case(cond)
			`TRAP:	begin vector <= `TRAP_VECTOR + {ir[3:0],2'b00}; state <= TRAP; end
			`TEQ:	begin if ( cr_zf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TNE:	begin if (!cr_zf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TMI:	begin if ( cr_nf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TPL:	begin if (!cr_zf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`THI:	begin if (!cr_cf & !cr_zf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TLS:	begin if (cf |zf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`THS:	begin if (!cr_cf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TLO:	begin if ( cr_cf) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TGT:	begin if ((cr_nf & cr_vf & !cr_zf)|(!cr_nf & !cr_vf & !cr_zf)) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TLE:	begin if (cr_zf | (cr_nf & !cr_vf) | (!cr_nf & cr_vf)) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TGE:	begin if ((cr_nf & cr_vf)|(!cr_nf & !cr_vf)) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TLT:	begin if ((cr_nf & !cr_vf)|(!cr_nf & cr_vf)) begin vector <= `TRAP_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TVS:	begin if ( cr_vf) begin vector <= `TRAPV_VECTOR; state <= TRAP; end else state <= IFETCH; end
			`TVC:	begin if (!cr_vf) begin vector <= `TRAPV_VECTOR; state <= TRAP; end else state <= IFETCH; end
			endcase
		`SETcc:	Rn <= ir[15:11];
		`PUSH:	state <= PUSH1;
		`POP:	state <= POP1;
		endcase
		if (isIllegalOpcode) begin
			vector <= `ILLEGAL_INSN;
			state <= TRAP;
		end
	end

