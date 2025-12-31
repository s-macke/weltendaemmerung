// Game logic exports for Weltendaemmerung

export { GameState, GateState } from './GameState';
export {
  advanceTurn,
  getPhaseName,
  getPlayerName,
  getTurnStatus,
} from './TurnManager';
export {
  canMoveTo,
  getMovementCost,
  moveUnit,
  getValidMoveTargets,
  hasValidMoves,
  getTerrainName,
  getUnitInfo,
} from './MovementSystem';
export {
  isInRange,
  isPositionInRange,
  canAttack,
  canAttackStructure,
  calculateDamage,
  applyDamage,
  attackUnit,
  attackStructure,
  getValidAttackTargets,
  getValidStructureTargets,
} from './CombatSystem';
export {
  canPerformTorphase,
  performTorphase,
  getValidTorphasePositions,
  getGateDescription,
  isEldoinTerritory,
  isDailorTerritory,
} from './FortificationSystem';
export {
  checkVictory,
  getVictoryStatus,
  getWinConditionDescription,
  isGameOver,
  getUnitCounts,
} from './VictoryChecker';