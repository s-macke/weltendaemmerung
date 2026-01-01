// Cursor Renderer for phase-based cursor styling
// Renders cursor highlight on the game canvas with colors based on game phase

import { GameState } from '../game/GameState';
import { Phase, Coord } from '../types';
import { C64_COLORS } from '../utils/colors';
import { UNIT_STATS } from '../data/units';

// Cursor colors by game state
const CURSOR_COLORS = {
  // Movement phase: white cursor
  movement: C64_COLORS.white,
  // Attack phase: selecting attacker (white)
  attackSelecting: C64_COLORS.white,
  // Attack phase: attacker selected (light red)
  attackSelected: C64_COLORS.lightRed,
  // Attack phase: targeting enemy (red flash)
  attackTargeting: '#FF0000',
  // Torphase: white cursor
  fortification: C64_COLORS.white,
  // Selected unit highlight
  selected: C64_COLORS.lightGreen,
};

export class CursorRenderer {
  // Current cursor position in map coordinates
  cursorX: number = 0;
  cursorY: number = 0;

  // Tile size for rendering
  private readonly tileSize: number = 8;

  // Animation state for pulsing effects
  private pulsePhase: number = 0;
  private lastPulseTime: number = 0;

  /**
   * Set cursor position in map coordinates.
   */
  setCursorPosition(x: number, y: number): void {
    this.cursorX = x;
    this.cursorY = y;
  }

  /**
   * Get current cursor position.
   */
  getCursorPosition(): Coord {
    return { x: this.cursorX, y: this.cursorY };
  }

  /**
   * Update pulse animation.
   */
  updatePulse(timestamp: number): void {
    if (timestamp - this.lastPulseTime > 100) {
      this.pulsePhase = (this.pulsePhase + 1) % 10;
      this.lastPulseTime = timestamp;
    }
  }

  /**
   * Get cursor color based on game phase and state.
   */
  getCursorColor(state: GameState): string {
    switch (state.phase) {
      case Phase.Movement:
        return CURSOR_COLORS.movement;

      case Phase.Attack:
        if (state.selectedUnit) {
          // Attacker selected - check if cursor is on enemy
          const unitAtCursor = state.getUnitAt({
            x: this.cursorX,
            y: this.cursorY,
          });
          if (unitAtCursor && unitAtCursor.owner !== state.currentPlayer) {
            // Targeting enemy - red
            return CURSOR_COLORS.attackTargeting;
          }
          // Attacker selected, not on enemy - light red
          return CURSOR_COLORS.attackSelected;
        }
        // No attacker selected
        return CURSOR_COLORS.attackSelecting;

      case Phase.Fortification:
        return CURSOR_COLORS.fortification;

      default:
        return CURSOR_COLORS.movement;
    }
  }

  /**
   * Render the cursor on the canvas.
   */
  render(
    ctx: CanvasRenderingContext2D,
    state: GameState,
    viewportX: number,
    viewportY: number
  ): void {
    // Calculate screen position
    const screenX = this.cursorX - viewportX;
    const screenY = this.cursorY - viewportY;

    // Skip if cursor is outside viewport
    if (screenX < 0 || screenX >= 40 || screenY < 0 || screenY >= 19) {
      return;
    }

    const pixelX = screenX * this.tileSize;
    const pixelY = screenY * this.tileSize;

    // Draw cursor outline
    ctx.strokeStyle = this.getCursorColor(state);
    ctx.lineWidth = 1;
    ctx.strokeRect(pixelX + 0.5, pixelY + 0.5, this.tileSize - 1, this.tileSize - 1);

    // Draw selected unit highlight (pulsing)
    if (state.selectedUnit && state.isUnitAlive(state.selectedUnit)) {
      const selScreenX = state.selectedUnit.x - viewportX;
      const selScreenY = state.selectedUnit.y - viewportY;

      if (selScreenX >= 0 && selScreenX < 40 && selScreenY >= 0 && selScreenY < 19) {
        const selPixelX = selScreenX * this.tileSize;
        const selPixelY = selScreenY * this.tileSize;

        // Pulsing effect
        const alpha = 0.3 + 0.2 * Math.sin(this.pulsePhase * 0.6);
        ctx.strokeStyle = CURSOR_COLORS.selected;
        ctx.globalAlpha = alpha;
        ctx.lineWidth = 2;
        ctx.strokeRect(selPixelX, selPixelY, this.tileSize, this.tileSize);
        ctx.globalAlpha = 1.0;
      }
    }
  }

  /**
   * Render valid move targets (optional highlight).
   */
  renderMoveTargets(
    ctx: CanvasRenderingContext2D,
    targets: Coord[],
    viewportX: number,
    viewportY: number
  ): void {
    ctx.fillStyle = C64_COLORS.lightGreen;
    ctx.globalAlpha = 0.2;

    for (const target of targets) {
      const screenX = target.x - viewportX;
      const screenY = target.y - viewportY;

      if (screenX >= 0 && screenX < 40 && screenY >= 0 && screenY < 19) {
        ctx.fillRect(
          screenX * this.tileSize,
          screenY * this.tileSize,
          this.tileSize,
          this.tileSize
        );
      }
    }

    ctx.globalAlpha = 1.0;
  }

  /**
   * Render attack range indicator.
   */
  renderAttackRange(
    ctx: CanvasRenderingContext2D,
    state: GameState,
    viewportX: number,
    viewportY: number
  ): void {
    if (!state.selectedUnit || state.phase !== Phase.Attack) return;

    // Highlight enemy units in range
    const range = UNIT_STATS[state.selectedUnit.type]!.range;
    const ax = state.selectedUnit.x;
    const ay = state.selectedUnit.y;

    ctx.strokeStyle = C64_COLORS.lightRed;
    ctx.globalAlpha = 0.5;
    ctx.lineWidth = 1;

    for (const unit of state.units) {
      if (unit.owner === state.currentPlayer || unit.y === 255) continue;

      const dx = unit.x - ax;
      const dy = unit.y - ay;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist <= range) {
        const screenX = unit.x - viewportX;
        const screenY = unit.y - viewportY;

        if (screenX >= 0 && screenX < 40 && screenY >= 0 && screenY < 19) {
          ctx.strokeRect(
            screenX * this.tileSize + 0.5,
            screenY * this.tileSize + 0.5,
            this.tileSize - 1,
            this.tileSize - 1
          );
        }
      }
    }

    ctx.globalAlpha = 1.0;
  }
}
