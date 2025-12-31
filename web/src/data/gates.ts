// Gate positions for Weltendaemmerung Torphase
// Data extracted from docs/torphase.md

import { Coord, Player } from '../types';

export interface GatePosition {
  index: number;
  pos: Coord;
  territory: Player;
}

// Territory boundary: X < 60 = Eldoin, X >= 60 = Dailor
export const TERRITORY_BOUNDARY_X = 60;

// 13 fixed gate positions on the map
// Players can only build/modify gates at these specific locations
export const GATE_POSITIONS: GatePosition[] = [
  // Eldoin territory (X < 60) - 10 gates
  { index: 0,  pos: { x: 5,  y: 6 },  territory: Player.Eldoin },
  { index: 1,  pos: { x: 17, y: 5 },  territory: Player.Eldoin },
  { index: 2,  pos: { x: 29, y: 10 }, territory: Player.Eldoin },
  { index: 3,  pos: { x: 14, y: 21 }, territory: Player.Eldoin },
  { index: 4,  pos: { x: 42, y: 21 }, territory: Player.Eldoin },
  { index: 5,  pos: { x: 47, y: 21 }, territory: Player.Eldoin },
  { index: 6,  pos: { x: 52, y: 21 }, territory: Player.Eldoin },
  { index: 7,  pos: { x: 25, y: 25 }, territory: Player.Eldoin },
  { index: 8,  pos: { x: 5,  y: 35 }, territory: Player.Eldoin },
  { index: 9,  pos: { x: 11, y: 34 }, territory: Player.Eldoin },

  // Dailor territory (X >= 60) - 3 gates
  { index: 10, pos: { x: 70, y: 7 },  territory: Player.Dailor },
  { index: 11, pos: { x: 69, y: 17 }, territory: Player.Dailor },
  { index: 12, pos: { x: 75, y: 34 }, territory: Player.Dailor },
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
