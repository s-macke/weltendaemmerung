// Movement system for Weltendaemmerung
// Handles movement validation and terrain costs

import { TerrainType, Unit, Coord } from '../types';
import { GameState } from './GameState';
import { getTerrainCost, canEnterTerrain } from '../data/terrain';
import { UNIT_STATS } from '../data/units';

/**
 * Check if a unit can move to a target position.
 * @returns true if movement is valid
 */
export function canMoveTo(
  state: GameState,
  unit: Unit,
  target: Coord
): boolean {
  // Unit must be alive
  if (!state.isUnitAlive(unit)) {
    return false;
  }

  // Unit must have movement points remaining
  if (unit.movement <= 0) {
    return false;
  }

  // Target must be orthogonally adjacent (no diagonal movement)
  const dx = Math.abs(target.x - unit.x);
  const dy = Math.abs(target.y - unit.y);
  // Only allow movement in 4 cardinal directions: (1,0), (0,1), (-1,0), (0,-1)
  if (!((dx === 1 && dy === 0) || (dx === 0 && dy === 1))) {
    return false;
  }

  // Get terrain at target
  const terrain = state.getTerrainAt(target);

  // Check if unit can enter this terrain type
  if (!canEnterTerrain(unit.type, terrain)) {
    return false;
  }

  // Get unit stats to check flying ability
  const stats = UNIT_STATS[unit.type]!;

  // Flying units (Eagle, Bloodsucker) can pass through mountains and gates
  // They are only blocked by other units (collision check below)
  if (!stats.isFlying) {
    // Non-flying units: blocked by Mountains, Gates, Walls, End
    if (
      terrain === TerrainType.Mountains ||
      terrain === TerrainType.Gate ||
      terrain === TerrainType.Wall ||
      terrain === TerrainType.End
    ) {
      return false;
    }
  }

  // Check if target is occupied
  const occupant = state.getUnitAt(target);
  if (occupant) {
    return false;
  }

  // Check if unit has enough movement points
  const cost = getMovementCost(unit, terrain);
  if (cost > unit.movement) {
    return false;
  }

  return true;
}

/**
 * Get the movement cost for a unit to enter a terrain type.
 */
export function getMovementCost(unit: Unit, terrain: TerrainType): number {
  return getTerrainCost(unit.type, terrain);
}

/**
 * Execute a movement from current position to target.
 * @returns true if movement was successful
 */
export function moveUnit(
  state: GameState,
  unit: Unit,
  target: Coord
): boolean {
  if (!canMoveTo(state, unit, target)) {
    return false;
  }

  const terrain = state.getTerrainAt(target);
  const cost = getMovementCost(unit, terrain);

  // Deduct movement points
  unit.movement -= cost;

  // Update position
  unit.x = target.x;
  unit.y = target.y;

  return true;
}

/**
 * Get all valid movement targets for a unit.
 * Returns orthogonally adjacent tiles the unit can move to (4 directions only).
 */
export function getValidMoveTargets(state: GameState, unit: Unit): Coord[] {
  const targets: Coord[] = [];

  // Check only 4 orthogonal directions (no diagonal movement)
  const directions = [
    { dx: 0, dy: -1 }, // up
    { dx: 0, dy: 1 },  // down
    { dx: -1, dy: 0 }, // left
    { dx: 1, dy: 0 },  // right
  ];

  for (const { dx, dy } of directions) {
    const target: Coord = { x: unit.x + dx, y: unit.y + dy };
    if (canMoveTo(state, unit, target)) {
      targets.push(target);
    }
  }

  return targets;
}

/**
 * Check if a unit has any valid moves remaining.
 */
export function hasValidMoves(state: GameState, unit: Unit): boolean {
  if (!state.isUnitAlive(unit) || unit.movement <= 0) {
    return false;
  }

  return getValidMoveTargets(state, unit).length > 0;
}

/**
 * Get terrain info string for display.
 */
export function getTerrainName(terrain: TerrainType): string {
  switch (terrain) {
    case TerrainType.Meadow:
      return 'Meadow';
    case TerrainType.River:
      return 'River';
    case TerrainType.Forest:
      return 'Forest';
    case TerrainType.End:
      return 'Edge';
    case TerrainType.Swamp:
      return 'Swamp';
    case TerrainType.Gate:
      return 'Gate';
    case TerrainType.Mountains:
      return 'Mountains';
    case TerrainType.Pavement:
      return 'Pavement';
    case TerrainType.Wall:
      return 'Wall';
  }
}

/**
 * Get unit type info for display.
 */
export function getUnitInfo(unit: Unit): {
  name: string;
  range: number;
  movement: number;
  attack: number;
  defense: number;
} {
  const stats = UNIT_STATS[unit.type]!;
  return {
    name: stats.name,
    range: stats.range,
    movement: unit.movement,
    attack: stats.attack,
    defense: unit.defense,
  };
}