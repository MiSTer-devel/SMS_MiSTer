;----------------------------------------------------------------------------
; Sega Master System & Game Gear - VDP functions
; by Omar Cornut (Bock)
; Started on February 2001
; Last update: 10 November 2001
;----------------------------------------------------------------------------

; VDP_INIT() ----------------------------------------------------------------
; Initialize default VDP registers, clear VRAM, clear sprites
;----------------------------------------------------------------------------
; no parameters
;----------------------------------------------------------------------------
vdp_init:
                in      a, (VDP_STATUS)         ; Read VDP status once
                ld      hl, vdp_init_table      ; before using VDP
                ld      b, 11*2                 ;
                ld      c, VDP_ADDR             ; Then upload default
                otir                            ; registers.
; VDP_CLEAR() ---------------------------------------------------------------
; Clear VRAM, clear sprites
;----------------------------------------------------------------------------
; no parameters
;----------------------------------------------------------------------------
vdp_clear:                                      ;
                ld      de, $0000               ; Clear VRAM
                rst     $18                     ; Set VDP address to DE
                ld      bc, VRAM_SIZE           ;
vdp_clear_loop:                                 ;
                xor     a
                out     (VDP_DATA), a           ;
                dec     bc                      ;
                ld      a, b                    ;
                or      c                       ;
                jr      nz, vdp_clear_loop      ;
; VDP_DISABLE_SPRITES() -----------------------------------------------------
; Clear sprites (by setting the first sprite position to 208)
;----------------------------------------------------------------------------
; no parameters
;----------------------------------------------------------------------------
vdp_disable_sprites:
                ld      de, VRAM_SPR_MAP        ; Disable sprites
                rst     $18                     ;
                ld      a, VRAM_SPR_LAST        ;
                out     (VDP_DATA), a           ;
                ret
;----------------------------------------------------------------------------
vdp_init_table:
.db             $16, $80,  $80, $81,  $FF, $82,  $FF, $83,  $FF, $84
.db             $FF, $85,  $FB, $86,  $00, $87,  $00, $88,  $00, $89
.db             $00, $8A
;----------------------------------------------------------------------------

; VDP_FRAME() / VDP_FRAME_ONE() ---------------------------------------------
; Wait for one or more frame to pass
;----------------------------------------------------------------------------
;  b = number of frames to wait for
;----------------------------------------------------------------------------
vdp_frame_one:
        ld      b, 1
vdp_frame:
        xor     a
        ld      (VAR_frame_cnt), a
vdp_frame_loop:
        ld      a, (VAR_frame_cnt)
        and     $FF
        jr      z, vdp_frame_loop
        djnz    vdp_frame
        ret
;----------------------------------------------------------------------------

; VDP_LOAD_DATA() -----------------------------------------------------------
; Load data from given source to video memory
;----------------------------------------------------------------------------
; bc = number of bytes
; hl = source in ROM/RAM
; de = destination in VRAM
;----------------------------------------------------------------------------
vdp_load_data:
                push    hl
                rst     $18                     ; Set VDP address to DE
vdp_load_data_loop:
                ld      a, (hl)
                inc     hl
                out     (VDP_DATA), a
                dec     bc
                ld      a, b
                or      c
                jr      nz, vdp_load_data_loop
                pop     hl
                ret
;----------------------------------------------------------------------------

; VDP_BG_PUTIMAGE() ---------------------------------------------------------
; Put image to background tile map
;----------------------------------------------------------------------------
;  b = image width (in tile)
;  c = image height (in tile)
;  d = starting tile number
;  e = attribute (automatically set bit 0 when d overflow)
; hl = VRAM address
;----------------------------------------------------------------------------
vdp_bg_putimage:
                push    bc
                push    de
                push    hl

vdp_bg_putimage_y:
                rst     $28                     ; Set VDP address to HL
                push    bc
vdp_bg_putimage_x:
                ld      a, d
                out     (VDP_DATA), a
                push    ix
                pop     ix
                ld      a, e
                out     (VDP_DATA), a
                inc     d
                jr      nz, vdp_bg_putimage_attr_end
                set     0, e
vdp_bg_putimage_attr_end:
                djnz    vdp_bg_putimage_x
                ld      bc, 32*2
                add     hl, bc
                pop     bc
                dec     c
                jr      nz, vdp_bg_putimage_y

                pop     hl
                pop     de
                pop     bc
                ret
;----------------------------------------------------------------------------

; VDP_SET_PAL() -------------------------------------------------------------
; Set palette
;----------------------------------------------------------------------------
;  a = starting color
;  b = number of colors
; hl = data source
;----------------------------------------------------------------------------
vdp_set_pal:
                out     (VDP_ADDR), a           ;
                ld      a, %11000000            ;
                out     (VDP_ADDR), a           ;
vdp_set_pal_loop:                               ;
                ld      a, (hl)                 ;
                out     (VDP_DATA), a           ;
                inc     hl                      ;
                djnz    vdp_set_pal_loop        ;
                ret                             ;
;----------------------------------------------------------------------------

; VDP_FADE() ----------------------------------------------------------------
; Fade palette
;----------------------------------------------------------------------------
; hl = address of fade data
;  a = starting affected color
;  b = number of colors per step
;  c = number of steps
;  d = tempo between steps
;----------------------------------------------------------------------------
vdp_fade:
                push    af
                push    bc
                call    vdp_set_pal
                ld      b, d
                call    vdp_frame
                pop     bc
                pop     af
                dec     c
                jr      nz, vdp_fade
                ret
;----------------------------------------------------------------------------

