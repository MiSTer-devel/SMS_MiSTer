;----------------------------------------------------------------------------
; Sega Master System & Game Gear basic definitions
; by Omar Cornut (Bock)
; Started on February 2001
; Last update: 10 November 2001
;----------------------------------------------------------------------------

; MEMORY --------------------------------------------------------------------
.DEFINE         PAGE_SIZE               $4000
.DEFINE         PAGE_0                  $0000
.DEFINE         PAGE_1                  (PAGE_0 + PAGE_SIZE)
.DEFINE         PAGE_2                  (PAGE_1 + PAGE_SIZE)
.DEFINE         RAM                     $C000
.DEFINE         RAM_LEN                 $1FF8
.DEFINE         RAM_MIRROR              $E000
.DEFINE         REG_MAP_SRAM            $FFFC
.DEFINE         REG_MAP_0               $FFFD
.DEFINE         REG_MAP_1               $FFFE
.DEFINE         REG_MAP_2               $FFFF
;----------------------------------------------------------------------------

; VIDEO ---------------------------------------------------------------------
.DEFINE         VDP_DATA                $BE
.DEFINE         VDP_ADDR                $BF
.DEFINE         VDP_STATUS              $BF
.DEFINE         VRAM_TILES              $0000
.DEFINE         VRAM_BG_MAP             $3800
.DEFINE         VRAM_SPR_MAP            $3F00
.DEFINE         VRAM_SPR_LAST           208
;----------------------------------------------------------------------------
.DEFINE         VRAM_SIZE               $4000
.DEFINE         VRAM_TILE_SIZE          32            ; (8 * 8) * 4 bits = 32 bytes
;----------------------------------------------------------------------------
.DEFINE         VREG_CONFIG0            $80
.DEFINE         VREG_CONFIG1            $81
; ..
.DEFINE         VREG_BORDER_COL         $87
.DEFINE         VREG_HSCROLL            $88
.DEFINE         VREG_VSCROLL            $89
.DEFINE         VREG_LINES_CNT          $8A
;----------------------------------------------------------------------------

; INPUTS --------------------------------------------------------------------
.DEFINE         PORT_INPUT1             $DC
.DEFINE         P1_UP                   $01
.DEFINE         P1_DOWN                 $02
.DEFINE         P1_LEFT                 $04
.DEFINE         P1_RIGHT                $08
.DEFINE         P1_BUTTON1              $10
.DEFINE         P1_BUTTON2              $20
.DEFINE         P2_UP                   $40
.DEFINE         P2_DOWN                 $80
;----------------------------------------------------------------------------
.DEFINE         P1_UP_BIT               0
.DEFINE         P1_DOWN_BIT             1
.DEFINE         P1_LEFT_BIT             2
.DEFINE         P1_RIGHT_BIT            3
.DEFINE         P1_BUTTON1_BIT          4
.DEFINE         P1_BUTTON2_BIT          5
.DEFINE         P2_UP_BIT               6
.DEFINE         P2_DOWN_BIT             7
;----------------------------------------------------------------------------
.DEFINE         PORT_INPUT2             $DD
.DEFINE         P2_LEFT                 $01
.DEFINE         P2_RIGHT                $02
.DEFINE         P2_BUTTON1              $04
.DEFINE         P2_BUTTON2              $08
.DEFINE         RESET_BUTTON            $10
; Unused                                $20
.DEFINE         LIGHTGUN1               $40
.DEFINE         LIGHTGUN2               $80
;----------------------------------------------------------------------------
.DEFINE         PORT_INPUTGG            $00
.DEFINE         START_BUTTON            $80
;----------------------------------------------------------------------------

; SOUND ---------------------------------------------------------------------
.DEFINE         PORT_PSG                $7F
.DEFINE         PORT_FM_ADDR            $F0
.DEFINE         PORT_FM_DATA            $F1
.DEFINE         PORT_FM_LATCH           $F2
;----------------------------------------------------------------------------

; MISCELLANEOUS -------------------------------------------------------------
.DEFINE         PORT_HARDWARE           $3E
.DEFINE         PORT_NATION             $3F
.DEFINE         PORT_VLINE              $7E
.DEFINE         PORT_HLINE              $7F
;----------------------------------------------------------------------------

; HEADER --------------------------------------------------------------------
.DEFINE         HEADER                  $7FF0
.DEFINE         HEADER_ID               $7FF0 ; TMR SEGA
; ..
.DEFINE         HEADER_CHECKSUM         $7FFA
; ..
.DEFINE         HEADER_SYS_SIZE         $7FFF
;----------------------------------------------------------------------------

