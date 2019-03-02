include "lib/gbhw.inc"		; hardware descriptions
include "src/optim.inc"		; optimized instruction aliases

include "src/interrupts.asm"
include "src/music.asm"

section "entry",ROM0[$100]
    nop
    jp start

section "main",ROM0[$0150]

start
    di

init_sound
    xor a

    ldz                                 ; WAV channel off
    ld [rAUD3ENA],a

ANGLE = 0.0
WAVSTEP = $30
    rept $10
HIGHNIBBLE = (MUL(7.8, SIN(ANGLE)) + 7.8) >> 16
LOWNIBBLE = (MUL(7.8, SIN(ANGLE + 2048.0)) + 7.8) >> 16
    ld a,LOW(LOWNIBBLE | (HIGHNIBBLE << 4))
    ldh [WAVSTEP],a
ANGLE = ANGLE + 4096.0			; circle has 65536.0 degrees, sin range [-1,1]
WAVSTEP = WAVSTEP + 1
    endr

    ld a,$80                            ; WAV channel on
    ld [rAUD3ENA],a
    ld a,$60                            ; WAV to max volume
    ld [rAUD3LEVEL],a
    ld a,LOW(c4_freq)                   ; play C2 (low byte)
    ld [rAUD3LOW],a
    ld a,(HIGH(c4_freq) & $07) | $80    ; play C2 (high byte) + some flags
    ld [rAUD3HIGH],a
    ld a,$77                            ; master volume max
    ld [rAUDVOL],a
    ld a,$44                            ; WAV channel output
    ld [rAUDTERM],a

wait_loop                           ; idle loop waiting for next int
    halt
    nop
    jr wait_loop

; vim: se ft=rgbds:
