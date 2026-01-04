// Weltendaemmerung - Web Port Entry Point
// A Commodore 64 fantasy strategy game for two players

import { C64_COLORS } from './utils/colors';
import { MAP_WIDTH, MAP_HEIGHT, getCharCodeAt } from './data/map';
import { GameState } from './game/GameState';
import { CursorRenderer } from './rendering';
import { TitleScreen, VictoryScreen, GameChrome, StatusBar, initScreens, showScreen, VictoryCondition } from './screens';
import { Player, Phase } from './types';
import { advanceTurn } from './game/TurnManager';
import { checkVictory } from './game/VictoryChecker';
import { getAllReachablePositions, executeMovementPath, ReachablePosition } from './game/MovementSystem';
import { canAttack, attackUnit, canAttackStructure, attackStructure } from './game/CombatSystem';
import { canPerformTorphase, performTorphase, getValidTorphasePositions } from './game/FortificationSystem';
import { findGateAt } from './data/gates';
import { GateState } from './game/GameState';

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

// Edge scrolling state
let mouseOverCanvas = false;
let lastMouseX = 0;
let lastMouseY = 0;
const EDGE_SCROLL_ZONE = 16;
let edgeScrollInterval: number | null = null;

// Touch input state
let touchStartX = 0;
let touchStartY = 0;
let touchStartViewportX = 0;
let touchStartViewportY = 0;
let isTouchDragging = false;

// Movement system state - cached reachable positions for selected unit
let cachedReachablePositions: Map<string, ReachablePosition> = new Map();
let lastSelectedUnit: typeof gameState.selectedUnit = null;

// Path preview state - tracks which tile the cursor is hovering over
let hoveredPathKey: string | null = null;

// Load a single tile image
async function loadTile(index: number): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = `./tiles/tile_${index.toString().padStart(2, '0')}.png`;
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

// Tile indices for terrain types (char code - TILE_OFFSET)
const TILE_MEADOW = 0x6A - TILE_OFFSET;   // 12 - Meadow tile
const TILE_PAVEMENT = 0x71 - TILE_OFFSET; // 19 - Pavement tile

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

      let tileIndex: number;

      // Check if this is a gate position with modified state
      const gate = findGateAt({ x: mapX, y: mapY });
      if (gate) {
        const gateState = gameState.getGateState(gate.index);
        switch (gateState) {
          case GateState.Pavement:
            tileIndex = TILE_PAVEMENT;
            break;
          case GateState.Meadow:
            tileIndex = TILE_MEADOW;
            break;
          case GateState.Destroyed:
            tileIndex = TILE_PAVEMENT;
            break;
          default:
            // Original state - use base map tile
            tileIndex = charCodeToTileIndex(getCharCodeAt(mapX, mapY));
        }
      } else {
        // Not a gate position - use base map tile
        const charCode = getCharCodeAt(mapX, mapY);
        tileIndex = charCodeToTileIndex(charCode);
      }

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

  // Track position for edge scrolling
  lastMouseX = e.clientX;
  lastMouseY = e.clientY;

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

  // Update hovered path for path preview (only in movement phase with selected unit)
  if (gameState.phase === Phase.Movement && gameState.selectedUnit) {
    const key = `${cursorMapX},${cursorMapY}`;
    hoveredPathKey = cachedReachablePositions.has(key) ? key : null;
  } else {
    hoveredPathKey = null;
  }

  requestAnimationFrame(() => render());
}

// Process click at map coordinates - shared by mouse and touch
function processClick(mapX: number, mapY: number): void {
  const clickedUnit = gameState.getUnitAt({ x: mapX, y: mapY });
  const target = { x: mapX, y: mapY };

  // FORTIFICATION PHASE: Build gates/walls
  if (gameState.phase === Phase.Fortification) {
    if (canPerformTorphase(gameState, target, gameState.currentPlayer)) {
      performTorphase(gameState, target);
    }
    requestAnimationFrame(() => render());
    return;
  }

  // ATTACK PHASE: Attack enemy units or structures
  if (gameState.phase === Phase.Attack && gameState.selectedUnit) {
    // Attack enemy unit
    if (clickedUnit && clickedUnit.owner !== gameState.currentPlayer) {
      if (canAttack(gameState, gameState.selectedUnit, clickedUnit)) {
        attackUnit(gameState, gameState.selectedUnit, clickedUnit);
        const result = checkVictory(gameState);
        if (result) {
          handleVictory(result.winner, result.condition);
          return;
        }
        requestAnimationFrame(() => render());
        return;
      }
    }
    // Attack structure (gate/wall)
    if (!clickedUnit && canAttackStructure(gameState, gameState.selectedUnit, target)) {
      attackStructure(gameState, gameState.selectedUnit, target);
      requestAnimationFrame(() => render());
      return;
    }
  }

  // MOVEMENT: Move selected unit to any reachable tile (Movement phase ONLY)
  if (gameState.phase === Phase.Movement && gameState.selectedUnit && !clickedUnit) {
    const key = `${mapX},${mapY}`;
    const reachable = cachedReachablePositions.get(key);

    if (reachable) {
      // Execute the full path to the target
      executeMovementPath(gameState, gameState.selectedUnit, reachable.path);
      // Recalculate reachable positions after movement
      cachedReachablePositions = getAllReachablePositions(gameState, gameState.selectedUnit);
      hoveredPathKey = null;
      requestAnimationFrame(() => render());
      return;
    }
  }

  // SELECTION: Toggle unit selection (own units only)
  if (clickedUnit && clickedUnit.owner === gameState.currentPlayer) {
    if (gameState.selectedUnit === clickedUnit) {
      // Deselect
      gameState.selectedUnit = null;
      cachedReachablePositions.clear();
    } else {
      // Select new unit
      gameState.selectedUnit = clickedUnit;
      // Cache reachable positions for the new selection
      if (gameState.phase === Phase.Movement) {
        cachedReachablePositions = getAllReachablePositions(gameState, clickedUnit);
      } else {
        cachedReachablePositions.clear();
      }
    }
    hoveredPathKey = null;
  } else if (!clickedUnit) {
    gameState.selectedUnit = null;
    cachedReachablePositions.clear();
    hoveredPathKey = null;
  }

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
  const mapX = Math.max(0, Math.min(MAP_WIDTH - 1, Math.floor(canvasX / TILE_SIZE) + viewportX));
  const mapY = Math.max(0, Math.min(MAP_HEIGHT - 1, Math.floor(canvasY / TILE_SIZE) + viewportY));

  processClick(mapX, mapY);
}

// Handle right-click to deselect
function handleRightClick(e: MouseEvent): void {
  e.preventDefault();
  if (!gameRunning) return;

  gameState.selectedUnit = null;
  requestAnimationFrame(() => render());
}

// Edge scrolling - scroll viewport when mouse is near edge
function updateEdgeScroll(): void {
  if (!gameRunning || !mouseOverCanvas) return;

  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) return;
  const rect = canvas.getBoundingClientRect();

  const canvasX = lastMouseX - rect.left;
  const canvasY = lastMouseY - rect.top;

  let scrolled = false;
  if (canvasX < EDGE_SCROLL_ZONE && viewportX > 0) { viewportX--; scrolled = true; }
  if (canvasX > rect.width - EDGE_SCROLL_ZONE && viewportX < MAP_WIDTH - VIEWPORT_WIDTH) { viewportX++; scrolled = true; }
  if (canvasY < EDGE_SCROLL_ZONE && viewportY > 0) { viewportY--; scrolled = true; }
  if (canvasY > rect.height - EDGE_SCROLL_ZONE && viewportY < MAP_HEIGHT - VIEWPORT_HEIGHT) { viewportY++; scrolled = true; }

  if (scrolled) requestAnimationFrame(() => render());
}

// Touch handlers for mobile support
function handleTouchStart(e: TouchEvent): void {
  if (!gameRunning || e.touches.length !== 1) return;

  const touch = e.touches[0];
  if (!touch) return;
  touchStartX = touch.clientX;
  touchStartY = touch.clientY;
  touchStartViewportX = viewportX;
  touchStartViewportY = viewportY;
  isTouchDragging = false;
}

function handleTouchMove(e: TouchEvent): void {
  if (!gameRunning || e.touches.length !== 1) return;
  e.preventDefault(); // Prevent page scrolling

  const touch = e.touches[0];
  if (!touch) return;
  const deltaX = touchStartX - touch.clientX;
  const deltaY = touchStartY - touch.clientY;

  // If moved more than 10px, treat as drag
  if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
    isTouchDragging = true;
  }

  if (isTouchDragging) {
    const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;

    // Convert pixel drag to tile scroll
    const tileDeltaX = Math.floor((deltaX * scaleX) / TILE_SIZE);
    const tileDeltaY = Math.floor((deltaY * scaleY) / TILE_SIZE);

    viewportX = Math.max(0, Math.min(MAP_WIDTH - VIEWPORT_WIDTH, touchStartViewportX + tileDeltaX));
    viewportY = Math.max(0, Math.min(MAP_HEIGHT - VIEWPORT_HEIGHT, touchStartViewportY + tileDeltaY));

    requestAnimationFrame(() => render());
  }
}

function handleTouchEnd(e: TouchEvent): void {
  if (!gameRunning) return;

  // Prevent browser from generating synthetic click event after touch
  e.preventDefault();

  // If was dragging, don't process as tap
  if (isTouchDragging) {
    isTouchDragging = false;
    return;
  }

  // Treat as click at start position
  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) return;

  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;
  const canvasX = (touchStartX - rect.left) * scaleX;
  const canvasY = (touchStartY - rect.top) * scaleY;
  const mapX = Math.max(0, Math.min(MAP_WIDTH - 1, Math.floor(canvasX / TILE_SIZE) + viewportX));
  const mapY = Math.max(0, Math.min(MAP_HEIGHT - 1, Math.floor(canvasY / TILE_SIZE) + viewportY));

  // Update cursor position for status bar
  cursorMapX = mapX;
  cursorMapY = mapY;
  cursorRenderer.setCursorPosition(mapX, mapY);

  // Process click (same logic as mouse click)
  processClick(mapX, mapY);
}

// Handle end turn
function handleEndTurn(): void {
  if (!gameRunning) return;

  // Deselect any selected unit and clear movement cache
  gameState.selectedUnit = null;
  cachedReachablePositions.clear();
  lastSelectedUnit = null;
  hoveredPathKey = null;

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

  // Clear movement cache
  cachedReachablePositions.clear();
  lastSelectedUnit = null;
  hoveredPathKey = null;

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

  // Render map
  renderMap(ctx);

  // Update cached reachable positions if selected unit changed
  if (gameState.selectedUnit !== lastSelectedUnit) {
    lastSelectedUnit = gameState.selectedUnit;
    if (gameState.selectedUnit && gameState.phase === Phase.Movement) {
      cachedReachablePositions = getAllReachablePositions(gameState, gameState.selectedUnit);
    } else {
      cachedReachablePositions.clear();
    }
    hoveredPathKey = null;
  }

  // Render valid targets BEFORE cursor
  if (gameState.selectedUnit && gameState.isUnitAlive(gameState.selectedUnit)) {
    if (gameState.phase === Phase.Movement) {
      // Movement targets - show ALL reachable positions (green)
      const allReachable = Array.from(cachedReachablePositions.values()).map(r => r.coord);
      cursorRenderer.renderMoveTargets(ctx, allReachable, viewportX, viewportY);

      // Path preview if hovering over a reachable tile
      if (hoveredPathKey) {
        const hoveredReachable = cachedReachablePositions.get(hoveredPathKey);
        if (hoveredReachable) {
          cursorRenderer.renderPathPreview(ctx, hoveredReachable.path, viewportX, viewportY);
        }
      }
    }

    // Attack range in attack phase (red)
    if (gameState.phase === Phase.Attack) {
      cursorRenderer.renderAttackRange(ctx, gameState, viewportX, viewportY);
    }
  }

  // Fortification targets in torphase (purple)
  if (gameState.phase === Phase.Fortification) {
    const torphaseTargets = getValidTorphasePositions(gameState);
    cursorRenderer.renderTorphaseTargets(ctx, torphaseTargets, viewportX, viewportY);
  }

  // Render cursor
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
    // Mouse events
    canvas.addEventListener('mousemove', handleMouseMove);
    canvas.addEventListener('click', handleMouseClick);
    canvas.addEventListener('contextmenu', handleRightClick);

    // Edge scrolling
    canvas.addEventListener('mouseenter', () => {
      mouseOverCanvas = true;
      edgeScrollInterval = window.setInterval(updateEdgeScroll, 100);
    });
    canvas.addEventListener('mouseleave', () => {
      mouseOverCanvas = false;
      if (edgeScrollInterval) {
        clearInterval(edgeScrollInterval);
        edgeScrollInterval = null;
      }
    });

    // Touch events for mobile
    canvas.addEventListener('touchstart', handleTouchStart, { passive: false });
    canvas.addEventListener('touchmove', handleTouchMove, { passive: false });
    canvas.addEventListener('touchend', handleTouchEnd, { passive: false });
  }

  console.log('Ready! Click START GAME to begin.');
}

// Start the game
init().catch(console.error);
