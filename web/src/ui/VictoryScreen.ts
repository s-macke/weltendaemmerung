// Victory Screen Component for Weltendämmerung
// Displays the dramatic winner announcement

import { Player } from '../types';
import { showScreen, hideScreen } from './screens';

// Victory condition messages
const VICTORY_MESSAGES = {
  turnLimit: {
    [Player.Eldoin]: '"The western lands are saved! Eldoin held the line for 15 turns!"',
    [Player.Dailor]: '"The invasion has succeeded! Dailor conquers all!"',
  },
  commanderDestroyed: {
    [Player.Eldoin]: '"Impossible! The Commander has fallen, but Eldoin fights on!"',
    [Player.Dailor]: '"The Commander has fallen! Dailor claims victory!"',
  },
  annihilation: {
    [Player.Eldoin]: '"Total victory! Eldoin has crushed all opposition!"',
    [Player.Dailor]: '"The defenders are no more! Dailor reigns supreme!"',
  },
};

export type VictoryCondition = 'turnLimit' | 'commanderDestroyed' | 'annihilation';

export class VictoryScreen {
  private container: HTMLElement | null;
  private winnerNameEl: HTMLElement | null;
  private victoryMessageEl: HTMLElement | null;
  private playAgainButton: HTMLButtonElement | null;
  private onPlayAgainCallback: (() => void) | null = null;

  constructor() {
    this.container = document.getElementById('victory-screen');
    this.winnerNameEl = document.getElementById('winner-name');
    this.victoryMessageEl = document.getElementById('victory-message');
    this.playAgainButton = document.getElementById('play-again-button') as HTMLButtonElement;
  }

  /**
   * Initialize the victory screen with event listeners
   */
  init(): void {
    if (this.playAgainButton) {
      this.playAgainButton.addEventListener('click', () => this.handlePlayAgain());
    }

    // Keyboard support (Enter to play again)
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && this.isVisible()) {
        this.handlePlayAgain();
      }
    });
  }

  /**
   * Check if victory screen is currently visible
   */
  isVisible(): boolean {
    return this.container ? !this.container.classList.contains('hidden') : false;
  }

  /**
   * Set callback for when player wants to play again
   */
  onPlayAgain(callback: () => void): void {
    this.onPlayAgainCallback = callback;
  }

  /**
   * Show the victory screen with winner info
   */
  show(winner: Player, condition: VictoryCondition = 'turnLimit'): void {
    const winnerName = winner === Player.Eldoin ? 'ELDOIN' : 'DAILOR';
    const winnerClass = winner === Player.Eldoin ? 'eldoin' : 'dailor';

    // Update winner name
    if (this.winnerNameEl) {
      this.winnerNameEl.textContent = `${winnerName} WINS!`;
      this.winnerNameEl.className = `winner-name ${winnerClass}`;
    }

    // Update victory message
    if (this.victoryMessageEl) {
      this.victoryMessageEl.textContent = VICTORY_MESSAGES[condition][winner];
    }

    // Update container border color based on winner
    if (this.container) {
      const contentEl = this.container.querySelector('.victory-content');
      if (contentEl) {
        if (winner === Player.Eldoin) {
          (contentEl as HTMLElement).style.borderColor = 'var(--c64-yellow)';
        } else {
          (contentEl as HTMLElement).style.borderColor = 'var(--c64-light-blue)';
        }
      }
    }

    showScreen('victory');
  }

  /**
   * Hide the victory screen
   */
  hide(): void {
    hideScreen('victory');
  }

  /**
   * Handle play again action
   */
  private handlePlayAgain(): void {
    if (!this.isVisible()) return;

    this.hide();

    setTimeout(() => {
      if (this.onPlayAgainCallback) {
        this.onPlayAgainCallback();
      }
    }, 300);
  }
}
