// Unit statistics table for Weltendaemmerung
// Data extracted from docs/units.md

import { Player } from '../types';

export interface UnitStats {
  type: number;
  name: string;
  range: number;      // Attack range
  movement: number;   // Movement points
  attack: number;     // Attack power
  defense: number;    // Initial defense
  owner: Player;
  tileCode: number;   // Character code for rendering ($74-$83)
  canAttackStructures: boolean;  // Can destroy gates/walls
  canAttackGatesOnly: boolean;   // Battering Ram: only gates, not walls
  isFlying: boolean;  // Eagle, Bloodsucker: terrain cost always 1
  isWaterOnly: boolean; // Warship: can only move on river
}

// Unit statistics indexed by type (0-15)
export const UNIT_STATS: UnitStats[] = [
  // Eldoin units (types 0-6)
  {
    type: 0,
    name: 'Sword Bearers',
    range: 1,
    movement: 10,
    attack: 4,
    defense: 16,
    owner: Player.Eldoin,
    tileCode: 0x74,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 1,
    name: 'Archers',
    range: 8,
    movement: 10,
    attack: 5,
    defense: 12,
    owner: Player.Eldoin,
    tileCode: 0x75,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 2,
    name: 'Eagle',
    range: 2,
    movement: 12,
    attack: 7,
    defense: 11,
    owner: Player.Eldoin,
    tileCode: 0x76,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: true,
    isWaterOnly: false,
  },
  {
    type: 3,
    name: 'Spear Bearers',
    range: 2,
    movement: 10,
    attack: 5,
    defense: 14,
    owner: Player.Eldoin,
    tileCode: 0x77,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 4,
    name: 'Warship',
    range: 8,
    movement: 8,
    attack: 20,
    defense: 18,
    owner: Player.Eldoin,
    tileCode: 0x78,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: true,
  },
  {
    type: 5,
    name: 'Cavalry',
    range: 5,
    movement: 15,
    attack: 6,
    defense: 10,
    owner: Player.Eldoin,
    tileCode: 0x79,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 6,
    name: 'Commander',
    range: 1,
    movement: 10,
    attack: 6,
    defense: 16,
    owner: Player.Eldoin,
    tileCode: 0x7A,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
    // VICTORY UNIT: Destroying this unit wins the game for Dailor
  },

  // Dailor units (types 7-15)
  {
    type: 7,
    name: 'Archers',
    range: 8,
    movement: 10,
    attack: 5,
    defense: 12,
    owner: Player.Dailor,
    tileCode: 0x7B,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 8,
    name: 'Catapult',
    range: 12,
    movement: 9,
    attack: 1,
    defense: 5,
    owner: Player.Dailor,
    tileCode: 0x7C,
    canAttackStructures: true,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 9,
    name: 'Bloodsucker',
    range: 1,
    movement: 12,
    attack: 8,
    defense: 10,
    owner: Player.Dailor,
    tileCode: 0x7D,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: true,
    isWaterOnly: false,
  },
  {
    type: 10,
    name: 'Axe Men',
    range: 1,
    movement: 10,
    attack: 4,
    defense: 16,
    owner: Player.Dailor,
    tileCode: 0x7E,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 11,
    name: 'Commander',
    range: 1,
    movement: 10,
    attack: 6,
    defense: 16,
    owner: Player.Dailor,
    tileCode: 0x7F,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 12,
    name: 'Dragon',
    range: 2,
    movement: 10,
    attack: 30,
    defense: 30,
    owner: Player.Dailor,
    tileCode: 0x80,
    canAttackStructures: true,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
    // Strongest unit in the game
  },
  {
    type: 13,
    name: 'Battering Ram',
    range: 1,
    movement: 10,
    attack: 1,
    defense: 5,
    owner: Player.Dailor,
    tileCode: 0x81,
    canAttackStructures: true,
    canAttackGatesOnly: true,
    isFlying: false,
    isWaterOnly: false,
  },
  {
    type: 14,
    name: 'Wagon Drivers',
    range: 7,
    movement: 14,
    attack: 10,
    defense: 16,
    owner: Player.Dailor,
    tileCode: 0x82,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
    // High forest/swamp cost (7) - slow in difficult terrain
  },
  {
    type: 15,
    name: 'Wolf Riders',
    range: 3,
    movement: 12,
    attack: 8,
    defense: 18,
    owner: Player.Dailor,
    tileCode: 0x83,
    canAttackStructures: false,
    canAttackGatesOnly: false,
    isFlying: false,
    isWaterOnly: false,
  },
];

// Eldoin's Commander type (victory condition)
export const ELDOIN_COMMANDER_TYPE = 6;

// Get unit stats by type
export function getUnitStats(type: number): UnitStats {
  return UNIT_STATS[type]!;
}

// Check if unit belongs to player
export function isOwnedBy(unitType: number, player: Player): boolean {
  return UNIT_STATS[unitType]!.owner === player;
}
