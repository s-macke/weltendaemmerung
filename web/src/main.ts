// Weltendaemmerung - Web Port Entry Point
// A Commodore 64 fantasy strategy game for two players

import { C64_COLORS } from './utils/colors';
import { MAP_WIDTH, MAP_HEIGHT, MAP_CHAR_CODES } from './data/map';
import { INITIAL_UNITS } from './data/initialUnits';

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

      const charCode = MAP_CHAR_CODES[mapY * MAP_WIDTH + mapX];
      if (charCode === undefined) continue;

      const tileIndex = charCodeToTileIndex(charCode);
      const tileImg = tileImages.get(tileIndex);

      if (tileImg) {
        ctx.drawImage(tileImg, x * TILE_SIZE, y * TILE_SIZE);
      }
    }
  }

  // Render units on visible area
  for (const unit of INITIAL_UNITS) {
    const screenX = unit.x - viewportX;
    const screenY = unit.y - viewportY;

    // Skip off-screen units
    if (screenX < 0 || screenX >= VIEWPORT_WIDTH) continue;
    if (screenY < 0 || screenY >= VIEWPORT_HEIGHT) continue;

    // Unit tiles start at index 22 (0x74 - 0x5E)
    // Types 0-6 are Eldoin, types 7-15 are Dailor
    const unitTileBase = 22; // tile_22.png = first unit sprite
    const tileIndex = unitTileBase + unit.type;
    const tileImg = tileImages.get(tileIndex);

    if (tileImg) {
      ctx.drawImage(tileImg, screenX * TILE_SIZE, screenY * TILE_SIZE);
    }
  }
}

// Update status bar
function updateStatusBar(): void {
  const statusBar = document.getElementById('status-bar');
  if (statusBar) {
    statusBar.textContent = `ELDOIN BEWEGUNGSPHASE | Map: ${MAP_WIDTH}x${MAP_HEIGHT} | Units: ${INITIAL_UNITS.length} | View: (${viewportX}, ${viewportY})`;
  }
}

// Handle keyboard input for scrolling
function handleKeyboard(e: KeyboardEvent): void {
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

// Main render function
function render(): void {
  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  // Disable image smoothing for crisp pixels
  ctx.imageSmoothingEnabled = false;

  renderMap(ctx);
  updateStatusBar();
}

// Initialize the game
async function init(): Promise<void> {
  console.log('Weltendaemmerung - Web Port');
  console.log(`Map size: ${MAP_WIDTH}x${MAP_HEIGHT}`);
  console.log(`Units: ${INITIAL_UNITS.length}`);

  // Load tile assets
  await loadAllTiles();

  // Setup keyboard controls
  document.addEventListener('keydown', handleKeyboard);

  // Initial render
  render();

  console.log('Ready! Use arrow keys to scroll the map.');
}

// Start the game
init().catch(console.error);