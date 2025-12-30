#!/usr/bin/env python3
"""
Annotate assembler files with variable comments based on docs/variables.md
"""
import re
import os

# Variable mapping: address -> (name, short_description)
# Addresses in uppercase without $
VARIABLES = {
    # Zero page
    "01": ("CPU_PORT", "memory config"),
    "61": ("FAC_MANTISSA", "math calc"),
    "65": ("ARG_MANTISSA", "math calc"),
    "B4": ("MAP_PTR", "map data ptr lo"),
    "B5": ("MAP_PTR", "map data ptr hi"),
    "D1": ("SCREEN_PTR", "screen line ptr lo"),
    "D2": ("SCREEN_PTR", "screen line ptr hi"),
    "D3": ("CURSOR_COL", "cursor column"),
    "D6": ("CURSOR_ROW", "cursor row"),
    "F3": ("COLOR_PTR", "color RAM ptr lo"),
    "F4": ("COLOR_PTR", "color RAM ptr hi"),
    "F7": ("TEMP_PTR1", "general ptr lo"),
    "F8": ("TEMP_PTR1", "general ptr hi"),
    "F9": ("TEMP_PTR2", "general ptr lo"),
    "FA": ("TEMP_PTR2", "general ptr hi"),
    # Page 2
    "0286": ("CHARCOLOR", "char color"),
    "0288": ("HIBASE", "screen mem page"),
    # IRQ Vector
    "0314": ("IRQ_VECTOR", "IRQ vector lo"),
    "0315": ("IRQ_VECTOR", "IRQ vector hi"),
    # Game variables $0340+
    "0340": ("SCROLL_X", "map scroll X"),
    "0341": ("SCROLL_Y", "map scroll Y"),
    "0342": ("TEMP_CALC", "temp calc lo"),
    "0343": ("TEMP_CALC", "temp calc hi"),
    "0344": ("TEMP_STORE", "temp storage lo"),
    "0345": ("TEMP_STORE", "temp storage hi"),
    "0346": ("COUNTER", "general counter"),
    "0347": ("CURRENT_PLAYER", "active player"),
    "0348": ("IRQ_COUNT", "IRQ timer"),
    "034A": ("GAME_STATE", "game phase"),
    "034B": ("CURSOR_MAP_Y", "cursor Y on map"),
    "034C": ("CURSOR_MAP_X", "cursor X on map"),
    "034D": ("PREV_JOY", "prev joystick"),
    "034E": ("UNIT_TYPE_IDX", "unit type index"),
    "034F": ("ACTION_UNIT", "unit in action"),
    "0350": ("STORED_PTR", "F9/FA backup lo"),
    "0351": ("STORED_PTR", "F9/FA backup hi"),
    "0352": ("STORED_CHAR", "stored char"),
    "0353": ("MOVE_FLAG", "movement flag"),
    "0354": ("JOY_STATE", "joystick state"),
    "0355": ("ATTACK_SRC_Y", "attack source Y"),
    "0356": ("ATTACK_SRC_X", "attack source X"),
    "0357": ("ATTACKER_TYPE", "attacker type"),
    "0358": ("ATTACKER_PTR", "attacker data ptr lo"),
    "0359": ("ATTACKER_PTR", "attacker data ptr hi"),
    "035C": ("SAVE_LETTER", "save filename"),
    "035D": ("MENU_SELECT", "menu selection"),
    # High memory
    "4FF0": ("FELDOIN_UNITS", "Feldoin unit count"),
    # Town flags $4FF2-$4FFE
    "4FF2": ("TOWN_FLAGS", "town capture flags"),
    # Sprite pointers
    "C3F8": ("SPRITE_PTRS", "sprite pointers"),
    "C3F9": ("SPRITE_PTRS", "sprite pointers"),
    "C3FA": ("SPRITE_PTRS", "sprite pointers"),
    "C3FB": ("SPRITE_PTRS", "sprite pointers"),
    "C3FC": ("SPRITE_PTRS", "sprite pointers"),
    "C3FD": ("SPRITE_PTRS", "sprite pointers"),
    "C3FE": ("SPRITE_PTRS", "sprite pointers"),
    "C3FF": ("SPRITE_PTRS", "sprite pointers"),
}

# Regex to match address operands in 6502 assembly
# Matches patterns like $0347, $F9, $0340,X, $0340,Y, ($F9),Y, etc.
# Excludes immediate mode (#$xx) by using negative lookbehind
ADDRESS_PATTERN = re.compile(r'(?<!#)\$([0-9A-Fa-f]{2,4})(?:[,\)\s]|$)')

def annotate_line(line):
    """Add variable comment to a line if it references a known variable."""
    # Skip if line already has a comment
    if ';' in line:
        return line

    # Skip empty lines and label-only lines
    stripped = line.strip()
    if not stripped or stripped.endswith(':'):
        return line

    # Find all address references in the line
    matches = ADDRESS_PATTERN.findall(line)
    for addr in matches:
        addr_upper = addr.upper()
        # Normalize to 4 digits for comparison if it's a short zero-page address
        if len(addr_upper) == 2:
            lookup_addr = addr_upper
        else:
            lookup_addr = addr_upper

        if lookup_addr in VARIABLES:
            name, desc = VARIABLES[lookup_addr]
            # Pad line to align comments
            if len(line.rstrip()) < 32:
                padded = line.rstrip().ljust(32)
            else:
                padded = line.rstrip() + "  "
            return f"{padded}; {name} ({desc})\n"

    return line

def process_file(filepath):
    """Process a single assembler file."""
    with open(filepath, 'r') as f:
        lines = f.readlines()

    modified = False
    new_lines = []
    for line in lines:
        new_line = annotate_line(line)
        if new_line != line:
            modified = True
        new_lines.append(new_line)

    if modified:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)
        return True
    return False

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    disassembly_dir = os.path.join(script_dir, '..', 'disassembly')

    # List of files to process (excluding archive)
    files = [
        '$0801-$080C_basic_header.asm',
        '$080D-$0884_initialization.asm',
        '$0885-$0A6F_main_loop_input.asm',
        '$0A70-$0BF2_movement_combat.asm',
        '$0BF3-$0E13_menu_text.asm',
        '$0E14-$0FAB_sound_sprites.asm',
        '$0FAC-$12B0_game_logic.asm',
        '$12B1-$15CC_combat_turn.asm',
        '$15CD-$1A3E_graphics_data.asm',
        '$1A3F-$1E8A_utilities_render.asm',
        '$1E8B-$2306_sound_effects.asm',
        '$2307-$23D7_file_io.asm',
    ]

    for filename in files:
        filepath = os.path.join(disassembly_dir, filename)
        if os.path.exists(filepath):
            modified = process_file(filepath)
            status = "modified" if modified else "no changes"
            print(f"{filename}: {status}")
        else:
            print(f"{filename}: NOT FOUND")

if __name__ == '__main__':
    main()
