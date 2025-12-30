# Weltendaemmerung Memory Layout

This document describes the memory layout used by the C64 game "Weltendaemmerung".

## Overview

| Region             | Address Range | Size       | Description                                |
|--------------------|---------------|------------|--------------------------------------------|
| Program Code       | $0801-$23D7   | 7126 bytes | Main program (BASIC header + machine code) |
| Game Variables     | $0340-$035F   | 32 bytes   | Runtime game state                         |
| Extended Variables | $4FF0-$500A   | 27 bytes   | Unit counters and town flags               |
| Map Data           | $5000-$5FA0   | 4000 bytes | Game map (80x40 tiles)                     |
| Screen RAM         | $C000-$C3E7   | 1000 bytes | VIC-II screen memory                       |
| Sprite Pointers    | $C3F8-$C3FF   | 8 bytes    | Sprite block pointers                      |
| Sprite Data        | $C400-$C43F   | 64 bytes   | Cursor sprite data                         |
| Color RAM          | $D800-$DBE7   | 1000 bytes | Character color attributes                 |
| Custom Characters  | $E2F0+        | ~256 bytes | Modified character patterns                |
