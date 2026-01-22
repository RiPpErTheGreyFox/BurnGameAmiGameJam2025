

                IFND	GLOBALS_I
GLOBALS_I      SET	1

;---------- Constants ---------
                            ;5432109876543210
DMASET                      EQU %1000001111000000     ; enable only copper, bitplane and blitter DMA
NUM_COLORS                  EQU 16
N_PLANES                    EQU 4
DISPLAY_WIDTH               EQU 320
DISPLAY_HEIGHT              EQU 256
DISPLAY_PLANE_SIZE          EQU DISPLAY_HEIGHT*(DISPLAY_WIDTH/8)
DISPLAY_ROW_SIZE            EQU (DISPLAY_WIDTH/8)
IMAGE_WIDTH                 EQU 32
IMAGE_HEIGHT                EQU 32
IMAGE_PLANE_SIZE            EQU IMAGE_HEIGHT*(IMAGE_WIDTH/8)
TILESET_WIDTH               EQU 320
TILESET_HEIGHT              EQU 304
TILESET_ROW_SIZE            EQU (TILESET_WIDTH/8)
TILESET_PLANE_SIZE          EQU (TILESET_HEIGHT*TILESET_ROW_SIZE)
TILESET_COLS                EQU 20
TILEMAP_ROW_SIZE            EQU 268*2
TILE_WIDTH                  EQU 16
TILE_HEIGHT                 EQU 16
BGND_WIDTH                  EQU 2*DISPLAY_WIDTH+2*16
BGND_HEIGHT                 EQU 192
BGND_PLANE_SIZE             EQU BGND_HEIGHT*(BGND_WIDTH/8)
BGND_ROW_SIZE               EQU (BGND_WIDTH/8)
VIEWPORT_HEIGHT             EQU 192
VIEWPORT_WIDTH              EQU 320
SCROLL_SPEED                EQU 2
SCROLL_THRESHOLD_X_RIGHT    EQU 240

;---------- Variables ---------
camera_x            dc.w 0*16
bgnd_x              dc.w 0
map_ptr             dc.w 0
view_buffer         dc.l dbuffer1       ; buffer displayed on screen
draw_buffer         dc.l dbuffer2       ; drawing buffer (not visible)


	ENDC	; GLOBALS_I