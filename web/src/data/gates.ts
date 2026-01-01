// Gate positions for Weltendaemmerung Torphase
// Data extracted from docs/torphase.md

import { Coord, Player } from '../types';

export interface GatePosition {
  index: number;
  pos: Coord;
  territory: Player;
}

// Territory boundary (0-indexed): X < 59 = Eldoin, X >= 59 = Dailor
// Note: C64 uses 1-indexed cursor coords (boundary at 60)
export const TERRITORY_BOUNDARY_X = 59;

// 13 fixed gate positions on the map (0-indexed coordinates)
// Note: C64 uses 1-indexed cursor coords, converted here for array access
// Players can only build/modify gates at these specific locations
export const GATE_POSITIONS: GatePosition[] = [
  // Eldoin territory (X < 59) - 10 gates
  { index: 0,  pos: { x: 4,  y: 5 },  territory: Player.Eldoin },
  { index: 1,  pos: { x: 16, y: 4 },  territory: Player.Eldoin },
  { index: 2,  pos: { x: 28, y: 9 },  territory: Player.Eldoin },
  { index: 3,  pos: { x: 13, y: 20 }, territory: Player.Eldoin },
  { index: 4,  pos: { x: 41, y: 20 }, territory: Player.Eldoin },
  { index: 5,  pos: { x: 46, y: 20 }, territory: Player.Eldoin },
  { index: 6,  pos: { x: 51, y: 20 }, territory: Player.Eldoin },
  { index: 7,  pos: { x: 24, y: 24 }, territory: Player.Eldoin },
  { index: 8,  pos: { x: 4,  y: 34 }, territory: Player.Eldoin },
  { index: 9,  pos: { x: 10, y: 33 }, territory: Player.Eldoin },

  // Dailor territory (X >= 59) - 3 gates
  { index: 10, pos: { x: 69, y: 6 },  territory: Player.Dailor },
  { index: 11, pos: { x: 68, y: 16 }, territory: Player.Dailor },
  { index: 12, pos: { x: 74, y: 33 }, territory: Player.Dailor },
];

// Total gate counts per territory
export const ELDOIN_GATE_COUNT = 10;
export const DAILOR_GATE_COUNT = 3;

/**
 * Find gate position at given coordinates.
 * @returns Gate position or undefined if not a gate location
 */
export function findGateAt(pos: Coord): GatePosition | undefined {
  return GATE_POSITIONS.find(gate => gate.pos.x === pos.x && gate.pos.y === pos.y);
}

/**
 * Check if coordinates are a valid gate position.
 */
export function isGatePosition(pos: Coord): boolean {
  return findGateAt(pos) !== undefined;
}

/**
 * Check if a position is in a player's territory.
 */
export function isInTerritory(x: number, player: Player): boolean {
  if (player === Player.Eldoin) {
    return x < TERRITORY_BOUNDARY_X;
  } else {
    return x >= TERRITORY_BOUNDARY_X;
  }
}

/**
 * Check if a player can perform torphase at given coordinates.
 * Requirements:
 * 1. Position must be one of the 13 gate positions
 * 2. Position must be in the player's territory
 */
export function canPerformTorphase(
  pos: Coord,
  player: Player,
  gateFlags: boolean[]
): boolean {
  const gate = findGateAt(pos);
  if (!gate) return false;

  // Check territory
  if (!isInTerritory(pos.x, player)) return false;

  // Check if gate was destroyed (permanently disabled)
  if (gateFlags[gate.index]) return false;

  return true;
}

/**
 * Get all gate positions in a player's territory.
 */
export function getGatesInTerritory(player: Player): GatePosition[] {
  return GATE_POSITIONS.filter(gate => gate.territory === player);
}
