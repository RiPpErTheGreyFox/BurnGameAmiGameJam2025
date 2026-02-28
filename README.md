WIP of the AmiGameJam 2025 entry I'm working on

AmiGameJam 2025 entry by RiPpEr253
Started technically November 1st
Started properly January 1st

Side scrolling/single screen beat'em up/shooter where you play as a furry firefighter (two players/multiple characters with different attacks time permitting)

Target system is a stock A500 (7mhz 68000, OCS, 512k Chipmem and no fast/slow mem) with game loaded from single 880k floppy (check compatible with HDD and on ECS/AGA via emulation)

Resolution/Colour, 320x200 (NTSC), 320x256 (PAL), 32 colours 

Art style: Metal Slug-esque, short stubby wide characters, equipped with firehoses/extinguishers

Basic Gameplay: walk on screen, fire based enemies (like brimstone horrors) spawn and move about and throw fireballs

16x16 tiles, full scrolling background, levels stored as files that are loaded from disk (or statically compiled), each level has it's own tileset, use aseprite to manage them and export to plain ASCII text files

Things needed:
Tile Renderer - takes a tile and blits it onto the bitplane
Level Manager - load level from text and setup tiles and map for scrolling
Sprite Renderer - takes the metasprites in memory and ensures they're drawn
^ Needs to handle mouse/players/projectiles/enemies
Sound Manager - handles PCM/sound effects
Music Manager - handles tracker music
Control Manager - take joystick/CD32 controller/Keyboard input and set move flags (make keyboard remappable?), allow player 1/2 selectable
Player Manager - keep track of everything for a single player, have two full managers
Enemy Manager - handles enemy units (updates/ai/calling draws)
Game Manager - owns the current game state and loop, player number, invoking the other mangers/subroutines as needed
Scene Manager - probably has crossover with game manager
Start Screen Manager - handles attract mode and allows player number selection

List a things to make the MVP possible:
*Character on screen
*Controller moving character
*Character being affected by gravity
*Enemy spawning/moving/collision with player
*Projectile spawning/moving/collision with player
/background loading/drawing
*Sound playing

MVP to-do final week of Jan: (failed, working on this still in Feb)
*BIG BLOCK: Come up with level format (needs both graphics and scripts (scroll stops and enemy spawns))
*Play the most basic sound to make sure the system works
*BIG BLOCK: Create a pool allocation for the enemies and projectiles to spawn and be managed
*make players shoot projectiles that kill enemies *(need collision detection written, DONE)
*BIG BLOCK: make enemies touching players kill them (need collision detection written, DONE)
*add player death and respawning (needs state checking added to all updates and the like)

Minimum viable product:
Start screen with basic logo, firefighter moves onto nonscrolling unanimated background, enemies spawn at random intervals, firefighter can attack them, enemies move around at random and can attack randomly, PAL Amiga and possibly overspecced for testing, as long as player can die or clear X number of enemies, MVP is reached, basic sound effects are a bonus

Final stretch tasks:
*Create HUD management functions that can be called from actors to updated the score/health bars
*320x64 resolution
*Contains score 
    and healthbars
*Make a drawn HUD that only redraws when updated
*Create a text renderer that converts binary numbers to BCD and then draws them out using bobs
*Refine the HUD with some graphics
Queue up all required sounds and art to be integrated later in the week
Redesign the level to make it slightly more interesting (cut elevation changes)
*Add health to enemies with knockback and players too
*Add an invulnerable state
Create a title screen that allows player selection

Wednesday to-do list:
*Remove the ground detection and just hit it with a flat plane (for performance)
*Add a second enemy type with different graphics and behaviours
*Add a knockback state to enemies and players
*Add a flashing state to enemies and players
*Add a small invulnerability timer to enemies and players
*Add health to players and enemies
*Adapt a drawing routine for drawing health bars (use the CPU like with font, forget the blitter because of how weirdly shaped they will be)
*Update string renderer to render all characters in the topaz font

Final day to-do list:
*Keyboard handling introduced
*Title screen with keyboard stuff to allow 1 or 2 players
*Moving onto the game scene dependant on that
Update level to be more interesting
Rebalance game at 25hz with half frame time enabled and platforms reenabled
Add new enemy spawns (maybe set them to multiple types? Dunno)
*Have a game-over when running out of lives
    - quits to Amiga OS as fully restarting the game ain't working right
*Update HUD to actually make sense
*Add sounds gotten from Zee to the sound library
Package and test on the 512kb chipmem A500 as that's the target
Remember that animation system only allows for same number of frames in all animations
Add jumping animation that overrides anything else
Art pass on everything (leave until last to ensure most amount of time is spent on everything else, rushed art > not working game)
Something is horribly wrong with the keyboard routines and it is glitchy on AOS 3.2.1 and outright destructive on AOS 1.3
Package and test on the 512kb chipmem A500 again after new art (don't go nuts)
Get back to work on gameboy game any time permitting (or just play trains idk)

Stretch goals:
Multiple players, multiple characters, XP system for the run, bosses, minibosses, multiple enemy types, multiple levels, scrolling levels, using copper to draw high-res score/info at the top of the screen, animated level tile sets, weapon pickups, health pickups, pop ups with dialogue, music, sound effects, NTSC support

List of sounds we'll eventually need:
Player:
    jump
    damaged
    die
    spawn
    landing on ground
    firing
Enemy:
    damaged
    die
    spawn
    firing
Level:
    Ambient Sound?