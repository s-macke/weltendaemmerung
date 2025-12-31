// Combat system for Weltendaemmerung
// Handles attack range, damage calculation, and combat resolution

import { TerrainType, Unit, Coord } from '../types';
import { GameState, GateState } from './GameState';
import { UNIT_STATS } from '../data/units';
import { GATE_POSITIONS } from '../data/gates';
import { checkVictory } from './VictoryChecker';

/**
 * Check if an attacker can attack a target unit (Euclidean distance).
 */
export function isInRange(attacker: Unit, target: Unit): boolean {
  const stats = UNIT_STATS[attacker.type]!;
  const dx = target.x - attacker.x;
  const dy = target.y - attacker.y;
  return Math.sqrt(dx * dx + dy * dy) <= stats.range;
}

/**
 * Check if a position is within range of an attacker.
 */
export function isPositionInRange(attacker: Unit, pos: Coord): boolean {
  const stats = UNIT_STATS[attacker.type]!;
  const dx = pos.x - attacker.x;
  const dy = pos.y - attacker.y;
  return Math.sqrt(dx * dx + dy * dy) <= stats.range;
}

/**
 * Check if an attacker can attack a target.
 * @returns true if attack is valid
 */
export function canAttack(
  state: GameState,
  attacker: Unit,
  target: Unit
): boolean {
  // Attacker must be alive
  if (!state.isUnitAlive(attacker)) {
    return false;
  }

  // Target must be alive
  if (!state.isUnitAlive(target)) {
    return false;
  }

  // Cannot attack own units
  if (attacker.owner === target.owner) {
    return false;
  }

  // Must be in range
  if (!isInRange(attacker, target)) {
    return false;
  }

  return true;
}

/**
 * Check if an attacker can attack a structure (gate/wall) at position.
 */
export function canAttackStructure(
  state: GameState,
  attacker: Unit,
  pos: Coord
): boolean {
  // Attacker must be alive
  if (!state.isUnitAlive(attacker)) {
    return false;
  }

  // Get attacker stats
  const stats = UNIT_STATS[attacker.type]!;

  // Only certain units can attack structures
  if (!stats.canAttackStructures) {
    return false;
  }

  // Get terrain at position
  const terrain = state.getTerrainAt(pos);

  // Battering Ram can only attack gates, not walls
  if (stats.canAttackGatesOnly && terrain !== TerrainType.Gate) {
    return false;
  }

  // Must be a gate or wall
  if (terrain !== TerrainType.Gate && terrain !== TerrainType.Wall) {
    return false;
  }

  // Must be in range
  if (!isPositionInRange(attacker, pos)) {
    return false;
  }

  return true;
}

/**
 * Calculate damage for an attack.
 * Damage = base attack + random modifier (0-4).
 * Distribution: 0(12.5%), 1(25%), 2(25%), 3(25%), 4(12.5%)
 */
export function calculateDamage(attackerType: number): number {
  const stats = UNIT_STATS[attackerType]!;
  const baseAttack = stats.attack;

  // Weighted distribution for modifier
  const modifierTable = [0, 1, 1, 2, 2, 3, 3, 4];
  const modifier = modifierTable[Math.floor(Math.random() * 8)]!;

  return baseAttack + modifier;
}

/**
 * Apply damage to a target unit.
 * @returns true if the unit was destroyed
 */
export function applyDamage(
  state: GameState,
  target: Unit,
  damage: number
): boolean {
  target.defense -= damage;

  if (target.defense <= 0) {
    state.destroyUnit(target);

    // Check victory condition (Commander destroyed or all Dailor units destroyed)
    const winner = checkVictory(state);
    if (winner !== null) {
      state.winner = winner;
    }

    return true;
  }

  return false;
}

/**
 * Execute an attack on a target unit.
 * @returns Object with damage dealt and whether target was destroyed
 */
export function attackUnit(
  state: GameState,
  attacker: Unit,
  target: Unit
): { damage: number; destroyed: boolean } {
  if (!canAttack(state, attacker, target)) {
    return { damage: 0, destroyed: false };
  }

  const damage = calculateDamage(attacker.type);
  const destroyed = applyDamage(state, target, damage);

  return { damage, destroyed };
}

/**
 * Execute an attack on a structure (gate/wall).
 * When destroyed, structures become Pavement.
 * @returns true if structure was destroyed
 */
export function attackStructure(
  state: GameState,
  attacker: Unit,
  pos: Coord
): boolean {
  if (!canAttackStructure(state, attacker, pos)) {
    return false;
  }

  // Find gate index at this position
  const gateIndex = GATE_POSITIONS.findIndex(
    (g) => g.pos.x === pos.x && g.pos.y === pos.y
  );

  if (gateIndex !== -1) {
    // Mark gate as destroyed (becomes Pavement)
    state.setGateState(gateIndex, GateState.Destroyed);
    return true;
  }

  return false;
}

/**
 * Get all valid attack targets for a unit (enemy units in range).
 */
export function getValidAttackTargets(state: GameState, unit: Unit): Unit[] {
  if (!state.isUnitAlive(unit)) {
    return [];
  }

  return state.units.filter((target) => canAttack(state, unit, target));
}

/**
 * Get all valid structure targets for a unit (gates/walls in range).
 */
export function getValidStructureTargets(
  state: GameState,
  unit: Unit
): Coord[] {
  if (!state.isUnitAlive(unit)) {
    return [];
  }

  const stats = UNIT_STATS[unit.type]!;
  if (!stats.canAttackStructures) {
    return [];
  }

  const targets: Coord[] = [];
  const range = stats.range;

  // Check all positions within range
  for (let dy = -range; dy <= range; dy++) {
    for (let dx = -range; dx <= range; dx++) {
      const pos: Coord = { x: unit.x + dx, y: unit.y + dy };
      if (canAttackStructure(state, unit, pos)) {
        targets.push(pos);
      }
    }
  }

  return targets;
}