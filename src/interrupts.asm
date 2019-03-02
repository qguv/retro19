section "V-Blank IRQ Vector",ROM0[$40]
VBL_VECT:
	reti

section "LCD IRQ Vector",ROM0[$48]
LCD_VECT:
	reti

section "Timer IRQ Vector",ROM0[$50]
TIMER_VECT:
	reti

section "Serial IRQ Vector",ROM0[$58]
SERIAL_VECT:
	reti

section "Joypad IRQ Vector",ROM0[$60]
JOYPAD_VECT:
	reti
