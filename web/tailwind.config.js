/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // C64 Color Palette
        c64: {
          black:      '#000000',  // $00 - Dailor units, meadow pattern
          white:      '#FFFFFF',  // $01 - End markers, cursor
          red:        '#683B2B',  // $02 - Forest
          cyan:       '#70A4B2',  // $03
          purple:     '#6F3D86',  // $04 - Title screen menu
          green:      '#588D43',  // $05 - Map background
          blue:       '#352879',  // $06 - Border, river, swamp
          yellow:     '#B8C76F',  // $07 - Eldoin units
          orange:     '#6F4F25',  // $08
          brown:      '#433900',  // $09
          'light-red':   '#9A6759',  // $0A - Attack mode cursor
          'dark-gray':   '#444444',  // $0B - UI elements, walls, gates
          gray:       '#6C6C6C',  // $0C
          'light-green': '#9AD284',  // $0D
          'light-blue':  '#6C5EB5',  // $0E - Title screen text
          'light-gray':  '#959595',  // $0F
        },
      },
      fontFamily: {
        mono: ['monospace'],
      },
    },
  },
  plugins: [],
};