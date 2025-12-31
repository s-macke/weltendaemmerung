// Terrain movement cost tables for Weltendaemmerung
// Data extracted from docs/movement.md

import { TerrainType } from '../types';
import { UNIT_STATS } from './units';

// River costs per unit type (terrain $6B)
// Index 0-15 corresponds to unit types 0-15
const RIVER_COSTS: number[] = [
  4,  // 0: Sword Bearers
  4,  // 1: Archers (Eldoin)
  1,  // 2: Eagle (flying)
  4,  // 3: Spear Bearers
  1,  // 4: Warship (water unit)
  4,  // 5: Cavalry
  4,  // 6: Commander (Eldoin)
  2,  // 7: Archers (Dailor)
  4,  // 8: Catapult
  1,  // 9: Bloodsucker (flying)
  2,  // 10: Axe Men
  2,  // 11: Commander (Dailor)
  4,  // 12: Dragon
  4,  // 13: Battering Ram
  5,  // 14: Wagon Drivers
  2,  // 15: Wolf Riders
];

// Forest costs per unit type (terrain $6C)
// 0 = impassable for that unit type
const FOREST_COSTS: number[] = [
  2,  // 0: Sword Bearers
  2,  // 1: Archers (Eldoin)
  1,  // 2: Eagle (flying)
  3,  // 3: Spear Bearers
  0,  // 4: Warship (water only - cannot enter)
  4,  // 5: Cavalry
  2,  // 6: Commander (Eldoin)
  2,  // 7: Archers (Dailor)
  4,  // 8: Catapult
  1,  // 9: Bloodsucker (flying)
  2,  // 10: Axe Men
  2,  // 11: Commander (Dailor)
  1,  // 12: Dragon
  3,  // 13: Battering Ram
  7,  // 14: Wagon Drivers (slow in difficult terrain)
  2,  // 15: Wolf Riders
];

// Swamp costs per unit type (terrain $6E)
// 0 = impassable for that unit type
const SWAMP_COSTS: number[] = [
  3,  // 0: Sword Bearers
  3,  // 1: Archers (Eldoin)
  1,  // 2: Eagle (flying)
  3,  // 3: Spear Bearers
  0,  // 4: Warship (water only - cannot enter)
  4,  // 5: Cavalry
  3,  // 6: Commander (Eldoin)
  3,  // 7: Archers (Dailor)
  4,  // 8: Catapult
  1,  // 9: Bloodsucker (flying)
  3,  // 10: Axe Men
  3,  // 11: Commander (Dailor)
  1,  // 12: Dragon
  4,  // 13: Battering Ram
  7,  // 14: Wagon Drivers (slow in difficult terrain)
  4,  // 15: Wolf Riders
];

// Default terrain cost (for Meadow, Gate, Mountains, Pavement, Wall)
const DEFAULT_COST = 1;

/**
 * Get movement cost for a unit to enter a terrain type.
 * @param unitType Unit type (0-15)
 * @param terrain Target terrain type
 * @returns Movement cost, or 0 if impassable
 */
export function getTerrainCost(unitType: number, terrain: TerrainType): number {
  const stats = UNIT_STATS[unitType]!;

  // Flying units (Eagle, Bloodsucker) always cost 1
  if (stats.isFlying) {
    return 1;
  }

  // Warship can only move on river
  if (stats.isWaterOnly) {
    return terrain === TerrainType.River ? 1 : 0;
  }

  switch (terrain) {
    case TerrainType.River:
      return RIVER_COSTS[unitType]!;
    case TerrainType.Forest:
      return FOREST_COSTS[unitType]!;
    case TerrainType.Swamp:
      return SWAMP_COSTS[unitType]!;
    case TerrainType.End:
      return 0; // Map boundary - impassable
    case TerrainType.Meadow:
    case TerrainType.Gate:
    case TerrainType.Mountains:
    case TerrainType.Pavement:
    case TerrainType.Wall:
    default:
      return DEFAULT_COST;
  }
}

/**
 * Check if a unit can enter a terrain type.
 * @param unitType Unit type (0-15)
 * @param terrain Target terrain type
 * @returns true if unit can enter, false otherwise
 */
export function canEnterTerrain(unitType: number, terrain: TerrainType): boolean {
  return getTerrainCost(unitType, terrain) > 0;
}

// Export raw cost tables for testing/debugging
export const TERRAIN_COST_TABLES = {
  river: RIVER_COSTS,
  forest: FOREST_COSTS,
  swamp: SWAMP_COSTS,
};
