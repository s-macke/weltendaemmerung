// Auto-generated map data from Weltendaemmerung C64 binary
// DO NOT EDIT - regenerate with tools/extract_map_data.py

import { TerrainType } from '../types';

export const MAP_WIDTH = 80;
export const MAP_HEIGHT = 40;

// Compact map representation - each character represents one tile
// Terrain: M/m=Meadow, R=River, F=Forest, E=End, S=Swamp, G=Gate, X=Mountains, P=Pavement, W/w=Wall
// Frame elements: 1-8 (fortress walls, map to Wall for game logic)
const MAP_STRINGS: string[] = [
  "EXXP7PPPPPPPPPPPPPPPPP7XXXXRRRRRRRRRRSSSSSSFFFFFFFFFFFFFFFFFFFFFFFFFFFXXXXXXXXXE",
  "XXPP7PPPPPPPPPPPPPPPPP7XXXFFRRRRRRRRRRRRSSSSSFFFFFFFFFFFFFFFFFFFFFFFFXXXXXmmmmXX",
  "XPPP7PPPPPPPPPPPPPPPPP7XXmmFFFFRRRRRRRRRRRSSSSFFFFFFFFFFFFFFFFFFFFFFFXXXXmmmmmmX",
  "PPPP7PPPPPPPPPPPPPPPPP7mmmmmmFFFFFRRRRRRRRRSSSFFFFFFFFFFFFFFFFFFmmmFXXXXmmmmmmmm",
  "PPPP7PPPPPW55555G555554mmmmmmmFFFFFFRRRRRRRRSSSSFFFFFFFFFFFmFmmmmmmmXXXXmmmmmmmm",
  "PPPPGPPPPP7mmmmmmmmmmmmmmmmmmmmmFFFFSSRRRRRRSSSFFSFFFFFmmFFmmmmmmmmmmXXmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmmmmmmFFFFFSRRRRRRRSSSSSFFFFmmmmmmmmmmmmmmmGmmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmm16662FFFFSSRRRRRRRSSSSmFFmmmmmmmmmmmmmmmXXXmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmm8PPP7FFFSSSRRRRRRRSSSmmmmmmmmmmmmmmmmmmmXXXXmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmmGPPP7FFmmSSRRRRRRRRSSmmmmmmmmmmmmmmXmmmXXXXmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmm8PPP7mmmmmSSRRRRRRRSSmmmmmmmmmmmmmmXXXXXXXmmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmm35554mmmmSSSRRRRRRSSSSmmmSSmmmmmmmmmXmXXXXmmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmmmmmmmmmmmSSSRRRRRRSSSSSSSSSmmmmmmmmmmmXXXmmmmmmmmmmm",
  "PPPP7PPPPPw6666662mmmmmmmmmmmmmmmmmmmSSRRRRRRRRRSSSSSSmmmmmmmmmmmmmXXXmmmmmmmmmm",
  "PPPP7PPPPPPPPPPPP7mmmmmm62mmmmmmmmmmSSRRRRRmRRRRRSSSSmmmmmmmmmmmmmXXXXmmmmmmmmmm",
  "PPPP7PPPPPPPPPPPP7mmmmmmm7mmmmmmmmmmSSRRRRmmmRRRRSSSmmmmmmmmmmmmmmmXXXmmmmmmmmmm",
  "PPPPw662PPPPPPPPP7mmmmmmm7mmmmmmmmmmSSRRRmmmmmmRRSSmmmmmmmmmmmmmmmmmGmmmmmmmmmmX",
  "PPPPPPP7PPPPPW5554mmmmmmm7mmmmmmmmmmmmRRR166662RRRmmmmmmmmmmmmmmmmmmXXmmmmmmmmXX",
  "PPPPPPP7PPPPP7mmmmmmmmmmm7mmmmmmmmmmmRRRR8PPPP7RRRmmmmmmmmmmmmmmmmmXXmmmmmmmmmXX",
  "PPPPPPP7PPPPP7mmmmmmmmmm54mmmmmmmmmmmmRRR8PPPP7RRR62mmmmmmmmmmmmmmXXXmmmmmmmmmmX",
  "PPPPPPP7PPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPGPPPPGmmmmmmmmmmmmmmXXXmmmmmmmmmmm",
  "PPPPPPP7PPPPP7mmmmmmmmmmmmmmmmmmmmmmmRRRR8PPPP7RRR54mmmmmmmmmmmmmmmXXmmmmmmmmmmm",
  "PPPPPPP7PPPPP7mmmmmmmmmmmmmmmmmmmmmmRRRRR8PPPP7RRRmmmmmmmmmmmmmmmmXXXXmmmmmmmmmm",
  "PPPPPPP7PPPPPw6662mmmmmm1662mmmmmmmSRRRRR355554RRRRmmmmmmmmmmmmmmmXXXmmmmmmmmmmm",
  "PPPPW554PPPPPPPPP7mmmmmmGPP7mmmmmmSSRRRRRmmmmmmRRRRmmmmmmmmmmmmmmmmXXXmmmmmmmmmm",
  "PPPP7PPPPPPPPPPPP7mmmmmm8PP7mmmmmmSSSRRRRRmmmmmRRRmmmmmmmmmmmmmmmmmmXXmmmmmmmmmm",
  "PPPP7PPPPPPPPPPPP7mmmmmm3554mmmmmmmSSRRRRRRmmmRRRRmmmmFFFmmmmmmmmmmXXXXmmmmmmmmm",
  "PPPP7PPPPPW5555554mmmmmmmmmmmmmmmmmSSSSRRRRmmRRRRSmmmmmFFFFFmmmmmmXXXXXmmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmmmmmmmmmmSSSRRRRRmRRRRRSSmmmFFFFmmmmmXXXXXXXXmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmmmmmmm166662SSSRRRRRRRRRRRRRSSFFFFFFmmmXXmXXXXXXmmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmm62mmmm8mmmm7SSSRRRRRRRRRRRRRRRSFFFFFmmmmmmmXmXXXXmmmmmmm",
  "PPPP7PPPPP7mmmmmmmmmmmmmm7mmmmmmmmmSSSSSRRRRRRRRRRRRRRRRFFFmmmmmmmmmmmmXXmmmmXXX",
  "PPPP7PPPPP7mmmmmmmmmmmmmm7mmmmmmmmmmS62SSRRRRRRRSSSRRRRRFFFFmmmmmmmmmmmXXXmXXXXX",
  "PPPP7PPPPPGmmmmmmmmmmmmmm7mmmmmmm62mmm7SSRRRRRRRSSmmmRRRRRFFFmmmmmmmmmmmXXGXmXXX",
  "PPPPGPPPPP7mmmmmmmmmmmmF54mmmmmmmm7mmm7SSRRRRRRSSSmmmFRRRRFFFFmmmmmmmmmmXXmmmmXX",
  "PPPP7PPPPP7mmmmmmmmmmmFFFFFmmmmmmm7mm54SRRRRRRRSSSSFFFRRRRRFFFFmmmmmmmmXXmmmmmmX",
  "PPPP7PPPPPw666666666662FFFFFmmmmmm7mmmSSRRRRRRSSSSFFFFFRRRRFFFFmmmmmmmmmmmmmmmmm",
  "XPPP7PPPPPPPPPPPPPPPPP7FFFFFFFmmmm7mmmFSSSRRRRRRFFFFFFFFRRRRFFFFFmmmmmmmmmmmmmmX",
  "XXPP7PPPPPPPPPPPPPPPPP7FFFFFFFFFF54FmFFFSSRRRRRRRFFFFFFFRRRRFFFFFFmmmmmmmmmmmmXX",
  "EXXP7PPPPPPPPPPPPPPPPP7FFFFFFFFFFFFFFFFFFFRRRRRRRFFFFFFFRRRRRFFFFFFFmmmmmmmmmXXE",
];

// Character to C64 char code mapping
const CHAR_TO_CODE: Record<string, number> = {
  '1': 0x61, '2': 0x62, '3': 0x63, '4': 0x64, '5': 0x65, '6': 0x66, '7': 0x67, '8': 0x68, 'E': 0x6D, 'F': 0x6C, 'G': 0x6F, 'M': 0x69, 'P': 0x71, 'R': 0x6B, 'S': 0x6E, 'W': 0x72, 'X': 0x70, 'm': 0x6A, 'w': 0x73
};

// Character to terrain type mapping
const CHAR_TO_TERRAIN: Record<string, TerrainType> = {
  '1': TerrainType.Wall, '2': TerrainType.Wall, '3': TerrainType.Wall, '4': TerrainType.Wall, '5': TerrainType.Wall, '6': TerrainType.Wall, '7': TerrainType.Wall, '8': TerrainType.Wall, 'E': TerrainType.End, 'F': TerrainType.Forest, 'G': TerrainType.Gate, 'M': TerrainType.Meadow, 'P': TerrainType.Pavement, 'R': TerrainType.River, 'S': TerrainType.Swamp, 'W': TerrainType.Wall, 'X': TerrainType.Mountains, 'm': TerrainType.Meadow, 'w': TerrainType.Wall
};

// Get terrain at map coordinates
export function getTerrainAt(x: number, y: number): TerrainType {
  if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) {
    return TerrainType.End;
  }
  const char = MAP_STRINGS[y]![x]!;
  return CHAR_TO_TERRAIN[char] ?? TerrainType.End;
}

// Get raw char code at map coordinates (for rendering)
export function getCharCodeAt(x: number, y: number): number {
  if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) {
    return 0x6D; // End marker
  }
  const char = MAP_STRINGS[y]![x]!;
  return CHAR_TO_CODE[char] ?? 0x6D;
}
