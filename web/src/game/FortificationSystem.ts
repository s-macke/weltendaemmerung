// Fortification system for Weltendaemmerung (Torphase)
// Handles gate building and wall construction

import { TerrainType, Coord, Player } from '../types';
import { GameState, GateState } from './GameState';
import {
  GATE_POSITIONS,
  TERRITORY_BOUNDARY_X,
  findGateAt,
  isInTerritory,
} from '../data/gates';

/**
 * Check if a player can perform torphase at given coordinates.
 * Requirements:
 * 1. Position must be one of the 13 gate positions
 * 2. Position must be in the player's territory
 * 3. Gate must not be destroyed
 */
export function canPerformTorphase(
  state: GameState,
  pos: Coord,
  player: Player
): boolean {
  // Find gate at position
  const gate = findGateAt(pos);
  if (!gate) {
    return false;
  }

  // Check territory
  if (!isInTerritory(pos.x, player)) {
    return false;
  }

  // Check if gate was destroyed
  if (state.isGateDestroyed(gate.index)) {
    return false;
  }

  return true;
}

/**
 * Perform torphase action at given coordinates.
 *
 * Logic:
 * - If current terrain is Gate:
 *   - Eldoin converts Gate → Wall
 *   - Dailor converts Gate → Meadow
 * - If current terrain is not Gate (Meadow, Pavement, etc.):
 *   - Either player places a new Gate
 *
 * @returns true if action was performed
 */
export function performTorphase(
  state: GameState,
  pos: Coord
): boolean {
  if (!canPerformTorphase(state, pos, state.currentPlayer)) {
    return false;
  }

  const gate = findGateAt(pos);
  if (!gate) {
    return false;
  }

  const currentTerrain = state.getTerrainAt(pos);

  if (currentTerrain === TerrainType.Gate) {
    // Convert existing gate
    if (state.currentPlayer === Player.Eldoin) {
      // Eldoin: Gate → Pavement (opens gate)
      state.setGateState(gate.index, GateState.Pavement);
    } else {
      // Dailor: Gate → Meadow
      state.setGateState(gate.index, GateState.Meadow);
    }
  } else {
    // Place new gate (terrain becomes Gate)
    state.setGateState(gate.index, GateState.Original);
  }

  return true;
}

/**
 * Get all valid torphase positions for the current player.
 */
export function getValidTorphasePositions(state: GameState): Coord[] {
  return GATE_POSITIONS.filter((gate) =>
    canPerformTorphase(state, gate.pos, state.currentPlayer)
  ).map((gate) => gate.pos);
}

/**
 * Get the state description of a gate position.
 */
export function getGateDescription(
  state: GameState,
  pos: Coord
): string {
  const gate = findGateAt(pos);
  if (!gate) {
    return 'Not a gate position';
  }

  const gateState = state.getGateState(gate.index);

  switch (gateState) {
    case GateState.Original:
      return 'Gate';
    case GateState.Pavement:
      return 'Pavement (opened)';
    case GateState.Meadow:
      return 'Meadow (cleared)';
    case GateState.Destroyed:
      return 'Destroyed';
    default:
      return 'Unknown';
  }
}

/**
 * Check if a position is in Eldoin's territory (X < 60).
 */
export function isEldoinTerritory(x: number): boolean {
  return x < TERRITORY_BOUNDARY_X;
}

/**
 * Check if a position is in Dailor's territory (X >= 60).
 */
export function isDailorTerritory(x: number): boolean {
  return x >= TERRITORY_BOUNDARY_X;
}