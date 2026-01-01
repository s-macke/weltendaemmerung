// Enhanced Status Bar Component for Weltendämmerung
// Displays terrain info, unit stats, and contextual information

import { GameState } from '../game/GameState';
import { Player, TerrainType } from '../types';
import { UNIT_STATS } from '../data/units';
import { getTerrainAt } from '../data/map';

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
  private terrainInfo: HTMLElement | null;
  private unitInfo: HTMLElement | null;
  private unitStats: HTMLElement | null;

  constructor() {
    this.terrainInfo = document.getElementById('terrain-info');
    this.unitInfo = document.getElementById('unit-info');
    this.unitStats = document.getElementById('unit-stats');
  }

  /**
   * Update the status bar based on game state and cursor position
   */
  update(gameState: GameState, cursorX: number, cursorY: number): void {
    this.updateTerrainInfo(cursorX, cursorY);
    this.updateUnitInfo(gameState, cursorX, cursorY);
  }

  /**
   * Update terrain information display
   */
  private updateTerrainInfo(x: number, y: number): void {
    if (!this.terrainInfo) return;

    const terrain = getTerrainAt(x, y);
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

      this.unitStats.innerHTML = `
        <span class="inline-flex items-center gap-1">
          Rng:<span class="text-c64-yellow">${stats.range}</span>
          Mov:<span class="text-c64-light-green">${unit.movement}</span>/${stats.movement}
          Atk:<span class="text-c64-light-red">${stats.attack}</span>
          Def:<span class="text-c64-yellow">${unit.defense}</span>/${stats.defense}
        </span>
      `;
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
      this.unitStats.innerHTML = `
        <span class="inline-flex items-center gap-1">
          Rng:<span class="text-c64-yellow">${stats.range}</span>
          Mov:<span class="text-c64-light-green">${gameState.selectedUnit.movement}</span>/${stats.movement}
          Atk:<span class="text-c64-light-red">${stats.attack}</span>
          Def:<span class="text-c64-yellow">${gameState.selectedUnit.defense}</span>/${stats.defense}
        </span>
      `;
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
