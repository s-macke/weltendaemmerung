// Weltendaemmerung - Web Port Entry Point
// A Commodore 64 fantasy strategy game for two players

import { C64_COLORS } from './utils/colors';
import { MAP_WIDTH, MAP_HEIGHT, getCharCodeAt } from './data/map';
import { GameState } from './game/GameState';
import { CursorRenderer } from './rendering';
import { TitleScreen, VictoryScreen, GameChrome, StatusBar, initScreens, showScreen, VictoryCondition } from './screens';
import { Player } from './types';
import { advanceTurn } from './game/TurnManager';
import { checkVictory } from './game/VictoryChecker';

// Tile rendering constants
const TILE_SIZE = 8;
const VIEWPORT_WIDTH = 40;  // tiles
const VIEWPORT_HEIGHT = 19; // tiles
const TILE_OFFSET = 0x5E;   // First tile character code

// Tile images cache
const tileImages: Map<number, HTMLImageElement> = new Map();

// Viewport position
let viewportX = 0;
let viewportY = 0;

// Game state
let gameState = new GameState();

// UI Components
const titleScreen = new TitleScreen();
const victoryScreen = new VictoryScreen();
const gameChrome = new GameChrome();
const statusBar = new StatusBar();
const cursorRenderer = new CursorRenderer();

// Cursor position for status bar
let cursorMapX = 0;
let cursorMapY = 0;

// Game running flag
let gameRunning = false;

// Load a single tile image
async function loadTile(index: number): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = `/tiles/tile_${index.toString().padStart(2, '0')}.png`;
  });
}

// Load all tile images
async function loadAllTiles(): Promise<void> {
  const promises: Promise<void>[] = [];

  for (let i = 0; i < 38; i++) {
    promises.push(
      loadTile(i).then(img => {
        tileImages.set(i, img);
      })
    );
  }

  await Promise.all(promises);
  console.log(`Loaded ${tileImages.size} tiles`);
}

// Get tile index from character code
function charCodeToTileIndex(charCode: number): number {
  return charCode - TILE_OFFSET;
}

// Render the map viewport
function renderMap(ctx: CanvasRenderingContext2D): void {
  // Fill background with C64 green
  ctx.fillStyle = C64_COLORS.green;
  ctx.fillRect(0, 0, VIEWPORT_WIDTH * TILE_SIZE, VIEWPORT_HEIGHT * TILE_SIZE);

  // Render visible tiles
  for (let y = 0; y < VIEWPORT_HEIGHT; y++) {
    for (let x = 0; x < VIEWPORT_WIDTH; x++) {
      const mapX = viewportX + x;
      const mapY = viewportY + y;

      // Skip out-of-bounds tiles
      if (mapX >= MAP_WIDTH || mapY >= MAP_HEIGHT) continue;

      const charCode = getCharCodeAt(mapX, mapY);

      const tileIndex = charCodeToTileIndex(charCode);
      const tileImg = tileImages.get(tileIndex);

      if (tileImg) {
        ctx.drawImage(tileImg, x * TILE_SIZE, y * TILE_SIZE);
      }
    }
  }

  // Render living units from game state
  for (const unit of gameState.units) {
    // Skip destroyed units
    if (unit.y === 255) continue;

    const screenX = unit.x - viewportX;
    const screenY = unit.y - viewportY;

    // Skip off-screen units
    if (screenX < 0 || screenX >= VIEWPORT_WIDTH) continue;
    if (screenY < 0 || screenY >= VIEWPORT_HEIGHT) continue;

    // Unit tiles start at index 22 (0x74 - 0x5E)
    const unitTileBase = 22;
    const tileIndex = unitTileBase + unit.type;
    const tileImg = tileImages.get(tileIndex);

    if (tileImg) {
      ctx.drawImage(tileImg, screenX * TILE_SIZE, screenY * TILE_SIZE);
    }
  }
}

// Handle keyboard input for scrolling
function handleKeyboard(e: KeyboardEvent): void {
  if (!gameRunning) return;

  const scrollSpeed = 1;

  switch (e.key) {
    case 'ArrowLeft':
      viewportX = Math.max(0, viewportX - scrollSpeed);
      break;
    case 'ArrowRight':
      viewportX = Math.min(MAP_WIDTH - VIEWPORT_WIDTH, viewportX + scrollSpeed);
      break;
    case 'ArrowUp':
      viewportY = Math.max(0, viewportY - scrollSpeed);
      break;
    case 'ArrowDown':
      viewportY = Math.min(MAP_HEIGHT - VIEWPORT_HEIGHT, viewportY + scrollSpeed);
      break;
    default:
      return;
  }

  e.preventDefault();
  requestAnimationFrame(() => render());
}

// Handle mouse movement for cursor tracking
function handleMouseMove(e: MouseEvent): void {
  if (!gameRunning) return;

  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) return;

  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;

  const canvasX = (e.clientX - rect.left) * scaleX;
  const canvasY = (e.clientY - rect.top) * scaleY;

  // Convert to map coordinates
  const tileX = Math.floor(canvasX / TILE_SIZE) + viewportX;
  const tileY = Math.floor(canvasY / TILE_SIZE) + viewportY;

  // Clamp to map bounds
  cursorMapX = Math.max(0, Math.min(MAP_WIDTH - 1, tileX));
  cursorMapY = Math.max(0, Math.min(MAP_HEIGHT - 1, tileY));

  cursorRenderer.setCursorPosition(cursorMapX, cursorMapY);
  requestAnimationFrame(() => render());
}

// Handle mouse click for unit selection and actions
function handleMouseClick(e: MouseEvent): void {
  if (!gameRunning) return;

  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) return;

  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;

  const canvasX = (e.clientX - rect.left) * scaleX;
  const canvasY = (e.clientY - rect.top) * scaleY;

  const tileX = Math.floor(canvasX / TILE_SIZE) + viewportX;
  const tileY = Math.floor(canvasY / TILE_SIZE) + viewportY;

  // Clamp to map bounds
  const mapX = Math.max(0, Math.min(MAP_WIDTH - 1, tileX));
  const mapY = Math.max(0, Math.min(MAP_HEIGHT - 1, tileY));

  const clickedUnit = gameState.getUnitAt({ x: mapX, y: mapY });

  // Toggle unit selection
  if (clickedUnit && clickedUnit.owner === gameState.currentPlayer) {
    if (gameState.selectedUnit === clickedUnit) {
      gameState.selectedUnit = null;
    } else {
      gameState.selectedUnit = clickedUnit;
    }
  } else if (!clickedUnit && gameState.selectedUnit) {
    // Deselect if clicking empty tile
    gameState.selectedUnit = null;
  }

  requestAnimationFrame(() => render());
}

// Handle right-click to deselect
function handleRightClick(e: MouseEvent): void {
  e.preventDefault();
  if (!gameRunning) return;

  gameState.selectedUnit = null;
  requestAnimationFrame(() => render());
}

// Handle end turn
function handleEndTurn(): void {
  if (!gameRunning) return;

  // Deselect any selected unit
  gameState.selectedUnit = null;

  // Advance the turn
  advanceTurn(gameState);

  // Check for victory
  const result = checkVictory(gameState);
  if (result) {
    handleVictory(result.winner, result.condition);
    return;
  }

  // Update UI
  gameChrome.update(gameState);
  requestAnimationFrame(() => render());
}

// Handle victory condition
function handleVictory(winner: Player, condition: VictoryCondition): void {
  gameRunning = false;
  victoryScreen.show(winner, condition);
}

// Start a new game
function startGame(): void {
  // Reset game state
  gameState = new GameState();
  viewportX = 0;
  viewportY = 0;

  // Update UI
  gameChrome.update(gameState);

  // Show game screen
  showScreen('game');
  gameRunning = true;

  // Initial render
  requestAnimationFrame(() => render());
}

// Main render function
function render(): void {
  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  // Disable image smoothing for crisp pixels
  ctx.imageSmoothingEnabled = false;

  // Update pulse animation
  cursorRenderer.updatePulse(performance.now());

  // Render layers
  renderMap(ctx);
  cursorRenderer.render(ctx, gameState, viewportX, viewportY);

  // Update UI
  statusBar.update(gameState, cursorMapX, cursorMapY);
}

// Initialize the game
async function init(): Promise<void> {
  console.log('Weltendaemmerung - Web Port');
  console.log(`Map size: ${MAP_WIDTH}x${MAP_HEIGHT}`);

  // Get root element for screen injection
  const root = document.getElementById('app-root') || document.body;

  // Initialize UI components (inject templates)
  titleScreen.init(root);
  gameChrome.init(root);
  victoryScreen.init(root);
  statusBar.init();

  // Initialize screen state
  initScreens();

  // Set up callbacks
  titleScreen.onStart(() => startGame());
  victoryScreen.onPlayAgain(() => {
    showScreen('title');
  });
  gameChrome.onEndTurn(() => handleEndTurn());

  // Load tile assets
  await loadAllTiles();

  // Setup input handlers
  document.addEventListener('keydown', handleKeyboard);

  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (canvas) {
    canvas.addEventListener('mousemove', handleMouseMove);
    canvas.addEventListener('click', handleMouseClick);
    canvas.addEventListener('contextmenu', handleRightClick);
  }

  console.log('Ready! Click START GAME to begin.');
}

// Start the game
init().catch(console.error);
