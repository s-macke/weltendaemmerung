https://www.commodoregames.net/Commodore64/Weltendammerung-8543.html

A 7kB binary weltendaemmerung is present. Let's just analyze it.
`Analyze the binary file weltendaemmerung.bin`
`Write a short summary in CLAUDE.md`
I remove al the unnecccary stuff such as publisher and author.
Keep some technical information.

/clear
/plan
`Write a C64 disassembler for the welterdaemmerung.bin file in Python. Put it into the "tools" directory. Make a flow analysis, so that you can differ between code and
data`
The output was just too verbose. He put the hex values of the decoded instructions in there as well.
`I neither need the disassembly hex code, not the position of each instruction, Just remove the unnecessary comments.`
`Remove the text detection. Instead show the binary parts like in a hex editor.`

`Move the disassembly as well as the bin file into its own disassembly folder.`

`Reference the disassembly in CLAUDE.md`

/clear
`The goal ist to split the weltemdaemmerung.asm file into multiple smaller files, which are then referenced inside claude.md. All file names should start
with the start and end address.`

export MAX_MCP_OUTPUT_TOKENS=50000

/plan

`Split the weltemdaemmerung.asm file into multiple smaller files, which are then referenced inside claude.md. All file names should start
with the start and end address and a short description. Figure out the technical as well as functional parts of the asm file first.`

/clear
`Write a script, which automaticcally checks if the content in archive/weltendaemmeriung.asm matches the modules`


/clear
/agent
`Check all assembler files and figure out the memory layout used. Then write a markdown file with a single table with the results into the docs folder.`
`Reference the file inside CLAUDE.md`

I had shorten the file a little bit, as it begun to put write variable information inside the file

`Write a single variables markdown file with one single table with a list of all variables of all game state variables`.

/clear
/plan

`Based on variables.md annotate the lines in the assembler file with the corresponding comment about the variable.`

/clear
/plan
`Extract the tiles used in this game and store these tiles in the assets folder.`
`Do the tiles come with color information about foreground and background color.`


`That is impossible that all characters are gray. This doesn't match, what you said before.`
The tiles are used in different contextes. So, make one assumption.

`Let us assume, that all tiles are shown on the map screen. What would be the background color?`
`Comment in the assembly files what you have learned.`


/clear
/agent
`Extract the different terrain types from the assembler files and write them into docs/map.md.`
`Can you correlate the terrain types with the tiles?`
`Comment in the assembly files what you have learned.`
`Don't remove the variable names inside the assembler files.`
`Update claude.md with file references`


/clear
`Take a look at the sound_effects file. It does seem, it is wrongly annotated with terrain information, Please refactor this file, so that it maps`
`Check all assembler files. Are there more severe mismatches?`

# Map drawing

/clear
/plan
`Read map.md and extract the map with correct tiles and colors. Do not assets/tiles as they don't have the correct color.`

`Check the background color of the map. This is not black.`
`Update map.md to match the new information in this session`

`Now, update the tiles color with this new information.`

# Initial placing of units
Parallel I did:
`display all tiles*.png in a 8-column grid`

# Initial placing of units
/clear
`Look at map.md and determine the initial placing of units of the map. Document inside units.md.`
I removed around 80% of useless information from the unit.md file.
`Update claude.md`

At this time I realized, that sometimes TOWN is used as term. But there are no towns in the game.
`To my knowledge, there are no towns in the game. Why now?`

It fixes all towns to gates.

# Variable fixes

/clear
`Check all assembler files and fix the variables.md file with this.`
It renamed the variables, but not subsequent comments.
`Check again, you didn't fix all X and Y flips`


# Load and store

/clear
`Take a look at the load/store routines and figure out, what is actually stored in the file. This is the full state of the game. Write an appropriate doc
file`


/clear

# Color Map Fix

/clear
`I am sure, that forest has the color red. Check map.md and check all mappings regarding the color.`

`Which tile file is forest?`
`I am 100% sure, that tile_13.png is not forest. Forest is tile_14.png.`


# Movement Phase

`Analyze the movement phase and write a movement.md document.`
`Use Mermaid diagram in movement.md instead of ascii art.`

At this point I realized, that edge is the wrong name for the terrain field and chose end-marker.
`Rename edge to end-marker`

# Clarify Warship Movement

`In Movement.md there is warship mentioned and water related logic. Can you clarify on these?`


# Attack Phase
`Analyze the attack/combat phase and write a document in the docs directory.`

`Do you see any reason, why cvatapult has a special logic?`

A lot of utility functions are called. Let us also comment these.
`Can you also comment the coresponding utilities assembler functions?`

`What a strange varialble: COUNTER. What does this variable mean exactly?`

# Fortification Phase

`Analyze the fortification phase and write a document in the docs directory.`

`Check why is a gate blocked. Maybe because a unit is at that position?`

`What happens if a unit os occupying a gate?`
`Can I change a gate to open or close if an unit occupies that state?`
`Sounds like a bug, because the underlying gate is open, the underlying map should be meadow. If the gate is closed, the meadow is still stored in the
units data field.`
It inserts a potential bug note at the corresponding places.

`Check the attack phase again. Can all units destroy a gate`


# Flow

`Check Flow documentation.`
`Also check sprite/cursor handling and document in flow.`
`Any other inconsistencies`


# Title

`Analyze the title screen and write a document.`
`Add to CLAUDE.md`

# Screen

Write a small document about the screen during the different phases. How does it look.

TODO: # Add references to program_flow to files.

# Overall check

`Check all assembler files. Any core game mechanic, which is not covered in comments?`


# Port

First, install playwright Plugin.

Now that we have everything, we can reduce the CLAUDE.md file 

Port this game to a web application
* Technology: vite, typescript and tailwind.
* Do not use BCD format. 
* No sound
* No load and store
* Don't skip the title screen
* For the map and the units use the C64 colors and tiles.
* Mouse control. Use different mouse pointers if possible. (See sprite/cursor handling)
* Implement the exact rulebook.
* The visuals can be more modern with retro style. But don't skip any information such as terrain data or unit stats.
* Phase/player change over a end-turn button.
* Read the full documentation first.
* Language is english. Translate every German word to English.
* Write a porting markdown file, with a design and an implementation plan.
* Reference the documentation files in the markdown file when necessary.
web subdirectory
edge scrolling


## UI

Use the frontend design skill to design a nice retro-modern look for the webapp under /web. Examine first the the PORING.md file.

