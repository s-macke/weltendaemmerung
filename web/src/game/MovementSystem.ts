// Movement system for Weltendaemmerung
// Handles movement validation and terrain costs

import { TerrainType, Unit, Coord } from '../types';
import { GameState } from './GameState';
import { getTerrainCost, canEnterTerrain } from '../data/terrain';
import { UNIT_STATS } from '../data/units';

/**
 * Represents a reachable position with path information.
 */
export interface ReachablePosition {
  coord: Coord;
  cost: number;
  path: Coord[];  // Path from unit to this tile (for path preview & execution)
}

/**
 * Simple priority queue implementation for Dijkstra's algorithm.
 */
class PriorityQueue<T> {
  private items: { item: T; priority: number }[] = [];

  push(item: T, priority: number): void {
    this.items.push({ item, priority });
    this.items.sort((a, b) => a.priority - b.priority);
  }

  pop(): T | undefined {
    return this.items.shift()?.item;
  }

  isEmpty(): boolean {
    return this.items.length === 0;
  }
}

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

/**
 * Check if a unit can pass through a position (for pathfinding).
 * Unlike canMoveTo, this checks if unit can traverse a tile, not just move to adjacent.
 */
function canPassThrough(
  state: GameState,
  unit: Unit,
  pos: Coord
): boolean {
  // Check map bounds
  if (pos.x < 0 || pos.x >= 80 || pos.y < 0 || pos.y >= 40) {
    return false;
  }

  const terrain = state.getTerrainAt(pos);

  // Check if unit can enter this terrain type
  if (!canEnterTerrain(unit.type, terrain)) {
    return false;
  }

  // Get unit stats to check flying ability
  const stats = UNIT_STATS[unit.type]!;

  // Flying units can pass through mountains and gates
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

  // Check if position is occupied by another unit
  const occupant = state.getUnitAt(pos);
  if (occupant && occupant !== unit) {
    return false;
  }

  return true;
}

/**
 * Get all positions reachable by a unit within its remaining movement points.
 * Uses Dijkstra's algorithm to find optimal paths to all reachable tiles.
 *
 * @param state Current game state
 * @param unit The unit to check movement for
 * @returns Map of coordinate string keys to ReachablePosition objects
 */
export function getAllReachablePositions(
  state: GameState,
  unit: Unit
): Map<string, ReachablePosition> {
  const result = new Map<string, ReachablePosition>();

  // Unit must be alive and have movement points
  if (!state.isUnitAlive(unit) || unit.movement <= 0) {
    return result;
  }

  const directions = [
    { dx: 0, dy: -1 },  // up
    { dx: 0, dy: 1 },   // down
    { dx: -1, dy: 0 },  // left
    { dx: 1, dy: 0 },   // right
  ];

  // Priority queue ordered by cost (Dijkstra's algorithm)
  const queue = new PriorityQueue<{ pos: Coord; cost: number; path: Coord[] }>();

  // Start at unit position with cost 0
  queue.push({ pos: { x: unit.x, y: unit.y }, cost: 0, path: [] }, 0);

  // Track best cost to reach each position
  const visited = new Map<string, number>();

  while (!queue.isEmpty()) {
    const current = queue.pop()!;
    const key = `${current.pos.x},${current.pos.y}`;

    // Skip if we've already found a better path to this position
    if (visited.has(key) && visited.get(key)! <= current.cost) {
      continue;
    }

    visited.set(key, current.cost);

    // Add to result (except starting position)
    if (current.cost > 0) {
      result.set(key, {
        coord: current.pos,
        cost: current.cost,
        path: current.path,
      });
    }

    // Explore neighbors
    for (const { dx, dy } of directions) {
      const neighbor: Coord = { x: current.pos.x + dx, y: current.pos.y + dy };
      const neighborKey = `${neighbor.x},${neighbor.y}`;

      // Skip if already visited with better cost
      if (visited.has(neighborKey)) {
        continue;
      }

      // Check if unit can pass through this position
      if (!canPassThrough(state, unit, neighbor)) {
        continue;
      }

      // Calculate terrain cost
      const terrain = state.getTerrainAt(neighbor);
      const terrainCost = getTerrainCost(unit.type, terrain);

      // Skip if impassable (cost 0)
      if (terrainCost <= 0) {
        continue;
      }

      const newCost = current.cost + terrainCost;

      // Skip if exceeds movement points
      if (newCost > unit.movement) {
        continue;
      }

      // Add to queue with new path
      const newPath = [...current.path, neighbor];
      queue.push({ pos: neighbor, cost: newCost, path: newPath }, newCost);
    }
  }

  return result;
}

/**
 * Execute a multi-step movement path for a unit.
 * Moves the unit along the path, deducting movement costs.
 *
 * @param state Current game state
 * @param unit The unit to move
 * @param path Array of coordinates to move through
 * @returns true if movement was successful
 */
export function executeMovementPath(
  state: GameState,
  unit: Unit,
  path: Coord[]
): boolean {
  if (path.length === 0) {
    return false;
  }

  // Execute each step in the path
  for (const target of path) {
    if (!moveUnit(state, unit, target)) {
      // Movement failed - unit stops where it is
      return false;
    }
  }

  return true;
}