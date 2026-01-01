// UI Renderer for status bar and game info
// Displays phase header, terrain info, and unit statistics

import { GameState } from '../game/GameState';
import { Phase, Player, TerrainType, Coord, Unit } from '../types';
import { UNIT_STATS } from '../data/units';
import { C64_COLORS } from '../utils/colors';

// Terrain names
const TERRAIN_NAMES: Record<TerrainType, string> = {
  [TerrainType.Meadow]: 'Meadow',
  [TerrainType.River]: 'River',
  [TerrainType.Forest]: 'Forest',
  [TerrainType.End]: 'End',
  [TerrainType.Swamp]: 'Swamp',
  [TerrainType.Gate]: 'Gate',
  [TerrainType.Mountains]: 'Mountains',
  [TerrainType.Pavement]: 'Pavement',
  [TerrainType.Wall]: 'Wall',
};

// Phase names
const PHASE_NAMES: Record<Phase, string> = {
  [Phase.Movement]: 'MOVEMENT PHASE',
  [Phase.Attack]: 'ATTACK PHASE',
  [Phase.Fortification]: 'GATE PHASE',
};

// Player names
const PLAYER_NAMES: Record<Player, string> = {
  [Player.Eldoin]: 'ELDOIN',
  [Player.Dailor]: 'DAILOR',
};

export class UIRenderer {
  private container: HTMLElement | null = null;
  private phaseHeader: HTMLElement | null = null;
  private terrainInfo: HTMLElement | null = null;
  private unitStats: HTMLElement | null = null;
  private turnInfo: HTMLElement | null = null;

  /**
   * Initialize the UI renderer with a container element.
   * Creates the status bar structure if not already present.
   */
  init(containerId: string): void {
    this.container = document.getElementById(containerId);
    if (!this.container) {
      console.error(`UIRenderer: Container '${containerId}' not found`);
      return;
    }

    // Create status bar elements if they don't exist
    if (!this.container.querySelector('.phase-header')) {
      this.createStatusBar();
    }

    this.phaseHeader = this.container.querySelector('.phase-header');
    this.terrainInfo = this.container.querySelector('.terrain-info');
    this.unitStats = this.container.querySelector('.unit-stats');
    this.turnInfo = this.container.querySelector('.turn-info');
  }

  /**
   * Create the status bar DOM structure.
   */
  private createStatusBar(): void {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="phase-header" style="color: ${C64_COLORS.yellow}; font-weight: bold;"></div>
      <div class="terrain-info" style="color: ${C64_COLORS.lightGray};"></div>
      <div class="unit-stats" style="color: ${C64_COLORS.white}; font-family: monospace;"></div>
      <div class="turn-info" style="color: ${C64_COLORS.lightGray}; font-size: 0.9em;"></div>
    `;
  }

  /**
   * Update the status bar with current game state.
   */
  render(state: GameState, cursorPos: Coord): void {
    this.updatePhaseHeader(state);
    this.updateTerrainInfo(state, cursorPos);
    this.updateUnitStats(state, cursorPos);
    this.updateTurnInfo(state);
  }

  /**
   * Format and display the phase header.
   * Format: "[PLAYER] [PHASE]PHASE"
   */
  private updatePhaseHeader(state: GameState): void {
    if (!this.phaseHeader) return;

    const playerName = PLAYER_NAMES[state.currentPlayer];
    const phaseName = PHASE_NAMES[state.phase];

    this.phaseHeader.textContent = `${playerName} ${phaseName}`;

    // Color based on player
    this.phaseHeader.style.color =
      state.currentPlayer === Player.Eldoin
        ? C64_COLORS.yellow
        : C64_COLORS.lightGray;
  }

  /**
   * Display terrain name at cursor position.
   */
  private updateTerrainInfo(state: GameState, cursorPos: Coord): void {
    if (!this.terrainInfo) return;

    const terrain = state.getTerrainAt(cursorPos);
    const terrainName = TERRAIN_NAMES[terrain] ?? 'Unknown';

    this.terrainInfo.textContent = terrainName;
  }

  /**
   * Display unit statistics if cursor is on a unit.
   * Format: "Unit Name - Rng=XX Mov=XX Atk=XX Def=XX"
   */
  private updateUnitStats(state: GameState, cursorPos: Coord): void {
    if (!this.unitStats) return;

    const unit = state.getUnitAt(cursorPos);

    if (unit) {
      const stats = UNIT_STATS[unit.type]!;
      // Using 2-digit padding for stats
      const rng = stats.range.toString().padStart(2, ' ');
      const mov = unit.movement.toString().padStart(2, ' ');
      const atk = stats.attack.toString().padStart(2, ' ');
      const def = unit.defense.toString().padStart(2, ' ');

      this.unitStats.textContent = `${stats.name} - Rng=${rng} Mov=${mov} Atk=${atk} Def=${def}`;
    } else {
      // Use non-breaking space to preserve height when empty
      this.unitStats.innerHTML = '&nbsp;';
    }
  }

  /**
   * Display turn counter.
   */
  private updateTurnInfo(state: GameState): void {
    if (!this.turnInfo) return;

    this.turnInfo.textContent = `Turn ${state.turnCounter}/15`;
  }

  /**
   * Get the formatted phase header string.
   */
  formatPhaseHeader(state: GameState): string {
    return `${PLAYER_NAMES[state.currentPlayer]} ${PHASE_NAMES[state.phase]}`;
  }

  /**
   * Get the terrain name.
   */
  formatTerrainName(terrain: TerrainType): string {
    return TERRAIN_NAMES[terrain] ?? 'Unknown';
  }

  /**
   * Format unit stats string.
   */
  formatUnitStats(unit: Unit): string {
    const stats = UNIT_STATS[unit.type]!;
    const rng = stats.range.toString().padStart(2, ' ');
    const mov = unit.movement.toString().padStart(2, ' ');
    const atk = stats.attack.toString().padStart(2, ' ');
    const def = unit.defense.toString().padStart(2, ' ');
    return `${stats.name} - Rng=${rng} Mov=${mov} Atk=${atk} Def=${def}`;
  }
}
