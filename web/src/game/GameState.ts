// Core game state management for Weltendaemmerung

import { Player, Phase, TerrainType, Unit, Coord } from '../types';
import { MAP_TERRAIN, MAP_WIDTH, MAP_HEIGHT } from '../data/map';
import { INITIAL_UNITS } from '../data/initialUnits';
import { UNIT_STATS } from '../data/units';
import { GATE_POSITIONS } from '../data/gates';

// Gate state enum for tracking modifications
export enum GateState {
  Original = 0,    // Gate as placed on original map
  Wall = 1,        // Converted to wall by Eldoin
  Meadow = 2,      // Converted to meadow by Dailor
  Destroyed = 3,   // Destroyed by combat (becomes Pavement)
}

export class GameState {
  // Turn tracking
  turnCounter: number = 1;
  currentPlayer: Player = Player.Eldoin;
  phase: Phase = Phase.Movement;

  // Units
  units: Unit[] = [];
  selectedUnit: Unit | null = null;

  // Gate state tracking (13 positions)
  // Tracks state of each gate position
  gateStates: GateState[] = new Array(GATE_POSITIONS.length).fill(GateState.Original);

  // Victory state
  winner: Player | null = null;

  constructor() {
    this.initializeUnits();
  }

  /**
   * Initialize units from the initial placement data.
   */
  private initializeUnits(): void {
    this.units = INITIAL_UNITS.map((data, index) => {
      const stats = UNIT_STATS[data.type]!;
      return {
        id: index,
        x: data.x,
        y: data.y,
        type: data.type,
        owner: data.owner,
        defense: stats.defense,
        movement: stats.movement,
        maxMovement: stats.movement,
      };
    });
  }

  /**
   * Reset game to initial state.
   */
  reset(): void {
    this.turnCounter = 1;
    this.currentPlayer = Player.Eldoin;
    this.phase = Phase.Movement;
    this.selectedUnit = null;
    this.gateStates = new Array(GATE_POSITIONS.length).fill(GateState.Original);
    this.winner = null;
    this.initializeUnits();
  }

  /**
   * Get terrain type at map coordinates.
   * Derives current terrain from original map + gate state modifications.
   */
  getTerrainAt(pos: Coord): TerrainType {
    if (pos.x < 0 || pos.x >= MAP_WIDTH || pos.y < 0 || pos.y >= MAP_HEIGHT) {
      return TerrainType.End;
    }

    // Get original terrain
    const original = MAP_TERRAIN[pos.y * MAP_WIDTH + pos.x]!;

    // Check if this is a gate position that may have been modified
    const gateIndex = GATE_POSITIONS.findIndex(
      (g) => g.pos.x === pos.x && g.pos.y === pos.y
    );

    if (gateIndex !== -1) {
      const state = this.gateStates[gateIndex]!;
      switch (state) {
        case GateState.Wall:
          return TerrainType.Wall;
        case GateState.Meadow:
          return TerrainType.Meadow;
        case GateState.Destroyed:
          return TerrainType.Pavement;
        default:
          // Original state - return what's on the map
          return original;
      }
    }

    return original;
  }

  /**
   * Get unit at map coordinates.
   * @returns Unit or undefined if no unit at position
   */
  getUnitAt(pos: Coord): Unit | undefined {
    return this.units.find(
      (u) => u.x === pos.x && u.y === pos.y && u.y !== 255
    );
  }

  /**
   * Get all living units owned by a player.
   */
  getPlayerUnits(player: Player): Unit[] {
    return this.units.filter((u) => u.owner === player && u.y !== 255);
  }

  /**
   * Check if a unit is alive (not destroyed).
   */
  isUnitAlive(unit: Unit): boolean {
    return unit.y !== 255;
  }

  /**
   * Mark a unit as destroyed.
   */
  destroyUnit(unit: Unit): void {
    unit.y = 255;
    if (this.selectedUnit === unit) {
      this.selectedUnit = null;
    }
  }

  /**
   * Reset movement points for all units at start of new round.
   */
  resetAllMovementPoints(): void {
    for (const unit of this.units) {
      if (this.isUnitAlive(unit)) {
        unit.movement = unit.maxMovement;
      }
    }
  }

  /**
   * Set movement to 1 for all units at start of attack phase.
   */
  setAllMovementToOne(): void {
    for (const unit of this.units) {
      if (this.isUnitAlive(unit)) {
        unit.movement = 1;
      }
    }
  }

  /**
   * Get combined state number (1-6) for turn display.
   * Combined State = (Phase × 2) + Player + 1
   */
  getCombinedState(): number {
    return this.phase * 2 + this.currentPlayer + 1;
  }

  /**
   * Set gate state at a gate index.
   */
  setGateState(gateIndex: number, state: GateState): void {
    if (gateIndex >= 0 && gateIndex < this.gateStates.length) {
      this.gateStates[gateIndex] = state;
    }
  }

  /**
   * Get gate state at a gate index.
   */
  getGateState(gateIndex: number): GateState {
    return this.gateStates[gateIndex] ?? GateState.Original;
  }

  /**
   * Check if gate at index was destroyed (permanently disabled).
   */
  isGateDestroyed(gateIndex: number): boolean {
    return this.gateStates[gateIndex] === GateState.Destroyed;
  }
}
