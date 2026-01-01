// Game Screen Components for Weltendämmerung
// Includes GameChrome (header bar) and StatusBar

import './style.css';
import template from './template.html?raw';
import { Player, Phase, TerrainType } from '../../types';
import { GameState } from '../../game/GameState';
import { UNIT_STATS } from '../../data/units';

// ═══════════════════════════════════════════════════════════════════
// GAME CHROME - Header bar with player indicator, phase display, etc.
// ═══════════════════════════════════════════════════════════════════

const PHASE_NAMES = {
  [Phase.Movement]: 'MOVEMENT',
  [Phase.Attack]: 'ATTACK',
  [Phase.Fortification]: 'FORTIFICATION',
};

export class GameChrome {
  private playerIndicator: HTMLElement | null = null;
  private phaseMovement: HTMLElement | null = null;
  private phaseAttack: HTMLElement | null = null;
  private phaseFort: HTMLElement | null = null;
  private turnNumber: HTMLElement | null = null;
  private endTurnButton: HTMLButtonElement | null = null;
  private onEndTurnCallback: (() => void) | null = null;
  private initialized = false;

  /**
   * Initialize the game chrome - inject template and setup listeners
   */
  init(root: HTMLElement): void {
    if (this.initialized) return;

    // Inject template
    root.insertAdjacentHTML('beforeend', template);

    // Get DOM references
    this.playerIndicator = document.getElementById('player-indicator');
    this.phaseMovement = document.getElementById('phase-movement');
    this.phaseAttack = document.getElementById('phase-attack');
    this.phaseFort = document.getElementById('phase-fort');
    this.turnNumber = document.getElementById('turn-number');
    this.endTurnButton = document.getElementById('end-turn-button') as HTMLButtonElement;

    // Setup event listeners
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

    this.initialized = true;
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

// ═══════════════════════════════════════════════════════════════════
// STATUS BAR - Terrain info, unit stats, contextual information
// ═══════════════════════════════════════════════════════════════════

const TERRAIN_NAMES: Record<TerrainType, string> = {
  [TerrainType.Meadow]: 'Meadow',
  [TerrainType.River]: 'River',
  [TerrainType.Forest]: 'Forest',
  [TerrainType.End]: 'Border',
  [TerrainType.Swamp]: 'Swamp',
  [TerrainType.Gate]: 'Gate',
  [TerrainType.Mountains]: 'Mountains',
  [TerrainType.Pavement]: 'Pavement',
  [TerrainType.Wall]: 'Wall',
};

export class StatusBar {
  private terrainInfo: HTMLElement | null = null;
  private unitInfo: HTMLElement | null = null;
  private unitStats: HTMLElement | null = null;

  /**
   * Initialize the status bar - get DOM references
   * Note: Template is already injected by GameChrome
   */
  init(): void {
    this.terrainInfo = document.getElementById('terrain-info');
    this.unitInfo = document.getElementById('unit-info');
    this.unitStats = document.getElementById('unit-stats');
  }

  /**
   * Update the status bar based on game state and cursor position
   */
  update(gameState: GameState, cursorX: number, cursorY: number): void {
    this.updateTerrainInfo(gameState, cursorX, cursorY);
    this.updateUnitInfo(gameState, cursorX, cursorY);
  }

  /**
   * Update terrain information display
   */
  private updateTerrainInfo(gameState: GameState, x: number, y: number): void {
    if (!this.terrainInfo) return;

    const terrain = gameState.getTerrainAt({ x, y });
    const terrainName = TERRAIN_NAMES[terrain] || 'Unknown';

    // Add color coding for terrain
    let colorClass = 'text-c64-light-gray';
    switch (terrain) {
      case TerrainType.River:
      case TerrainType.Swamp:
        colorClass = 'text-c64-light-blue';
        break;
      case TerrainType.Forest:
        colorClass = 'text-c64-light-red';
        break;
      case TerrainType.Gate:
      case TerrainType.Wall:
        colorClass = 'text-c64-purple';
        break;
      case TerrainType.Mountains:
        colorClass = 'text-c64-dark-gray';
        break;
    }

    this.terrainInfo.innerHTML = `<span class="${colorClass}">Terrain: ${terrainName}</span>`;
  }

  /**
   * Update unit information display
   */
  private updateUnitInfo(gameState: GameState, cursorX: number, cursorY: number): void {
    if (!this.unitInfo || !this.unitStats) return;

    // Check for unit at cursor position
    const unit = gameState.getUnitAt({ x: cursorX, y: cursorY });

    if (unit) {
      const stats = UNIT_STATS[unit.type];
      if (!stats) {
        this.unitInfo.textContent = '';
        this.unitStats.textContent = '';
        return;
      }

      const ownerClass = unit.owner === Player.Eldoin ? 'text-eldoin' : 'text-dailor';

      this.unitInfo.innerHTML = `<span class="${ownerClass}">${stats.name}</span>`;

      this.unitStats.innerHTML =
        `Rng:<span class="stat-rng">${stats.range}</span> ` +
        `Mov:<span class="stat-mov">${unit.movement}</span>/${stats.movement} ` +
        `Atk:<span class="stat-atk">${stats.attack}</span> ` +
        `Def:<span class="stat-def">${unit.defense}</span>/${stats.defense}`;
    } else if (gameState.selectedUnit) {
      // Show selected unit info even when cursor is elsewhere
      const stats = UNIT_STATS[gameState.selectedUnit.type];
      if (!stats) {
        this.unitInfo.textContent = '';
        this.unitStats.textContent = '';
        return;
      }

      const ownerClass = gameState.selectedUnit.owner === Player.Eldoin ? 'text-eldoin' : 'text-dailor';

      this.unitInfo.innerHTML = `<span class="${ownerClass}">${stats.name} (selected)</span>`;

      this.unitStats.innerHTML =
        `Rng:<span class="stat-rng">${stats.range}</span> ` +
        `Mov:<span class="stat-mov">${gameState.selectedUnit.movement}</span>/${stats.movement} ` +
        `Atk:<span class="stat-atk">${stats.attack}</span> ` +
        `Def:<span class="stat-def">${gameState.selectedUnit.defense}</span>/${stats.defense}`;
    } else {
      this.unitInfo.textContent = '';
      this.unitStats.textContent = '';
    }
  }

  /**
   * Show a temporary message in the status bar
   */
  showMessage(message: string, duration: number = 2000): void {
    if (!this.unitInfo) return;

    const originalContent = this.unitInfo.innerHTML;
    this.unitInfo.innerHTML = `<span class="text-c64-yellow animate-phosphor">${message}</span>`;

    setTimeout(() => {
      if (this.unitInfo) {
        this.unitInfo.innerHTML = originalContent;
      }
    }, duration);
  }
}
