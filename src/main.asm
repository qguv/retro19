include "lib/gbhw.inc"                  ; hardware descriptions
include "src/optim.inc"                 ; optimized instruction aliases

include "src/interrupts.asm"
include "src/music.asm"

section "entry",ROM0[$100]
    nop
    jp start

section "main",ROM0[$0150]

; a = nybble in question
bring_closer_to_eight:
    cp $08
    jr z,.end
    jr c,.raise
.lower
    sub 1
    ret
.raise
    add 1
.end
    ret

start
    ldz                                 ; turn audio off while setting up to save some battery
    ld [rAUDENA],a

    di                                  ; excuse me, I was speaking

; create wavetable in HIRAM
HIRAM_LOC = $80
ANGLE = 0.0
    rept $10
HIGHNIBBLE = (MUL(7.8, SIN(ANGLE)) + 7.8) >> 16
LOWNIBBLE = (MUL(7.8, SIN(ANGLE + 2048.0)) + 7.8) >> 16
    ld a,LOW(LOWNIBBLE | (HIGHNIBBLE << 4))
    ldh [HIRAM_LOC],a
HIRAM_LOC = HIRAM_LOC + 1
ANGLE = ANGLE + 4096.0                  ; circle has 65536.0 degrees, sin range [-1,1]
    endr

; global audio settings
    ld a,$80                            ; turn audio on globally
    ld [rAUDENA],a
    ldz                                 ; WAV channel output OFF (needed?)
    ld [rAUDTERM],a
    ld a,$77                            ; master volume max
    ld [rAUDVOL],a

decrease_volume                         ; cycle through wave samples in hiram buffer and decrease volume
    ld h,$ff                            ; hl = hiram address
    ld l,$80
.next_byte
    ld a,[hl]                           ; get a pair of samples
    ld c,a                              ; save original sample -> c for later
    and $0f                             ; extract the lower nybble
    call bring_closer_to_eight          ; process it to make it quieter
    ld b,a                              ; save processed low nybble -> b
    ld a,c                              ; now extract upper nybble
    rept 4
    srl a
    endr
    call bring_closer_to_eight          ; process it to make it quieter
    rept 4                              ; recombine the two nybbles
    sla a
    endr
    or b
    ld [hl+],a                          ; save new result to hiram
    ld a,l                              ; out of samples?
    cp $90
    jr nz,.next_byte

    ldz                                 ; about to write to buffer, turn off WAV sound
    ld [rAUDTERM],a                     ; WAV channel output off
    ld [rAUD3ENA],a                     ; WAV channel off

; copy from wave buffer to wave sample io registers
.do_copy
    push hl
    ld h,$ff                            ; hl = source (hiram wave sample buffer)
    ld l,$80
    ld b,h                              ; bc = destination (wave sample registers)
    ld c,$30
.next
    ld a,[hl+]
    ld [bc],a
    inc c
    ld a,c
    cp $40
    jr nz,.next
    pop hl

    ld a,$80                            ; WAV channel on
    ld [rAUD3ENA],a
    ld a,$44                            ; WAV channel output on
    ld [rAUDTERM],a
    ld a,$20                            ; don't divide waves
    ld [rAUD3LEVEL],a
    ld a,LOW(c4_freq)                   ; play C2 (low byte)
    ld [rAUD3LOW],a
    ld a,(HIGH(c4_freq) & $07) | $80    ; play C2 (high byte) + some flags + trigger
    ld [rAUD3HIGH],a

wait_loop:
    ldz
    ld b,$48
.loop
    nop
    dec a
    jr nz,.loop
    dec b
    jr nz,.loop
    jr decrease_volume

; vim: se ft=rgbds et ts=4 sts=4 sw=4:
