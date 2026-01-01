// Game Chrome Component for Weltendämmerung
// Manages the header bar with player indicator, phase display, turn counter, and end turn button

import { Player, Phase } from '../types';
import { GameState } from '../game/GameState';

const PHASE_NAMES = {
  [Phase.Movement]: 'MOVEMENT',
  [Phase.Attack]: 'ATTACK',
  [Phase.Fortification]: 'FORTIFICATION',
};

export class GameChrome {
  private playerIndicator: HTMLElement | null;
  private phaseMovement: HTMLElement | null;
  private phaseAttack: HTMLElement | null;
  private phaseFort: HTMLElement | null;
  private turnNumber: HTMLElement | null;
  private endTurnButton: HTMLButtonElement | null;
  private onEndTurnCallback: (() => void) | null = null;

  constructor() {
    this.playerIndicator = document.getElementById('player-indicator');
    this.phaseMovement = document.getElementById('phase-movement');
    this.phaseAttack = document.getElementById('phase-attack');
    this.phaseFort = document.getElementById('phase-fort');
    this.turnNumber = document.getElementById('turn-number');
    this.endTurnButton = document.getElementById('end-turn-button') as HTMLButtonElement;
  }

  /**
   * Initialize the game chrome with event listeners
   */
  init(): void {
    if (this.endTurnButton) {
      this.endTurnButton.addEventListener('click', () => this.handleEndTurn());
    }

    // Keyboard shortcut for end turn (Space)
    document.addEventListener('keydown', (e) => {
      if (e.key === ' ' && !e.repeat) {
        const gameScreen = document.getElementById('app');
        if (gameScreen && !gameScreen.classList.contains('hidden')) {
          e.preventDefault();
          this.handleEndTurn();
        }
      }
    });
  }

  /**
   * Set callback for when end turn is clicked
   */
  onEndTurn(callback: () => void): void {
    this.onEndTurnCallback = callback;
  }

  /**
   * Update the chrome UI based on current game state
   */
  update(gameState: GameState): void {
    this.updatePlayerIndicator(gameState.currentPlayer);
    this.updatePhaseIndicators(gameState.phase);
    this.updateTurnCounter(gameState.turnCounter);
  }

  /**
   * Update player indicator display
   */
  private updatePlayerIndicator(player: Player): void {
    if (!this.playerIndicator) return;

    const isEldoin = player === Player.Eldoin;
    this.playerIndicator.textContent = isEldoin ? 'ELDOIN' : 'DAILOR';
    this.playerIndicator.className = `player-indicator ${isEldoin ? 'eldoin' : 'dailor'}`;
  }

  /**
   * Update phase indicator pills
   */
  private updatePhaseIndicators(phase: Phase): void {
    // Reset all indicators
    [this.phaseMovement, this.phaseAttack, this.phaseFort].forEach((el) => {
      if (el) el.classList.remove('active');
    });

    // Activate current phase
    switch (phase) {
      case Phase.Movement:
        if (this.phaseMovement) this.phaseMovement.classList.add('active');
        break;
      case Phase.Attack:
        if (this.phaseAttack) this.phaseAttack.classList.add('active');
        break;
      case Phase.Fortification:
        if (this.phaseFort) this.phaseFort.classList.add('active');
        break;
    }

    // Update glow effect on header based on phase
    const header = document.getElementById('game-header');
    if (header) {
      header.classList.remove('glow-green', 'glow-red', 'glow-purple');
      switch (phase) {
        case Phase.Movement:
          header.classList.add('glow-green');
          break;
        case Phase.Attack:
          header.classList.add('glow-red');
          break;
        case Phase.Fortification:
          header.classList.add('glow-purple');
          break;
      }
    }
  }

  /**
   * Update turn counter display
   */
  private updateTurnCounter(turn: number): void {
    if (this.turnNumber) {
      this.turnNumber.textContent = String(turn);
    }
  }

  /**
   * Handle end turn button click
   */
  private handleEndTurn(): void {
    if (this.endTurnButton) {
      // Visual feedback
      this.endTurnButton.classList.add('animate-pulse-glow');
      setTimeout(() => {
        this.endTurnButton?.classList.remove('animate-pulse-glow');
      }, 200);
    }

    if (this.onEndTurnCallback) {
      this.onEndTurnCallback();
    }
  }

  /**
   * Get the current phase name for display
   */
  getPhaseName(phase: Phase): string {
    return PHASE_NAMES[phase];
  }
}
