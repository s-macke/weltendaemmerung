// C64 Color Palette
// Full 16-color C64 palette with hex values

export const C64_COLORS = {
  black:      '#000000',  // $00 - Dailor units, meadow pattern
  white:      '#FFFFFF',  // $01 - End markers, cursor
  red:        '#683B2B',  // $02 - Forest
  cyan:       '#70A4B2',  // $03
  purple:     '#6F3D86',  // $04 - Title screen menu
  green:      '#588D43',  // $05 - Map background
  blue:       '#352879',  // $06 - Border, river, swamp
  yellow:     '#B8C76F',  // $07 - Eldoin units
  orange:     '#6F4F25',  // $08
  brown:      '#433900',  // $09
  lightRed:   '#9A6759',  // $0A - Attack mode cursor
  darkGray:   '#444444',  // $0B - UI elements, walls, gates
  gray:       '#6C6C6C',  // $0C
  lightGreen: '#9AD284',  // $0D
  lightBlue:  '#6C5EB5',  // $0E - Title screen text
  lightGray:  '#959595',  // $0F
} as const;

// Indexed array for direct C64 color index lookup
export const C64_PALETTE: readonly string[] = [
  C64_COLORS.black,      // 0
  C64_COLORS.white,      // 1
  C64_COLORS.red,        // 2
  C64_COLORS.cyan,       // 3
  C64_COLORS.purple,     // 4
  C64_COLORS.green,      // 5
  C64_COLORS.blue,       // 6
  C64_COLORS.yellow,     // 7
  C64_COLORS.orange,     // 8
  C64_COLORS.brown,      // 9
  C64_COLORS.lightRed,   // 10
  C64_COLORS.darkGray,   // 11
  C64_COLORS.gray,       // 12
  C64_COLORS.lightGreen, // 13
  C64_COLORS.lightBlue,  // 14
  C64_COLORS.lightGray,  // 15
] as const;

// Get tile foreground color based on character code
export function getTileColor(charCode: number): string {
  if (charCode < 0x69) return C64_COLORS.darkGray;  // UI elements
  if (charCode === 0x69 || charCode === 0x6A) return C64_COLORS.black;   // Meadow
  if (charCode === 0x6B) return C64_COLORS.blue;    // River
  if (charCode === 0x6C) return C64_COLORS.red;     // Forest
  if (charCode === 0x6D) return C64_COLORS.white;   // End
  if (charCode === 0x6E) return C64_COLORS.blue;    // Swamp
  if (charCode >= 0x6F && charCode <= 0x73) return C64_COLORS.darkGray; // Structures
  if (charCode >= 0x74 && charCode <= 0x7A) return C64_COLORS.yellow;   // Eldoin units
  return C64_COLORS.black;  // Dailor units ($7B+)
}