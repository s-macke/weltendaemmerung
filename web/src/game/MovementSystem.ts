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

  // Target must be adjacent (1 tile away)
  const dx = Math.abs(target.x - unit.x);
  const dy = Math.abs(target.y - unit.y);
  if (dx > 1 || dy > 1 || (dx === 0 && dy === 0)) {
    return false;
  }

  // Get terrain at target
  const terrain = state.getTerrainAt(target);

  // Check if unit can enter this terrain type
  if (!canEnterTerrain(unit.type, terrain)) {
    return false;
  }

  // Check blocking terrain (Mountains, Walls, End)
  if (
    terrain === TerrainType.Mountains ||
    terrain === TerrainType.Wall ||
    terrain === TerrainType.End
  ) {
    return false;
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
 * Returns adjacent tiles the unit can move to.
 */
export function getValidMoveTargets(state: GameState, unit: Unit): Coord[] {
  const targets: Coord[] = [];

  // Check all 8 adjacent tiles
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) {
      if (dx === 0 && dy === 0) continue;

      const target: Coord = { x: unit.x + dx, y: unit.y + dy };
      if (canMoveTo(state, unit, target)) {
        targets.push(target);
      }
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