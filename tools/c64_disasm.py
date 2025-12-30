#!/usr/bin/env python3
"""
C64 6502 Disassembler with Flow Analysis

Disassembles C64 .prg files using flow analysis to distinguish code from data.
"""

import argparse
from collections import deque
from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


# =============================================================================
# Byte Classification
# =============================================================================

class ByteType(Enum):
    UNKNOWN = auto()
    CODE = auto()
    CODE_OPERAND = auto()
    DATA = auto()


@dataclass
class MemoryByte:
    value: int
    byte_type: ByteType = ByteType.UNKNOWN
    instruction_start: bool = False
    label: Optional[str] = None
    references_from: List[int] = field(default_factory=list)


# =============================================================================
# 6502 Opcode Definitions
# =============================================================================

@dataclass
class OpcodeInfo:
    mnemonic: str
    addressing_mode: str
    size: int
    instruction_type: str  # normal, branch, jump, jump_indirect, jsr, return


# Addressing mode sizes
ADDR_SIZES = {
    "impl": 1, "acc": 1, "imm": 2, "zpg": 2, "zpg_x": 2, "zpg_y": 2,
    "abs": 3, "abs_x": 3, "abs_y": 3, "ind": 3, "x_ind": 2, "ind_y": 2, "rel": 2
}

# Complete 6502 opcode table
OPCODES: Dict[int, OpcodeInfo] = {
    # BRK, ORA
    0x00: OpcodeInfo("BRK", "impl", 1, "return"),
    0x01: OpcodeInfo("ORA", "x_ind", 2, "normal"),
    0x05: OpcodeInfo("ORA", "zpg", 2, "normal"),
    0x06: OpcodeInfo("ASL", "zpg", 2, "normal"),
    0x08: OpcodeInfo("PHP", "impl", 1, "normal"),
    0x09: OpcodeInfo("ORA", "imm", 2, "normal"),
    0x0A: OpcodeInfo("ASL", "acc", 1, "normal"),
    0x0D: OpcodeInfo("ORA", "abs", 3, "normal"),
    0x0E: OpcodeInfo("ASL", "abs", 3, "normal"),

    # Branches and more
    0x10: OpcodeInfo("BPL", "rel", 2, "branch"),
    0x11: OpcodeInfo("ORA", "ind_y", 2, "normal"),
    0x15: OpcodeInfo("ORA", "zpg_x", 2, "normal"),
    0x16: OpcodeInfo("ASL", "zpg_x", 2, "normal"),
    0x18: OpcodeInfo("CLC", "impl", 1, "normal"),
    0x19: OpcodeInfo("ORA", "abs_y", 3, "normal"),
    0x1D: OpcodeInfo("ORA", "abs_x", 3, "normal"),
    0x1E: OpcodeInfo("ASL", "abs_x", 3, "normal"),

    # JSR, AND
    0x20: OpcodeInfo("JSR", "abs", 3, "jsr"),
    0x21: OpcodeInfo("AND", "x_ind", 2, "normal"),
    0x24: OpcodeInfo("BIT", "zpg", 2, "normal"),
    0x25: OpcodeInfo("AND", "zpg", 2, "normal"),
    0x26: OpcodeInfo("ROL", "zpg", 2, "normal"),
    0x28: OpcodeInfo("PLP", "impl", 1, "normal"),
    0x29: OpcodeInfo("AND", "imm", 2, "normal"),
    0x2A: OpcodeInfo("ROL", "acc", 1, "normal"),
    0x2C: OpcodeInfo("BIT", "abs", 3, "normal"),
    0x2D: OpcodeInfo("AND", "abs", 3, "normal"),
    0x2E: OpcodeInfo("ROL", "abs", 3, "normal"),

    # BMI, AND
    0x30: OpcodeInfo("BMI", "rel", 2, "branch"),
    0x31: OpcodeInfo("AND", "ind_y", 2, "normal"),
    0x35: OpcodeInfo("AND", "zpg_x", 2, "normal"),
    0x36: OpcodeInfo("ROL", "zpg_x", 2, "normal"),
    0x38: OpcodeInfo("SEC", "impl", 1, "normal"),
    0x39: OpcodeInfo("AND", "abs_y", 3, "normal"),
    0x3D: OpcodeInfo("AND", "abs_x", 3, "normal"),
    0x3E: OpcodeInfo("ROL", "abs_x", 3, "normal"),

    # RTI, EOR
    0x40: OpcodeInfo("RTI", "impl", 1, "return"),
    0x41: OpcodeInfo("EOR", "x_ind", 2, "normal"),
    0x45: OpcodeInfo("EOR", "zpg", 2, "normal"),
    0x46: OpcodeInfo("LSR", "zpg", 2, "normal"),
    0x48: OpcodeInfo("PHA", "impl", 1, "normal"),
    0x49: OpcodeInfo("EOR", "imm", 2, "normal"),
    0x4A: OpcodeInfo("LSR", "acc", 1, "normal"),
    0x4C: OpcodeInfo("JMP", "abs", 3, "jump"),
    0x4D: OpcodeInfo("EOR", "abs", 3, "normal"),
    0x4E: OpcodeInfo("LSR", "abs", 3, "normal"),

    # BVC, EOR
    0x50: OpcodeInfo("BVC", "rel", 2, "branch"),
    0x51: OpcodeInfo("EOR", "ind_y", 2, "normal"),
    0x55: OpcodeInfo("EOR", "zpg_x", 2, "normal"),
    0x56: OpcodeInfo("LSR", "zpg_x", 2, "normal"),
    0x58: OpcodeInfo("CLI", "impl", 1, "normal"),
    0x59: OpcodeInfo("EOR", "abs_y", 3, "normal"),
    0x5D: OpcodeInfo("EOR", "abs_x", 3, "normal"),
    0x5E: OpcodeInfo("LSR", "abs_x", 3, "normal"),

    # RTS, ADC
    0x60: OpcodeInfo("RTS", "impl", 1, "return"),
    0x61: OpcodeInfo("ADC", "x_ind", 2, "normal"),
    0x65: OpcodeInfo("ADC", "zpg", 2, "normal"),
    0x66: OpcodeInfo("ROR", "zpg", 2, "normal"),
    0x68: OpcodeInfo("PLA", "impl", 1, "normal"),
    0x69: OpcodeInfo("ADC", "imm", 2, "normal"),
    0x6A: OpcodeInfo("ROR", "acc", 1, "normal"),
    0x6C: OpcodeInfo("JMP", "ind", 3, "jump_indirect"),
    0x6D: OpcodeInfo("ADC", "abs", 3, "normal"),
    0x6E: OpcodeInfo("ROR", "abs", 3, "normal"),

    # BVS, ADC
    0x70: OpcodeInfo("BVS", "rel", 2, "branch"),
    0x71: OpcodeInfo("ADC", "ind_y", 2, "normal"),
    0x75: OpcodeInfo("ADC", "zpg_x", 2, "normal"),
    0x76: OpcodeInfo("ROR", "zpg_x", 2, "normal"),
    0x78: OpcodeInfo("SEI", "impl", 1, "normal"),
    0x79: OpcodeInfo("ADC", "abs_y", 3, "normal"),
    0x7D: OpcodeInfo("ADC", "abs_x", 3, "normal"),
    0x7E: OpcodeInfo("ROR", "abs_x", 3, "normal"),

    # STA
    0x81: OpcodeInfo("STA", "x_ind", 2, "normal"),
    0x84: OpcodeInfo("STY", "zpg", 2, "normal"),
    0x85: OpcodeInfo("STA", "zpg", 2, "normal"),
    0x86: OpcodeInfo("STX", "zpg", 2, "normal"),
    0x88: OpcodeInfo("DEY", "impl", 1, "normal"),
    0x8A: OpcodeInfo("TXA", "impl", 1, "normal"),
    0x8C: OpcodeInfo("STY", "abs", 3, "normal"),
    0x8D: OpcodeInfo("STA", "abs", 3, "normal"),
    0x8E: OpcodeInfo("STX", "abs", 3, "normal"),

    # BCC, STA
    0x90: OpcodeInfo("BCC", "rel", 2, "branch"),
    0x91: OpcodeInfo("STA", "ind_y", 2, "normal"),
    0x94: OpcodeInfo("STY", "zpg_x", 2, "normal"),
    0x95: OpcodeInfo("STA", "zpg_x", 2, "normal"),
    0x96: OpcodeInfo("STX", "zpg_y", 2, "normal"),
    0x98: OpcodeInfo("TYA", "impl", 1, "normal"),
    0x99: OpcodeInfo("STA", "abs_y", 3, "normal"),
    0x9A: OpcodeInfo("TXS", "impl", 1, "normal"),
    0x9D: OpcodeInfo("STA", "abs_x", 3, "normal"),

    # LDY, LDA, LDX
    0xA0: OpcodeInfo("LDY", "imm", 2, "normal"),
    0xA1: OpcodeInfo("LDA", "x_ind", 2, "normal"),
    0xA2: OpcodeInfo("LDX", "imm", 2, "normal"),
    0xA4: OpcodeInfo("LDY", "zpg", 2, "normal"),
    0xA5: OpcodeInfo("LDA", "zpg", 2, "normal"),
    0xA6: OpcodeInfo("LDX", "zpg", 2, "normal"),
    0xA8: OpcodeInfo("TAY", "impl", 1, "normal"),
    0xA9: OpcodeInfo("LDA", "imm", 2, "normal"),
    0xAA: OpcodeInfo("TAX", "impl", 1, "normal"),
    0xAC: OpcodeInfo("LDY", "abs", 3, "normal"),
    0xAD: OpcodeInfo("LDA", "abs", 3, "normal"),
    0xAE: OpcodeInfo("LDX", "abs", 3, "normal"),

    # BCS, LDA
    0xB0: OpcodeInfo("BCS", "rel", 2, "branch"),
    0xB1: OpcodeInfo("LDA", "ind_y", 2, "normal"),
    0xB4: OpcodeInfo("LDY", "zpg_x", 2, "normal"),
    0xB5: OpcodeInfo("LDA", "zpg_x", 2, "normal"),
    0xB6: OpcodeInfo("LDX", "zpg_y", 2, "normal"),
    0xB8: OpcodeInfo("CLV", "impl", 1, "normal"),
    0xB9: OpcodeInfo("LDA", "abs_y", 3, "normal"),
    0xBA: OpcodeInfo("TSX", "impl", 1, "normal"),
    0xBC: OpcodeInfo("LDY", "abs_x", 3, "normal"),
    0xBD: OpcodeInfo("LDA", "abs_x", 3, "normal"),
    0xBE: OpcodeInfo("LDX", "abs_y", 3, "normal"),

    # CPY, CMP
    0xC0: OpcodeInfo("CPY", "imm", 2, "normal"),
    0xC1: OpcodeInfo("CMP", "x_ind", 2, "normal"),
    0xC4: OpcodeInfo("CPY", "zpg", 2, "normal"),
    0xC5: OpcodeInfo("CMP", "zpg", 2, "normal"),
    0xC6: OpcodeInfo("DEC", "zpg", 2, "normal"),
    0xC8: OpcodeInfo("INY", "impl", 1, "normal"),
    0xC9: OpcodeInfo("CMP", "imm", 2, "normal"),
    0xCA: OpcodeInfo("DEX", "impl", 1, "normal"),
    0xCC: OpcodeInfo("CPY", "abs", 3, "normal"),
    0xCD: OpcodeInfo("CMP", "abs", 3, "normal"),
    0xCE: OpcodeInfo("DEC", "abs", 3, "normal"),

    # BNE, CMP
    0xD0: OpcodeInfo("BNE", "rel", 2, "branch"),
    0xD1: OpcodeInfo("CMP", "ind_y", 2, "normal"),
    0xD5: OpcodeInfo("CMP", "zpg_x", 2, "normal"),
    0xD6: OpcodeInfo("DEC", "zpg_x", 2, "normal"),
    0xD8: OpcodeInfo("CLD", "impl", 1, "normal"),
    0xD9: OpcodeInfo("CMP", "abs_y", 3, "normal"),
    0xDD: OpcodeInfo("CMP", "abs_x", 3, "normal"),
    0xDE: OpcodeInfo("DEC", "abs_x", 3, "normal"),

    # CPX, SBC
    0xE0: OpcodeInfo("CPX", "imm", 2, "normal"),
    0xE1: OpcodeInfo("SBC", "x_ind", 2, "normal"),
    0xE4: OpcodeInfo("CPX", "zpg", 2, "normal"),
    0xE5: OpcodeInfo("SBC", "zpg", 2, "normal"),
    0xE6: OpcodeInfo("INC", "zpg", 2, "normal"),
    0xE8: OpcodeInfo("INX", "impl", 1, "normal"),
    0xE9: OpcodeInfo("SBC", "imm", 2, "normal"),
    0xEA: OpcodeInfo("NOP", "impl", 1, "normal"),
    0xEC: OpcodeInfo("CPX", "abs", 3, "normal"),
    0xED: OpcodeInfo("SBC", "abs", 3, "normal"),
    0xEE: OpcodeInfo("INC", "abs", 3, "normal"),

    # BEQ, SBC
    0xF0: OpcodeInfo("BEQ", "rel", 2, "branch"),
    0xF1: OpcodeInfo("SBC", "ind_y", 2, "normal"),
    0xF5: OpcodeInfo("SBC", "zpg_x", 2, "normal"),
    0xF6: OpcodeInfo("INC", "zpg_x", 2, "normal"),
    0xF8: OpcodeInfo("SED", "impl", 1, "normal"),
    0xF9: OpcodeInfo("SBC", "abs_y", 3, "normal"),
    0xFD: OpcodeInfo("SBC", "abs_x", 3, "normal"),
    0xFE: OpcodeInfo("INC", "abs_x", 3, "normal"),
}


# =============================================================================
# C64 Hardware Symbols
# =============================================================================

C64_SYMBOLS: Dict[int, str] = {
    # Kernal ROM routines
    0xFFD2: "CHROUT",
    0xFFE4: "GETIN",
    0xFFCF: "CHRIN",
    0xFFCC: "CLRCHN",
    0xFFBA: "SETLFS",
    0xFFBD: "SETNAM",
    0xFFC0: "OPEN",
    0xFFC3: "CLOSE",
    0xFFD5: "LOAD",
    0xFFD8: "SAVE",
    0xFFE1: "STOP",
    0xFFE7: "CLALL",
    0xFF81: "CINT",
    0xFF84: "IOINIT",
    0xFF87: "RAMTAS",
    0xFF8A: "RESTOR",
    0xFF90: "SETMSG",
    0xFF93: "SECOND",
    0xFF96: "TKSA",
    0xFFB1: "READST",
    0xFFB4: "SETLFS2",
    0xFFB7: "READST2",

    # BASIC ROM
    0xA474: "BASIC_CHRGET",
    0xA57C: "BASIC_FRMNUM",
    0xA9E7: "BASIC_PRTSTR",
    0xAB1E: "BASIC_STROUT",
    0xBDCD: "BASIC_FOUT",
    0xE544: "BASIC_CLRSCR",

    # VIC-II registers
    0xD000: "VIC_SP0X",
    0xD001: "VIC_SP0Y",
    0xD002: "VIC_SP1X",
    0xD003: "VIC_SP1Y",
    0xD004: "VIC_SP2X",
    0xD005: "VIC_SP2Y",
    0xD006: "VIC_SP3X",
    0xD007: "VIC_SP3Y",
    0xD008: "VIC_SP4X",
    0xD009: "VIC_SP4Y",
    0xD00A: "VIC_SP5X",
    0xD00B: "VIC_SP5Y",
    0xD00C: "VIC_SP6X",
    0xD00D: "VIC_SP6Y",
    0xD00E: "VIC_SP7X",
    0xD00F: "VIC_SP7Y",
    0xD010: "VIC_SPXMSB",
    0xD011: "VIC_SCROLY",
    0xD012: "VIC_RASTER",
    0xD013: "VIC_LPENX",
    0xD014: "VIC_LPENY",
    0xD015: "VIC_SPENA",
    0xD016: "VIC_SCROLX",
    0xD017: "VIC_YXPAND",
    0xD018: "VIC_VMCSB",
    0xD019: "VIC_VICIRQ",
    0xD01A: "VIC_IRQMSK",
    0xD01B: "VIC_SPBGPR",
    0xD01C: "VIC_SPMC",
    0xD01D: "VIC_XXPAND",
    0xD01E: "VIC_SPSPCL",
    0xD01F: "VIC_SPBGCL",
    0xD020: "VIC_EXTCOL",
    0xD021: "VIC_BGCOL0",
    0xD022: "VIC_BGCOL1",
    0xD023: "VIC_BGCOL2",
    0xD024: "VIC_BGCOL3",
    0xD025: "VIC_SPMC0",
    0xD026: "VIC_SPMC1",
    0xD027: "VIC_SP0COL",
    0xD028: "VIC_SP1COL",
    0xD029: "VIC_SP2COL",
    0xD02A: "VIC_SP3COL",
    0xD02B: "VIC_SP4COL",
    0xD02C: "VIC_SP5COL",
    0xD02D: "VIC_SP6COL",
    0xD02E: "VIC_SP7COL",

    # SID registers
    0xD400: "SID_V1FREQL",
    0xD401: "SID_V1FREQH",
    0xD402: "SID_V1PWL",
    0xD403: "SID_V1PWH",
    0xD404: "SID_V1CTRL",
    0xD405: "SID_V1AD",
    0xD406: "SID_V1SR",
    0xD407: "SID_V2FREQL",
    0xD408: "SID_V2FREQH",
    0xD409: "SID_V2PWL",
    0xD40A: "SID_V2PWH",
    0xD40B: "SID_V2CTRL",
    0xD40C: "SID_V2AD",
    0xD40D: "SID_V2SR",
    0xD40E: "SID_V3FREQL",
    0xD40F: "SID_V3FREQH",
    0xD410: "SID_V3PWL",
    0xD411: "SID_V3PWH",
    0xD412: "SID_V3CTRL",
    0xD413: "SID_V3AD",
    0xD414: "SID_V3SR",
    0xD415: "SID_FCUTL",
    0xD416: "SID_FCUTH",
    0xD417: "SID_RESFLT",
    0xD418: "SID_VOLUME",

    # CIA1 registers
    0xDC00: "CIA1_PRA",
    0xDC01: "CIA1_PRB",
    0xDC02: "CIA1_DDRA",
    0xDC03: "CIA1_DDRB",
    0xDC04: "CIA1_TALO",
    0xDC05: "CIA1_TAHI",
    0xDC06: "CIA1_TBLO",
    0xDC07: "CIA1_TBHI",
    0xDC08: "CIA1_TOD10",
    0xDC09: "CIA1_TODSEC",
    0xDC0A: "CIA1_TODMIN",
    0xDC0B: "CIA1_TODHR",
    0xDC0C: "CIA1_SDR",
    0xDC0D: "CIA1_ICR",
    0xDC0E: "CIA1_CRA",
    0xDC0F: "CIA1_CRB",

    # CIA2 registers
    0xDD00: "CIA2_PRA",
    0xDD01: "CIA2_PRB",
    0xDD02: "CIA2_DDRA",
    0xDD03: "CIA2_DDRB",
    0xDD0D: "CIA2_ICR",
    0xDD0E: "CIA2_CRA",
    0xDD0F: "CIA2_CRB",

    # IRQ vectors
    0x0314: "IRQ_VECTOR_LO",
    0x0315: "IRQ_VECTOR_HI",
    0x0316: "BRK_VECTOR_LO",
    0x0317: "BRK_VECTOR_HI",
    0x0318: "NMI_VECTOR_LO",
    0x0319: "NMI_VECTOR_HI",

    # Screen memory (default)
    0x0400: "SCREEN_MEM",

    # Color RAM
    0xD800: "COLOR_RAM",
}


# =============================================================================
# Memory Model
# =============================================================================

class Memory:
    def __init__(self, data: bytes, load_address: int):
        self.load_address = load_address
        self.end_address = load_address + len(data) - 1
        self.bytes: Dict[int, MemoryByte] = {}

        for i, b in enumerate(data):
            self.bytes[load_address + i] = MemoryByte(value=b)

    def is_in_range(self, addr: int) -> bool:
        return addr in self.bytes

    def get_byte(self, addr: int) -> Optional[int]:
        if addr in self.bytes:
            return self.bytes[addr].value
        return None

    def mark_as_code(self, addr: int, instruction_size: int):
        if addr in self.bytes:
            self.bytes[addr].byte_type = ByteType.CODE
            self.bytes[addr].instruction_start = True
        for i in range(1, instruction_size):
            if addr + i in self.bytes:
                self.bytes[addr + i].byte_type = ByteType.CODE_OPERAND

    def add_reference(self, from_addr: int, to_addr: int):
        if to_addr in self.bytes:
            self.bytes[to_addr].references_from.append(from_addr)


# =============================================================================
# Flow Analyzer
# =============================================================================

class FlowAnalyzer:
    def __init__(self, memory: Memory, entry_points: List[int]):
        self.memory = memory
        self.work_queue: deque = deque(entry_points)
        self.visited: Set[int] = set()
        self.subroutines: Set[int] = set()
        self.indirect_jumps: List[int] = []
        self.jump_targets: Set[int] = set()
        self.branch_targets: Set[int] = set()

    def analyze(self):
        while self.work_queue:
            pc = self.work_queue.popleft()

            if pc in self.visited:
                continue
            if not self.memory.is_in_range(pc):
                continue

            self._trace_basic_block(pc)

    def _trace_basic_block(self, start_pc: int):
        pc = start_pc

        while True:
            if pc in self.visited:
                break
            if not self.memory.is_in_range(pc):
                break

            # Check if byte already marked as operand (overlap)
            mb = self.memory.bytes[pc]
            if mb.byte_type == ByteType.CODE_OPERAND:
                break

            self.visited.add(pc)

            opcode = mb.value
            info = OPCODES.get(opcode)

            if info is None:
                # Unknown opcode - stop tracing
                break

            # Check if we have all bytes for this instruction
            for i in range(1, info.size):
                if not self.memory.is_in_range(pc + i):
                    return

            # Mark bytes as code
            self.memory.mark_as_code(pc, info.size)

            # Get operand bytes
            operand = self._get_operand(pc, info.size)

            # Handle instruction based on type
            if info.instruction_type == "normal":
                pc += info.size
                continue

            elif info.instruction_type == "branch":
                target = self._calculate_branch_target(pc, operand[0])
                self.branch_targets.add(target)
                self.memory.add_reference(pc, target)
                self._add_work(target)
                # Fall through
                pc += info.size
                continue

            elif info.instruction_type == "jump":
                target = operand[0] | (operand[1] << 8)
                self.jump_targets.add(target)
                self.memory.add_reference(pc, target)
                self._add_work(target)
                break  # No fall-through

            elif info.instruction_type == "jump_indirect":
                self.indirect_jumps.append(pc)
                break  # Cannot determine target

            elif info.instruction_type == "jsr":
                target = operand[0] | (operand[1] << 8)
                self.subroutines.add(target)
                self.memory.add_reference(pc, target)
                self._add_work(target)
                # Continue after JSR
                pc += info.size
                continue

            elif info.instruction_type == "return":
                break  # End of subroutine

            else:
                pc += info.size

    def _get_operand(self, pc: int, size: int) -> bytes:
        result = []
        for i in range(1, size):
            b = self.memory.get_byte(pc + i)
            if b is not None:
                result.append(b)
        return bytes(result)

    def _calculate_branch_target(self, pc: int, offset_byte: int) -> int:
        if offset_byte >= 0x80:
            offset = offset_byte - 256
        else:
            offset = offset_byte
        return pc + 2 + offset

    def _add_work(self, addr: int):
        if addr not in self.visited and self.memory.is_in_range(addr):
            self.work_queue.append(addr)


# =============================================================================
# Output Formatter
# =============================================================================

class OutputFormatter:
    def __init__(self, memory: Memory, analyzer: FlowAnalyzer, use_symbols: bool = True):
        self.memory = memory
        self.analyzer = analyzer
        self.use_symbols = use_symbols
        self.labels: Dict[int, str] = {}
        self._generate_labels()

    def _generate_labels(self):
        label_num = 0

        # Label subroutines
        for addr in sorted(self.analyzer.subroutines):
            if self.memory.is_in_range(addr):
                self.labels[addr] = f"sub_{addr:04X}"

        # Label jump targets
        for addr in sorted(self.analyzer.jump_targets):
            if addr not in self.labels and self.memory.is_in_range(addr):
                self.labels[addr] = f"loc_{addr:04X}"

        # Label branch targets
        for addr in sorted(self.analyzer.branch_targets):
            if addr not in self.labels and self.memory.is_in_range(addr):
                self.labels[addr] = f"L{addr:04X}"

    def _get_symbol(self, addr: int) -> Optional[str]:
        if addr in self.labels:
            return self.labels[addr]
        if self.use_symbols and addr in C64_SYMBOLS:
            return C64_SYMBOLS[addr]
        return None

    def _format_operand(self, pc: int, info: OpcodeInfo) -> str:
        mode = info.addressing_mode

        if mode == "impl":
            return ""

        if mode == "acc":
            return "A"

        operand = []
        for i in range(1, info.size):
            b = self.memory.get_byte(pc + i)
            if b is not None:
                operand.append(b)

        if not operand:
            return ""

        if mode == "imm":
            return f"#${operand[0]:02X}"

        elif mode == "zpg":
            return f"${operand[0]:02X}"

        elif mode == "zpg_x":
            return f"${operand[0]:02X},X"

        elif mode == "zpg_y":
            return f"${operand[0]:02X},Y"

        elif mode == "abs":
            addr = operand[0] | (operand[1] << 8)
            sym = self._get_symbol(addr)
            if sym:
                return sym
            return f"${addr:04X}"

        elif mode == "abs_x":
            addr = operand[0] | (operand[1] << 8)
            sym = self._get_symbol(addr)
            if sym:
                return f"{sym},X"
            return f"${addr:04X},X"

        elif mode == "abs_y":
            addr = operand[0] | (operand[1] << 8)
            sym = self._get_symbol(addr)
            if sym:
                return f"{sym},Y"
            return f"${addr:04X},Y"

        elif mode == "ind":
            addr = operand[0] | (operand[1] << 8)
            sym = self._get_symbol(addr)
            if sym:
                return f"({sym})"
            return f"(${addr:04X})"

        elif mode == "x_ind":
            return f"(${operand[0]:02X},X)"

        elif mode == "ind_y":
            return f"(${operand[0]:02X}),Y"

        elif mode == "rel":
            offset = operand[0]
            if offset >= 0x80:
                offset -= 256
            target = pc + 2 + offset
            sym = self._get_symbol(target)
            if sym:
                return sym
            return f"${target:04X}"

        return ""

    def _format_hex_bytes(self, addr: int, size: int) -> str:
        result = []
        for i in range(size):
            b = self.memory.get_byte(addr + i)
            if b is not None:
                result.append(f"{b:02X}")
        return " ".join(result)

    def _is_printable_petscii(self, b: int) -> bool:
        return 32 <= b < 127 or 160 <= b < 255

    def _petscii_to_ascii(self, b: int) -> str:
        if 65 <= b <= 90:  # PETSCII uppercase -> lowercase
            return chr(b + 32)
        elif 193 <= b <= 218:  # PETSCII shifted uppercase
            return chr(b - 128)
        elif 32 <= b < 127:
            return chr(b)
        return '.'

    def generate_output(self) -> str:
        lines = []
        lines.append("; =============================================================================")
        lines.append(f"; Disassembly of C64 program")
        lines.append(f"; Load address: ${self.memory.load_address:04X}")
        lines.append(f"; End address:  ${self.memory.end_address:04X}")
        lines.append("; =============================================================================")
        lines.append("")
        lines.append(f"        * = ${self.memory.load_address:04X}")
        lines.append("")

        addr = self.memory.load_address
        in_data_block = False
        data_block_start = 0
        data_block_bytes = []

        while addr <= self.memory.end_address:
            mb = self.memory.bytes[addr]

            # Check for label
            if addr in self.labels:
                # Flush any pending data
                if in_data_block and data_block_bytes:
                    lines.extend(self._format_data_block(data_block_start, data_block_bytes))
                    in_data_block = False
                    data_block_bytes = []

                lines.append("")
                lines.append(f"{self.labels[addr]}:")

            if mb.byte_type == ByteType.CODE and mb.instruction_start:
                # Flush any pending data
                if in_data_block and data_block_bytes:
                    lines.extend(self._format_data_block(data_block_start, data_block_bytes))
                    in_data_block = False
                    data_block_bytes = []

                # Format instruction
                opcode = mb.value
                info = OPCODES.get(opcode)
                if info:
                    operand_str = self._format_operand(addr, info)

                    if operand_str:
                        instr = f"{info.mnemonic} {operand_str}"
                    else:
                        instr = info.mnemonic

                    lines.append(f"        {instr}")
                    addr += info.size
                else:
                    lines.append(f"        .byte ${mb.value:02X}")
                    addr += 1

            elif mb.byte_type == ByteType.CODE_OPERAND:
                # Skip - already output with instruction
                addr += 1

            else:
                # Data byte - accumulate for block output
                if not in_data_block:
                    in_data_block = True
                    data_block_start = addr
                    data_block_bytes = []

                data_block_bytes.append(mb.value)
                addr += 1

        # Flush any remaining data
        if in_data_block and data_block_bytes:
            lines.extend(self._format_data_block(data_block_start, data_block_bytes))

        return "\n".join(lines)

    def _format_data_block(self, start_addr: int, data: List[int]) -> List[str]:
        lines = []
        BYTES_PER_LINE = 16

        i = 0
        while i < len(data):
            addr = start_addr + i

            # Check for label at this address
            if addr in self.labels and i > 0:
                lines.append("")
                lines.append(f"{self.labels[addr]}:")

            # Collect bytes for this line (up to BYTES_PER_LINE or until next label)
            row = []
            while len(row) < BYTES_PER_LINE and i < len(data):
                next_addr = start_addr + i
                # Stop if we hit a label (except at start of row)
                if len(row) > 0 and next_addr in self.labels:
                    break
                row.append(data[i])
                i += 1

            # Format as hex bytes with text comment
            hex_bytes = ", ".join(f"${b:02X}" for b in row)
            text = "".join(self._petscii_to_ascii(b) if self._is_printable_petscii(b) else '.' for b in row)
            lines.append(f"        .byte {hex_bytes}  ; {text}")

        return lines


# =============================================================================
# Main
# =============================================================================

def find_basic_sys_entry(memory: Memory) -> Optional[int]:
    """Find SYS entry point from BASIC stub."""
    # Look for pattern: 9E (SYS token) followed by ASCII digits
    addr = memory.load_address

    # Skip link pointer (2 bytes) and line number (2 bytes)
    addr += 4

    if not memory.is_in_range(addr):
        return None

    b = memory.get_byte(addr)
    if b == 0x9E:  # SYS token
        # Read ASCII digits
        addr += 1
        digits = []
        while memory.is_in_range(addr):
            b = memory.get_byte(addr)
            if b is None:
                break
            if 0x30 <= b <= 0x39:  # ASCII digit
                digits.append(chr(b))
                addr += 1
            else:
                break

        if digits:
            try:
                return int("".join(digits))
            except ValueError:
                pass

    return None


def main():
    parser = argparse.ArgumentParser(
        description="C64 6502 Disassembler with Flow Analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s game.prg                    # Disassemble to stdout
  %(prog)s game.prg -o game.asm        # Write to file
  %(prog)s game.prg -e 0x1000          # Add extra entry point
  %(prog)s game.prg --no-symbols       # Disable C64 symbol names
"""
    )
    parser.add_argument("input", help="Input binary file (.prg or .bin)")
    parser.add_argument("-o", "--output", help="Output assembly file")
    parser.add_argument("-e", "--entry", type=lambda x: int(x, 0),
                        action="append", default=[],
                        help="Additional entry point address (hex or decimal)")
    parser.add_argument("--no-symbols", action="store_true",
                        help="Disable C64 symbol names in output")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose output")
    args = parser.parse_args()

    # Load binary
    data = Path(args.input).read_bytes()

    if len(data) < 3:
        print("Error: File too small")
        return 1

    # Extract load address (first 2 bytes for .prg format)
    load_addr = data[0] | (data[1] << 8)
    program_data = data[2:]

    print(f"Load address: ${load_addr:04X}")
    print(f"Program size: {len(program_data)} bytes")
    print(f"Address range: ${load_addr:04X}-${load_addr + len(program_data) - 1:04X}")

    # Initialize memory model
    memory = Memory(program_data, load_addr)

    # Determine entry points
    entry_points = []

    # Try to find BASIC SYS entry
    sys_entry = find_basic_sys_entry(memory)
    if sys_entry:
        print(f"Found BASIC SYS entry: ${sys_entry:04X} ({sys_entry})")
        entry_points.append(sys_entry)
    else:
        # Default: assume code starts right after load address
        default_entry = load_addr
        print(f"No BASIC stub found, using default entry: ${default_entry:04X}")
        entry_points.append(default_entry)

    # Add user-specified entry points
    for ep in args.entry:
        if ep not in entry_points:
            entry_points.append(ep)
            print(f"Added entry point: ${ep:04X}")

    # Run flow analysis
    print("\nRunning flow analysis...")
    analyzer = FlowAnalyzer(memory, entry_points)
    analyzer.analyze()

    # Calculate statistics
    code_bytes = sum(1 for b in memory.bytes.values()
                     if b.byte_type in (ByteType.CODE, ByteType.CODE_OPERAND))
    data_bytes = len(memory.bytes) - code_bytes

    print(f"\nAnalysis complete:")
    print(f"  Code bytes: {code_bytes} ({100*code_bytes/len(memory.bytes):.1f}%)")
    print(f"  Data bytes: {data_bytes} ({100*data_bytes/len(memory.bytes):.1f}%)")
    print(f"  Subroutines found: {len(analyzer.subroutines)}")
    print(f"  Jump targets: {len(analyzer.jump_targets)}")
    print(f"  Branch targets: {len(analyzer.branch_targets)}")

    if analyzer.indirect_jumps:
        print(f"\nIndirect jumps (may need manual analysis):")
        for addr in analyzer.indirect_jumps:
            print(f"  ${addr:04X}")

    # Generate output
    formatter = OutputFormatter(memory, analyzer, use_symbols=not args.no_symbols)
    output = formatter.generate_output()

    if args.output:
        Path(args.output).write_text(output)
        print(f"\nOutput written to: {args.output}")
    else:
        print("\n" + "=" * 70)
        print(output)

    return 0


if __name__ == "__main__":
    exit(main())
