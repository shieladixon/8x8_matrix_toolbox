#target BIN

#code PAGE1,$100

WIDTH_OF_SPACE		equ 3

buffer_length		equ $16		; the actual number of cells / pixels.  We sent this / 8  to the display, 8 bits per byte

LED_ON_TIME		equ $0030		; play with these two figures to change the intensity of the LEDs
LED_OFF_TIME	equ $0090		; this is the duty cycle

scroll_speed		equ	$000A	; ff is about 6 seconds

select_row_port 	equ 00
select_columns_port	equ 02

;=========================================================
; intro
			call printCR

			ld HL,introduction
			call print_str


;=========================================================
; init


			ld HL,buffer1
			ld B,1			; shifts 1, 2, 4, 8 etc
							; when 0, set to 1 again, and reset HL to chr_data
							
			call reset_scrolly
			;call get_next_char
			;call chr_A_into_buffer

			ld de,scroll_speed
			
			ld a,7
			ld (shift_counter),a

;=========================================================
; main loop

main_loop
			
			

			call display_data_at_row	; includes on time and off time
		
			
			inc hl
			sla b
			jr nz,end_outer_divide
			

				; main loop already divided by 8 here
				; further divide
				dec de
				ld a,d
				or e
				cp 0
				jr nz,end_inner_divide
			
			
					call scroll_buffer		; affects b, hl
				
				
					; every 8 of these
					ld hl,shift_counter
					dec (hl)
					ld a,(hl)
					cp 0
					jr nz,end_inner_divide2
			
						;get next char in a
						
						call get_next_char
						call chr_A_into_buffer	; now sets shift_counter according to proportional font
			
end_inner_divide2
			
				ld de,scroll_speed
			
end_inner_divide
	
				; finally
				ld HL,buffer1
				ld B,1
			
end_outer_divide			
			
			
			; do we have a keypress? if not, loop back to main loop
			push HL
			push BC
			push de
			ld C,$0b
			call 5
			pop de
			pop BC
			pop HL
			
			cp 0	
			jp z,main_loop

			; otherwise
			ret






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; subroutines


display_data_at_row:
			; data should be in (hl)
			; row number in b reg

			ld c,select_row_port
			ld	a,b
			out (c),a
			ld c,select_columns_port
			ld	a,(HL)
			out (c),a
			call delay_on_time
			
			ld c,select_columns_port
			ld	a,0
			out (c),a
			call delay_off_time	; the rest of the code below will delay a small amount	
			ret








ascii_counter	defb $20
get_next_char
			;get next char in a
			ld hl,(message_pointer)
			inc hl
			ld (message_pointer),hl

			ld hl,(message_pointer)
			ld a,(hl)
			
			cp 0
			jr nz, not_message_end
				call reset_scrolly
				ld hl,(message_pointer)
				ld a,(hl)
not_message_end
			ret




			; for now
			ld a,(ascii_counter)
			inc a
			ld (ascii_counter),a
			cp $7f
			jr nz,gnc_ret
			
			ld a,$20
			ld (ascii_counter),a
gnc_ret		ret





			
			
reset_scrolly

			call clr_buffer1
			ld hl,scrolly
			ld (message_pointer),hl
			
			ld hl,(message_pointer)
			ld a,(hl)
			call chr_A_into_buffer

			ret



			
character_counter defb 00



print_Msg	
			ld A,0
			ld(character_counter),A


pm_loop	
			
			ld IY,buffer1
			

			
			ld HL,message			; ld HL, message + msg_ptr
			ld A,(msg_ptr)
			ld B,0
			ld C,A
			add HL,BC
			push HL
			
			; y & x in BC
			
			
			
			ld A,(msg_ptr)
			sla A
			sla A
			sla A
			
			ld IX,x_offset
			add A,(IX)


			;cp LINEWIDTH+1
			;jr c,pm_not_end_yet
			
			; early bath
			;pop HL
			;ret
			
	
		


clr_buffer1

			ld BC,buffer_length
			ld HL,buffer1
			
cb1_lp	
			ld A,0
			ld (HL),A

			inc HL
			dec BC
			ld A,B
			or C
			cp 0
			jr nz,cb1_lp
			
			ret
			
			


chr_A_into_buffer			; ascii value in A


		; we start at $20
		sub $20
		
		;a into c
		ld c,a
		;0 int b
		ld b,0
		;mult bc by 8
		sla c
		rl b
		sla c
		rl b
		sla c
		rl b

		ld hl,chr_data
		add hl,bc
		
		ld b,8
		ld de,buffer1+8

caib_1	; first byte is the width
		ld a,(hl)
		inc a
		ld(shift_counter),a
		dec b
		ld a,0
		ld (de),A
		inc hl
		inc de
		
		; and loop for the remaining 7 bytes
caib_lp
		ld A,(hl)
		ld (de),A
		
		inc hl
		inc de
		
		djnz caib_lp
		ret
		
		
scroll_buffer

		ld ix,buffer1		
		ld iy,buffer1+8
		ld b,8
		
sb_loop		
		ld a,(iy)
		ld l,a
		ld a,(ix)
		ld h,a
		
		add hl,hl	; 16 bit shift
		
		ld	a,h
		ld (ix),a
		ld	a,l
		ld (iy),a
		
		inc ix
		inc iy
		
		djnz sb_loop
	
		ret
	
			
			
			

delay_on_time
	push HL
	ld HL,LED_ON_TIME
	call dl_lp
	pop HL
	ret
	
delay_off_time
	push HL
	ld HL,LED_OFF_TIME
	call dl_lp
	pop HL
	ret
	
			
dl_lp	
	dec HL
	ld A,H
	or L
	jp nz,dl_lp
	ret





HexToBCD			; courtesy https://www.msx.org/forum/development/msx-development/bcdhex-conversion-asm
					; no idea what it's doing but it does work. 
					; there's lots of talk about daa but I've not seen anything that works.
	push	bc
	ld	b,10
	ld	c,-1
div10:	inc	c
	sub	b
	jr	nc,div10
	add	a,b
	ld	b,a
	ld	a,c
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	b
	pop	bc
	ret


print_str
		ld A,(HL)
		cp 00
		jr z,print_str_end
		push HL
		call chrout
		pop HL
		inc HL
		jp print_str
print_str_end
		ret
	
	
chrout
		; affects C & E
		ld E,A
		ld C,02
		call 5
		ret
chrin
		;Entered with C=1. Returns A=L=character.
		ld C,01
		call 5
		ret


printCR
		ld A,$0d
		call chrout
		ld A,$0a
		call chrout
		ret
	
	
printSpace
		ld A,$20
		call chrout
		ret
		





RND6
		call fastRND
		and %00000111	; 0-7
		cp 0
		jr z,RND6
		cp 7
		jr z,RND6
		ret


	
		; Fast RND
		;
		; An 8-bit pseudo-random number generator,
		; using a similar method to the Spectrum ROM,
		; - without the overhead of the Spectrum ROM.
		;
		; R = random number seed
		; an integer in the range [1, 256]
		;
		; R -> (33*R) mod 257
		;
		; S = R - 1
		; an 8-bit unsigned integer

fastRND
        push    hl
        push    de
        ld      hl,(seed)
        ld      a,r
        ld      d,a
        ld      e,(hl)
        add     hl,de
        add     a,l
        xor     h
        ld      (seed),hl
        pop     de
        pop     hl
        ret





;=========================================================
; transformation stuff

buffer2_into_buffer1
		







;=========================================================
; vars


shift_counter	defb 00

message_pointer	defb 00,00

level 			defb 03
seed 			defb 00,00
seed_at_start 	defb 00,00



init_screen_data
		; 28 bytes
		defb $AE,$D5,$A0,$A8,$1F,$D3,$00,$AD,$8E,$D8,$05,$A1,$C8,$DA,$12,$91,$3F,$3F,$3F,$81,$80,$D9,$D2,$DB,$34,$A6,$A4,$AF
	
	





game_over_data_table
			defb $10,$20,$40,$80,$40,$20,$10,$08,$04,$02,$01,$02,$04,$08,00,00,00,00,00,00,00

game_win_data_table
			defb $18,$24,$42,$81,$42,$24,$18,00,$18,$24,$42,$81,$42,$24,$18,$00,$ff,$00,$ff,$00,$ff,$ff,$ff,$ff,00,00,00,00,00

separator:
	dm      "--------------------",$0d,$0a,00

introduction:
	dm      "8x8 matrix scroller for RC2014",$0d,$0a,"S Dixon 2021",00
	
	
scrolly:
	dm      "Proportional font working with 8x8 matrix scroller for RC2014! S Dixon 2021 ",00
	

debugMode
	dm "We're in debug mode. Here is the solution:",$0d,$0a,00
	
difficulty
	dm "Press a key to randomise",00

seedwas
	dm "Seed was: ",00

	
play_again
	dm "Play again?",00
	

paddingbyte		defb $00
	

	
buffer1 		defs buffer_length,16 	
				;defb 00;

buffer2 		defs 64,$00 	; 40 x 20
				;defb 00;









message 
	dm "Happy New Year everyone!",0


msg_ptr
	defb 	00

x_offset
	defb 	32



sin_table
			defb  4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,6,6,6,6,6,6,6,6,6,6,6,6,6,5,5,5,5,5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4




#include "speccyfont.proportional.asm"










;=========================================================
; useful code

; debug mode - print solution
			;ld HL,debugMode
			;call print_str
		
			;ld HL,solution
			;ld B,4
;print_sol_loop
			;ld A,(HL)
			;push HL
			;push BC
			;call printDotOfColourA
			;pop BC
			;pop HL
			;inc HL
			;djnz print_sol_loop
			
			
			;call printCR
			;call printCR




;setReverse
		;ld IX,attributes
		;ld A,$30			; ascii '0'
		;ld (IX+0),A
		;ld A,$37			; ascii '7'
		;ld (IX+1),A
		;ret

;setNormal
		;ld IX,attributes
		;ld A,$30			; ascii '0'
		;ld (IX+0),A
		;ld A,$30			; ascii '0'
		;ld (IX+1),A
		;ret


setColour
		; in A, 0-7
		
		; need to make d30 - d37, which is the ascii '0' - '7'
		;or $30
		
		;ld IX,colour
		;ld (IX+1),A
	;	
		;ld A,$33			; ascii '3'
		;ld (IX+0),A

		;ret	




