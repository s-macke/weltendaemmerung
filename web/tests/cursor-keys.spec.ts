import { test, expect } from '@playwright/test';

test.describe('Cursor Key Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for tiles to load
    await page.waitForFunction(() => {
      const logs = (window as any).__loadedTiles;
      return document.querySelector('#game-canvas') !== null;
    });
    // Give time for initial render
    await page.waitForTimeout(500);
  });

  test('arrow keys should scroll the viewport', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await expect(canvas).toBeVisible();

    // Focus the page to receive keyboard events
    await canvas.click();

    // Get initial viewport position by evaluating the global variables
    const getViewport = () => page.evaluate(() => ({
      x: (window as any).viewportX ?? 0,
      y: (window as any).viewportY ?? 0
    }));

    // We need to expose viewport variables - let's check via screenshot comparison instead
    // Take a screenshot before pressing keys
    const screenshotBefore = await canvas.screenshot();

    // Press ArrowRight multiple times to ensure visible change
    await page.keyboard.press('ArrowRight');
    await page.keyboard.press('ArrowRight');
    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(100);

    const screenshotAfterRight = await canvas.screenshot();

    // Screenshots should be different after scrolling right
    expect(screenshotBefore.equals(screenshotAfterRight)).toBe(false);

    // Press ArrowDown multiple times
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(100);

    const screenshotAfterDown = await canvas.screenshot();

    // Should be different from the right-scroll state
    expect(screenshotAfterRight.equals(screenshotAfterDown)).toBe(false);

    // Press ArrowLeft to go back
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowLeft');
    await page.waitForTimeout(100);

    const screenshotAfterLeft = await canvas.screenshot();
    expect(screenshotAfterDown.equals(screenshotAfterLeft)).toBe(false);

    // Press ArrowUp to go back
    await page.keyboard.press('ArrowUp');
    await page.keyboard.press('ArrowUp');
    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(100);

    const screenshotAfterUp = await canvas.screenshot();
    expect(screenshotAfterLeft.equals(screenshotAfterUp)).toBe(false);

    // After going right 3, down 3, left 3, up 3 we should be back at start
    // Compare with original - should be the same (or very close)
    expect(screenshotBefore.equals(screenshotAfterUp)).toBe(true);
  });

  test('ArrowRight key scrolls viewport right', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await canvas.click();

    const before = await canvas.screenshot();

    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(50);

    const after = await canvas.screenshot();

    expect(before.equals(after)).toBe(false);
  });

  test('ArrowLeft key scrolls viewport left (when not at edge)', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await canvas.click();

    // First scroll right to have room to scroll left
    await page.keyboard.press('ArrowRight');
    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(50);

    const before = await canvas.screenshot();

    await page.keyboard.press('ArrowLeft');
    await page.waitForTimeout(50);

    const after = await canvas.screenshot();

    expect(before.equals(after)).toBe(false);
  });

  test('ArrowDown key scrolls viewport down', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await canvas.click();

    const before = await canvas.screenshot();

    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(50);

    const after = await canvas.screenshot();

    expect(before.equals(after)).toBe(false);
  });

  test('ArrowUp key scrolls viewport up (when not at edge)', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await canvas.click();

    // First scroll down to have room to scroll up
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(50);

    const before = await canvas.screenshot();

    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(50);

    const after = await canvas.screenshot();

    expect(before.equals(after)).toBe(false);
  });

  test('viewport does not scroll left past edge', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await canvas.click();

    // We start at (0,0), so pressing left should have no effect
    const before = await canvas.screenshot();

    await page.keyboard.press('ArrowLeft');
    await page.waitForTimeout(50);

    const after = await canvas.screenshot();

    // Should be the same since we're at the left edge
    expect(before.equals(after)).toBe(true);
  });

  test('viewport does not scroll up past edge', async ({ page }) => {
    const canvas = page.locator('#game-canvas');
    await canvas.click();

    // We start at (0,0), so pressing up should have no effect
    const before = await canvas.screenshot();

    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(50);

    const after = await canvas.screenshot();

    // Should be the same since we're at the top edge
    expect(before.equals(after)).toBe(true);
  });
});
