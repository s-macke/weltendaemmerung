// Core game types for Weltendaemmerung

// Map coordinates
export interface Coord {
  x: number;
  y: number;
}

// Player factions
export enum Player {
  Eldoin = 0,  // Western faction (defender)
  Dailor = 1   // Eastern faction (attacker)
}

// Game phases
export enum Phase {
  Movement = 0,      // Bewegungsphase - full movement points
  Attack = 1,        // Angriffsphase - movement restricted to 1
  Fortification = 2  // Torphase - build gates/walls
}

// Terrain types
export enum TerrainType {
  Meadow = 0,     // $69-$6A - Easy traversal
  River = 1,      // $6B - Water, varies by unit
  Forest = 2,     // $6C - Slows movement
  End = 3,        // $6D - Map boundary
  Swamp = 4,      // $6E - Difficult terrain
  Gate = 5,       // $6F - Fortification point
  Mountains = 6,  // $70 - Blocking terrain
  Pavement = 7,   // $71 - Fast movement
  Wall = 8        // $72-$73 - Blocking structure
}

// Unit representation
export interface Unit {
  id: number;          // Unique identifier
  x: number;           // Map X position (0-79)
  y: number;           // Map Y position (0-39), 255 = destroyed
  type: number;        // Unit type (0-15)
  owner: Player;       // Eldoin (0) or Dailor (1)
  defense: number;     // Current defense (decreases in combat)
  movement: number;    // Remaining movement this phase
  maxMovement: number; // Max movement (reset each round)
  hasAttacked: boolean; // True if unit has attacked this attack phase
}

// Complete game state
export interface GameState {
  // Turn tracking
  turnCounter: number;      // Current turn (1-15)
  currentPlayer: Player;    // Active player
  phase: Phase;             // Current phase

  // Units
  units: Unit[];            // All units (292 total)
  selectedUnit: Unit | null; // Currently selected unit

  // Map state
  mapTerrain: TerrainType[]; // 80x40 terrain grid

  // Gate tracking (13 positions)
  gateFlags: boolean[];     // True if gate was destroyed

  // Victory state
  winner: Player | null;    // Non-null when game ends
}