// Screen Management for Weltendämmerung
// Handles transitions between Title, Game, and Victory screens

import './shared.css';

// Re-export screen classes
export { TitleScreen } from './title';
export { GameChrome, StatusBar } from './game';
export { VictoryScreen, type VictoryCondition } from './victory';

// ═══════════════════════════════════════════════════════════════════
// SCREEN STATE MANAGEMENT
// ═══════════════════════════════════════════════════════════════════

export type ScreenType = 'title' | 'game' | 'victory';

// DOM element references (lazy-loaded)
const screens = {
  title: () => document.getElementById('title-screen'),
  game: () => document.getElementById('app'),
  victory: () => document.getElementById('victory-screen'),
};

let currentScreen: ScreenType = 'title';

/**
 * Show a specific screen with fade-in animation
 */
export function showScreen(screen: ScreenType): void {
  const element = screens[screen]();
  if (!element) return;

  // Hide current screen first
  if (currentScreen !== screen) {
    hideScreen(currentScreen);
  }

  currentScreen = screen;

  // Show the new screen
  element.classList.remove('hidden');
  element.classList.remove('animate-fade-out');
  element.classList.add('animate-fade-in');
}

/**
 * Hide a specific screen with fade-out animation
 */
export function hideScreen(screen: ScreenType): void {
  const element = screens[screen]();
  if (!element) return;

  element.classList.remove('animate-fade-in');
  element.classList.add('animate-fade-out');

  // Add hidden class after animation completes
  setTimeout(() => {
    element.classList.add('hidden');
  }, 300);
}

/**
 * Get the current active screen
 */
export function getCurrentScreen(): ScreenType {
  return currentScreen;
}

/**
 * Initialize screen state - show title, hide others
 */
export function initScreens(): void {
  // Ensure title is shown, others hidden
  const titleEl = screens.title();
  const gameEl = screens.game();
  const victoryEl = screens.victory();

  if (titleEl) {
    titleEl.classList.remove('hidden');
  }
  if (gameEl) {
    gameEl.classList.add('hidden');
  }
  if (victoryEl) {
    victoryEl.classList.add('hidden');
  }

  currentScreen = 'title';
}
