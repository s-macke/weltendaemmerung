// Turn management for Weltendaemmerung
// Implements the 6-state turn machine

import { Player, Phase } from '../types';
import { GameState } from './GameState';
import { checkVictory } from './VictoryChecker';

/**
 * Advance to the next turn.
 * Called when the current player clicks "End Turn".
 *
 * State cycle: 1 → 2 → 3 → 4 → 5 → 6 → 1
 *
 * | State | Phase | Player |
 * |-------|-------|--------|
 * | 1     | Movement (0) | Eldoin |
 * | 2     | Movement (0) | Dailor |
 * | 3     | Attack (1)   | Eldoin |
 * | 4     | Attack (1)   | Dailor |
 * | 5     | Torphase (2) | Eldoin |
 * | 6     | Torphase (2) | Dailor |
 */
export function advanceTurn(state: GameState): void {
  // Clear selection when turn ends
  state.selectedUnit = null;

  // Toggle player
  if (state.currentPlayer === Player.Eldoin) {
    state.currentPlayer = Player.Dailor;
  } else {
    state.currentPlayer = Player.Eldoin;

    // If back to Eldoin, advance phase
    state.phase = ((state.phase + 1) % 3) as Phase;

    // If new round (back to Movement phase)
    if (state.phase === Phase.Movement) {
      state.turnCounter++;
      state.resetAllMovementPoints();

      // Check turn limit victory condition
      const result = checkVictory(state);
      if (result !== null) {
        state.winner = result.winner;
      }
    }
  }

  // At start of attack phase, reset attack flags (each unit can attack once)
  if (state.phase === Phase.Attack) {
    state.resetAllAttackFlags();
  }
}

/**
 * Get the phase name for display.
 */
export function getPhaseName(phase: Phase): string {
  switch (phase) {
    case Phase.Movement:
      return 'Movement Phase';
    case Phase.Attack:
      return 'Attack Phase';
    case Phase.Fortification:
      return 'Fortification Phase';
  }
}

/**
 * Get the player name for display.
 */
export function getPlayerName(player: Player): string {
  return player === Player.Eldoin ? 'Eldoin' : 'Dailor';
}

/**
 * Get full turn status string for display.
 * Example: "Turn 3 - Eldoin Movement Phase"
 */
export function getTurnStatus(state: GameState): string {
  const playerName = getPlayerName(state.currentPlayer);
  const phaseName = getPhaseName(state.phase);
  return `Turn ${state.turnCounter} - ${playerName} ${phaseName}`;
}