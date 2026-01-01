// Victory condition checking for Weltendaemmerung
// Checks all three win conditions

import { Player } from '../types';
import { GameState } from './GameState';
import { ELDOIN_COMMANDER_TYPE } from '../data/units';

// Maximum number of turns before Eldoin wins
const MAX_TURNS = 15;

// Victory condition types
export type VictoryCondition = 'turnLimit' | 'commanderDestroyed' | 'annihilation';

// Victory result with winner and condition
export interface VictoryResult {
  winner: Player;
  condition: VictoryCondition;
}

/**
 * Check all victory conditions.
 *
 * Victory conditions:
 * 1. Turn Limit: Turn counter reaches 15 → Eldoin wins
 * 2. Commander Destroyed: Eldoin's Feldherr (type 6) destroyed → Dailor wins
 * 3. Total Annihilation: All Dailor units destroyed → Eldoin wins
 *
 * @returns VictoryResult with winner and condition, or null if game continues
 */
export function checkVictory(state: GameState): VictoryResult | null {
  // 1. Turn limit - Eldoin wins by survival
  if (state.turnCounter >= MAX_TURNS) {
    return { winner: Player.Eldoin, condition: 'turnLimit' };
  }

  // 2. Eldoin's Commander destroyed - Dailor wins
  const eldoinCommander = state.units.find(
    (u) =>
      u.type === ELDOIN_COMMANDER_TYPE &&
      u.owner === Player.Eldoin &&
      state.isUnitAlive(u)
  );

  if (!eldoinCommander) {
    return { winner: Player.Dailor, condition: 'commanderDestroyed' };
  }

  // 3. All Dailor units destroyed - Eldoin wins
  const dailorUnits = state.units.filter(
    (u) => u.owner === Player.Dailor && state.isUnitAlive(u)
  );

  if (dailorUnits.length === 0) {
    return { winner: Player.Eldoin, condition: 'annihilation' };
  }

  // Game continues
  return null;
}

/**
 * Get a description of the current victory status.
 */
export function getVictoryStatus(state: GameState): string {
  if (state.winner === Player.Eldoin) {
    return 'Eldoin is victorious!';
  }

  if (state.winner === Player.Dailor) {
    return 'Dailor is victorious!';
  }

  // Show remaining turns
  const remainingTurns = MAX_TURNS - state.turnCounter;
  return `${remainingTurns} turns remaining`;
}

/**
 * Get the win condition description for the winning player.
 */
export function getWinConditionDescription(state: GameState): string | null {
  if (state.winner === null) {
    return null;
  }

  if (state.winner === Player.Eldoin) {
    // Check if by turn limit or annihilation
    if (state.turnCounter >= MAX_TURNS) {
      return 'Eldoin defended successfully for 15 turns!';
    }

    const dailorUnits = state.units.filter(
      (u) => u.owner === Player.Dailor && state.isUnitAlive(u)
    );
    if (dailorUnits.length === 0) {
      return 'Eldoin destroyed all Dailor forces!';
    }

    return 'Eldoin wins!';
  }

  if (state.winner === Player.Dailor) {
    return "Dailor destroyed Eldoin's Commander!";
  }

  return null;
}

/**
 * Check if the game is over.
 */
export function isGameOver(state: GameState): boolean {
  return state.winner !== null;
}

/**
 * Count remaining units for each player.
 */
export function getUnitCounts(state: GameState): {
  eldoin: number;
  dailor: number;
} {
  let eldoin = 0;
  let dailor = 0;

  for (const unit of state.units) {
    if (state.isUnitAlive(unit)) {
      if (unit.owner === Player.Eldoin) {
        eldoin++;
      } else {
        dailor++;
      }
    }
  }

  return { eldoin, dailor };
}