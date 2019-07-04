;------------------------------------------------------------------------------
; SMS Boot 0.91
; by Omar Cornut (Bock)
; Last updated 28 December 2003
;------------------------------------------------------------------------------

.INCLUDE "sms.inc"

; WlaDX stuffs ----------------------------------------------------------------
.EMPTYFILL $00
.SMSTAG
.COMPUTESMSCHECKSUM
.MEMORYMAP
        DEFAULTSLOT     0
        SLOTSIZE        PAGE_SIZE
        SLOT            0               PAGE_0
        SLOT            1               PAGE_1
.ENDME

.ROMBANKMAP
        BANKSTOTAL      2
        BANKSIZE        PAGE_SIZE
        BANKS           2
.ENDRO
.BANK 0 SLOT 0
;------------------------------------------------------------------------------

; Variables -------------------------------------------------------------------
.DEFINE VAR_frame_cnt           (RAM + $1000)    ; 1 byte
.DEFINE VAR_menu_slot           (RAM + $1001)    ; 1 byte
.DEFINE VAR_menu_sprite_y       (RAM + $1002)    ; 1 byte
;------------------------------------------------------------------------------

; Start -----------------------------------------------------------------------
.ORGA   $0000
        di
        im      1
        ld      sp,     $DFF0
	in	a,($c0) ; special Mist(er) : during bootload, bit7 is game-gear indicator
	bit	7,a
	jr	nz,gamegear_loc
smsstart:
        jp      start
;------------------------------------------------------------------------------

; Tools ---------------------------------------------------------------------
.ORGA   $0010
vdp_write_de:
                ld      a, e
                out     (VDP_ADDR), a
                ld      a, d
                out     (VDP_ADDR), a
                ret
;
;
.ORGA   $0018
vdp_write_addr_de:
                ld      a, e
                out     (VDP_ADDR), a
                ld      a, d
                or      $40
                out     (VDP_ADDR), a
                ret

.ORGA   $0028
vdp_write_addr_hl:
                ld      a, l
                out     (VDP_ADDR), a
                ld      a, h
                or      $40
                out     (VDP_ADDR), a
                ret

; Interrupt -------------------------------------------------------------------
.ORGA   $0038
interrupt:
        di
        push    af
        in      a, (VDP_STATUS)
        and     $80
        jr      z, interrupt_end
        ld      a, (VAR_frame_cnt)
        inc     a
        ld      (VAR_frame_cnt), a
interrupt_end:
        pop     af
        ei
        ret
;------------------------------------------------------------------------------
gamegear_loc:	jp	gamegear

; NMI -------------------------------------------------------------------------
.ORGA   $0066
        reti
;------------------------------------------------------------------------------

; SDSC HEADER DATA ------------------------------------------------------------
sdsc_author:            .db     "wsoltys", 0
sdsc_program_name:      .db     "MiST/MiSTer Boot Loader", 0
sdsc_unused_but_stored: .db     "v0.92", 0
;------------------------------------------------------------------------------

; VDP Library -----------------------------------------------------------------
.INCLUDE "vdp.asm"
; DATA ------------------------------------------------------------------------
tiles_data:
.INCLUDE "tiles.inc"
palette_data:
.INCLUDE "palette.inc"
;------------------------------------------------------------------------------

start:
        call    vdp_init

	; Setup palette for fade start
        ld      a, 0
        ld      b, 5
        ld      hl, pal_table_bg_fade_0
        call    vdp_set_pal

	; Load tiles
        ld      bc, VRAM_TILE_SIZE * GFX_LAST_TILE
        ld      hl, tiles_data
        ld      de, $0000 + (1 * VRAM_TILE_SIZE)
        call    vdp_load_data

	; Draw SEGA logo to map
        ld      b, GFX_SEGA_SIZE_X
        ld      c, GFX_SEGA_SIZE_Y
        ld      d, GFX_SEGA_TILE
        ld      e, 0
        ld      hl, VRAM_BG_MAP + (11*2+(20)*32)
        call    vdp_bg_putimage

	; Draw Master System logo to map
    ;    ld      b, GFX_MASTERSYSTEM_SIZE_X
    ;    ld      c, GFX_MASTERSYSTEM_SIZE_Y
    ;    ld      d, GFX_MASTERSYSTEM_TILE
    ;    ld      e, 0
    ;    ld      hl, VRAM_BG_MAP + (4*2+(12)*32)
    ;    call    vdp_bg_putimage

	; Draw Boot Loader logo to map
    ;    ld      b, GFX_BOOTLOADER_SIZE_X
    ;    ld      c, GFX_BOOTLOADER_SIZE_Y
    ;    ld      d, GFX_BOOTLOADER_TILE
    ;    ld      e, 0
    ;    ld      hl, VRAM_BG_MAP + (1*2+(22)*32)
    ;    call    vdp_bg_putimage

	; Draw SMS Power copyright to map
    ;    ld      b, GFX_SMSPOWER_SIZE_X
    ;    ld      c, GFX_SMSPOWER_SIZE_Y
    ;    ld      d, GFX_SMSPOWER_TILE - 256
    ;    ld      e, 1
    ;    ld      hl, VRAM_BG_MAP + (9*2+(42)*32)
    ;    call    vdp_bg_putimage

	; Reset horizontal scrolling
        ld      de, $8800
        rst     $10

	; Enable display, 16x8 sprites & vblank
        ld      de, $81E2
        rst     $10

	; Fade-in
        xor     a
        ld      b, 5
        ld      c, 4
        ld      d, 10
        ld      hl, pal_table_bg_fade_0
        ei
        call    vdp_fade
        di
        
        ; Enable display & 16x8 sprites, disable vblank
        ld      de, $81C2
        rst     $10

	; Setup final palette
        ld      a, 16
        ld      b, 16
        ld      hl, pal_table_fg
        call    vdp_set_pal

wait_for_rom:
;
	ld 	hl,modelSMS
	ld	de,$c700
	ld	bc,modelSMS_end-modelSMS
	ldir
	ld	ix,$0000
	ld	iy,$0000
	ld	hl,$0293
	ld	sp,$dff0
	ld	a,$ab
	ld	($c000),a
	jp	$c700
;
gamegear:
	call	vdp_clear	; raz vram
	ld	hl,$c000
	xor	a
	ld	(hl),a
	ld	bc,$1FFF
	ld	de,$c001
	ldir			; raz memory
	ld 	hl,modelGG
	ld	de,$c800
	ld	bc,modelGG_end-modelGG
	ldir
	ld	ix,$0000
	ld	iy,$0000
	ld	hl,$00fa
	ld	sp,$dfee
	ld	a,$a8
	ld	($c000),a
	jp     $c800
;
;	
modelSMS:
	ld 	a,$ab
	out	($3e),a
	jp	$0000
modelSMS_end:
modelGG:
	ld	a,$a8
	out	($3e),a
	jp	$0000
modelGG_end:
	.db	0

;------------------------------------------------------------------------------

boot_end:

.BANK 1 SLOT 1

; SDSC HEADER -----------------------------------------------------------------
.ORGA   $7FE0
        .DB     "SDSC"                  ; Magic
        .DB     $00, $91                ; Version 0.91
        .DB     $12                     ; 17
        .DB     $11                     ; November
        .DW     $2001                   ; 2001
        .DW     sdsc_author
        .DW     sdsc_program_name
        .DW     $FFFF

; CHECKSUM --------------------------------------------------------------------
.ORGA   $7FF0

	.DB	"TMR SEGA"	; Trademark
	.DW     $0120           ; Year
	.DW	$0000		; Checksum not correct
	.DW	$0000		; Part Num not correct
	.DB     $01             ; Version
	.DB     $4C             ; Master System, 32k
;
