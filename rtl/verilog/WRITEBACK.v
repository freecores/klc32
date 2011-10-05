// ============================================================================
// (C) 2011 Robert Finch
// All Rights Reserved.
// robfinch<remove>@opencores.org
//
// KLC32 - 32 bit CPU
// WRITEBACK.v - update register file / generate flags
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
WRITEBACK:
	begin
		if (opcode==`POP)
			state <= POP1;
		else
			state <= WRITE_FLAGS;
		if (opcode!=`CMPI && !(opcode==`RR && func==`CMP)) begin
			regfile[Rn] <= res;
			if (Rn==5'd31) begin
				if (sf) ssp <= res;
				else usp <= res;
			end
		end
		case(opcode)
		`R:
			case(func)
			`ABS:
				begin
				vf <= res[31];
				cf <= 1'b0;
				nf <= res[31];
				zf <= res==32'd0;
				end
			`SGN,`NOT,`EXTB,`EXTH:
				begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= res[31];
				zf <= res==32'd0;
				end
			`NEG:
				begin
				vf <= v_rr;
				cf <= c_rr;
				nf <= res[31];
				zf <= res==32'd0;
				end
			endcase
		`RR:
			case(func)
			`ADD,`SUB:
				begin
				vf <= v_rr;
				cf <= c_rr;
				nf <= res[31];
				zf <= res==32'd0;
				end
			`CMP:
				begin
				vf <= 1'b0;
				cf <= c_rr;
				nf <= res[31];
				zf <= res==32'd0;
				end
			`AND,`OR,`EOR,`NAND,`NOR,`ENOR,`MIN,`MAX,
			`LWX,`LHX,`LBX,`LHUX,`LBUX:
				begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= res[31];
				zf <= res==32'd0;
				end
			`SHL,`ROL:
				begin
				vf <= 1'b0;
				cf <= shlo[32];
				nf <= res[31];
				zf <= res==32'd0;
				end
			`SHR,`ROR:
				begin
				vf <= 1'b0;
				cf <= shro[31];
				nf <= res[31];
				zf <= res==32'd0;
				end
			`BCDADD:
				begin
				vf <= 1'b0;
				cf <= bcdaddc;
				nf <= res[7];
				zf <= res[7:0]==8'd0;
				end
			`BCDSUB:
				begin
				vf <= 1'b0;
				cf <= bcdsubc;
				nf <= res[7];
				zf <= res[7:0]==8'd0;
				end
			endcase
		`ADDI,`SUBI:
			begin
			vf <= v_ri;
			cf <= c_ri;
			nf <= res[31];
			zf <= res==32'd0;
			end
		`CMPI:
			begin
			vf <= 1'b0;
			cf <= c_ri;
			nf <= res[31];
			zf <= res==32'd0;
			end
		`ANDI,`ORI,`EORI,`LW,`LH,`LB,`LHU,`LBU,`POP,`TAS:
			begin
			vf <= 1'b0;
			cf <= 1'b0;
			nf <= res[31];
			zf <= res==32'd0;
			end
		`LINK:
			begin
				state <= IFETCH;
				if (sf)
					ssp <= ssp + imm;
				else
					usp <= usp + imm;
			end
		endcase
	end

