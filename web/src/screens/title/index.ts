// Title Screen Component for Weltendämmerung
// Displays the epic game title with faction display and start button

import './style.css';
import template from './template.html?raw';
import { showScreen } from '../index';

export class TitleScreen {
  private container: HTMLElement | null = null;
  private startButton: HTMLButtonElement | null = null;
  private onStartCallback: (() => void) | null = null;
  private initialized = false;

  /**
   * Initialize the title screen - inject template and setup listeners
   */
  init(root: HTMLElement): void {
    if (this.initialized) return;

    // Inject template
    root.insertAdjacentHTML('beforeend', template);

    // Get DOM references
    this.container = document.getElementById('title-screen');
    this.startButton = document.getElementById('start-button') as HTMLButtonElement;

    // Setup event listeners
    if (this.startButton) {
      this.startButton.addEventListener('click', () => this.handleStart());
    }

    // Keyboard support (Enter to start)
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && this.isVisible()) {
        this.handleStart();
      }
    });

    this.initialized = true;
  }

  /**
   * Check if title screen is currently visible
   */
  isVisible(): boolean {
    return this.container ? !this.container.classList.contains('hidden') : false;
  }

  /**
   * Set callback for when game should start
   */
  onStart(callback: () => void): void {
    this.onStartCallback = callback;
  }

  /**
   * Handle start game action
   */
  private handleStart(): void {
    if (!this.isVisible()) return;

    // Trigger button press effect
    if (this.startButton) {
      this.startButton.classList.add('animate-pulse-glow');
    }

    // Short delay for visual feedback, then start
    setTimeout(() => {
      showScreen('game');
      if (this.onStartCallback) {
        this.onStartCallback();
      }
    }, 200);
  }

  /**
   * Show the title screen
   */
  show(): void {
    showScreen('title');
  }

  /**
   * Hide the title screen
   */
  hide(): void {
    if (this.container) {
      this.container.classList.add('hidden');
    }
  }
}
