;=========================================================
; 8x8 matrix template
; S Dixon https://peacockmedia.software

; for S.Dixon's 8x8 LED matrix board for RC2014 and CP/M
; handles the multiplexing, gives you a callback at a convenient rate 
; for you to implement a game loop.
; a smiley is copied into the buffer for example purposes
;
;
; last updated 14 Nov 2021
; use zasm to build

;=========================================================


#target BIN

#code PAGE1,$100

LED_ON_TIME		equ $0030		; play with these two figures to change the intensity of the LEDs
LED_OFF_TIME	equ $0090		; this is the duty cycle

BDOS			equ $05

CONS_IN			equ  1			;READ CONSOLE
CONS_OUT		equ  2			;TYPE FUNCTION
PRINT_STR		equ  9			;BUFFER PRINT ENTRY
CONS_STAT		equ  11			;(TRUE IF CHAR READY)

select_row_port 	equ 00
select_columns_port	equ 02

BUFFERLENGTH	equ 64		; the actual number of cells / pixels.  We sent this / 8  to the display, 8 bits per byte
LINEWIDTH		equ 8
ROWCOUNT		equ 8
CELL			equ $80
NOCELL			equ	$00




;=========================================================
; intro / menu

			call printCR

			ld de,introduction
			call print_str
			call printCR
			call printCR			

			ld de,menu
			call print_str
			call printCR
			call printCR


wait_key:	
			ld C,CONS_STAT
			call BDOS
			cp 0	
			jr z,wait_key
			; eat it
			call chrin

				
			
			
setup_smiley:
			ld hl,smiley
			ld de,buffer1
			call copy_buffer
					; source: HL, destination: DE
					
			ld IY,buffer1
			call matrix_copy

				
			; 0-9, speed
			ld a,4
			ld(inner_divide),a
			ld(speed),a




;=========================================================
; main 

main:
			call start_matrix_refresh_loop		
			ret






;=========================================================
; main program callback - this is one 'frame'
; don't put a loop in here, 
; do as much as you need to do in one 'frame' and return

main_program_loop:



		
				; do your stuff here

				
				
				
				
				call key_routine	

				ret










;=============================================================================
; this is the LED multiplexing, during which our game 'frame' loop will be called 


cursor: defb 0
inner_divide: defb 12
	
start_matrix_refresh_loop:


			ld HL,matrixbuffer
			ld B,1			; shifts 1, 2, 4, 8 etc
							; when 0, set to 1 again, and reset HL to chr_data
							
mref_loop:



			call display_data_at_row	; includes on time and off time
			

			
			inc hl
			sla b
			jr nz,end_outer_divide
				; main loop already divided by 8 here
			
				ld hl,inner_divide
				dec (hl)
				jr nz,end_inner_divide
				



					; do stuff here.

					
					call main_program_loop
					
					
				

					ld IY,buffer1			
					call matrix_copy


				ld a,(speed)
				ld (inner_divide),a
				

end_inner_divide:
				ld HL,matrixbuffer
				ld B,1
			
end_outer_divide:

			ld a,(last_key)
			cp 27
			jp nz,mref_loop

			ret

	






;=========================================================
; game subroutines 


key_routine:

			ld C,CONS_STAT
			call BDOS
			cp 0	
			jp z,kr_ret
			
			; in a
			ld (last_key),a
			; eat it
			call chrin
			
			; key is in a - test it and do it.
			; eg if left, call go_left etc
		
kr_ret			
			ret






;=========================================================
; some useful subroutines




plot: 		; bc = y & x,  zero-based
			call get_buffer1_add
			ld (ix),CELL
			ret

unplot:		; bc = y & x,  zero-based
			call get_buffer1_add
			ld (ix),NOCELL
			ret

peek:		; bc = y & x,  zero-based
			call get_buffer1_add
			ld a,(ix)				; CELL or NOCELL
			ret










;=========================================================
; subroutines - internal


get_buffer1_add:
			; cell address in ix from b=y, c=x
			
			ld ix,buffer1
			push bc
			ld b,0
			add ix,bc
			pop bc
			sla b
			sla b
			sla b
			ld c,b
			ld b,0
			add ix,bc		
			ret




delay_on_time:
			push HL
			ld HL,LED_ON_TIME
			call dl_lp
			pop HL
			ret
	
delay_off_time:
			push HL
			ld HL,LED_OFF_TIME
			call dl_lp
			pop HL
			ret
		
dl_lp:
			dec HL
			ld A,H
			or L
			jp nz,dl_lp
			ret

			

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








			; C is rows
			; B is columns
			; B&C are 1-based
			; ROWCOUNT is # rows
			; LINEWIDTH is # cols


getContentsatBC:
			; start of buffer in IX
			; needs rewriting for rows & columns that aren't 8
			
			push ix
			push bc
			
			; if b=0, b=8
			ld a,0
			cp b
			jr nz,bnot0
			ld b,8
bnot0
			; if c=0, c=8
			ld a,0
			cp c
			jr nz,cnot0
			ld c,8
cnot0
			; if b=9, b=1
			ld a,9
			cp b
			jr nz,bnot9
			ld b,1
bnot9
			; if c=9, c=1
			ld a,9
			cp c
			jr nz,cnot9
			ld c,1
cnot9		

			dec b
			dec c
			
			sla c
			sla c
			sla c	; rows * 8
			
			ld a,c
			add b
			ld c,a
			ld b,0
			
			add ix,bc
			
			ld a,(ix)
			
			pop bc
			pop ix

			ret

			 



;=========================================================
; convert our main buffer (bytes) to our 8x8buffer (bits)


current_stack defb 00

matrix_copy
; iy is the byte buffer
; put into the 8 bytes of matrixbuffer


		ld HL,current_stack
		ld DE,LINEWIDTH
		ld ix,matrixbuffer
		ld b,08

mr_row	ld (hl),0
		
		ld a,(iy)
		cp CELL
		jr nz,not7
		set 7,(hl)
not7	ld a,(iy+1)
		cp CELL
		jr nz,not6
		set 6,(hl)
not6	ld a,(iy+2)
		cp CELL
		jr nz,not5
		set 5,(hl)
not5	ld a,(iy+3)
		cp CELL
		jr nz,not4
		set 4,(hl)
not4	ld a,(iy+4)
		cp CELL
		jr nz,not3
		set 3,(hl)
not3	ld a,(iy+5)
		cp CELL
		jr nz,not2
		set 2,(hl)
not2	ld a,(iy+6)
		cp CELL
		jr nz,not1
		set 1,(hl)
not1	ld a,(iy+7)
		cp CELL
		jr nz,not0
		set 0,(hl)
		
not0	ld a,(hl)


		ld (ix),a
		
		add iy,de	; line width
		inc ix	
		
		djnz mr_row
		
		ret








;=========================================================
; subroutines - general utilities


copy_buffer
		; source: HL, destination: DE
		;LD (DE),(HL), then increments DE, HL, and decrements BC) until BC=0.
		ld bc,BUFFERLENGTH
		ldir
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
		



bell
		ld A,$07	;esc
		call chrout
	
		ret	


	
	
	
print_str
		;D,E ADDRESSES OF MESSAGE ENDING WITH "$"
		ld c,PRINT_STR
		call BDOS
				
		ret
	
	
chrout
		; affects C & E
		ld E,A
		ld C,CONS_OUT
		call BDOS
		ret
chrin
		;Entered with C=1. Returns A=L=character.
		ld C,CONS_IN
		call BDOS
		ret


clr_buffer	
			ld C,CONS_STAT
			call BDOS
			cp 0	
			ret z
			
			; clear it
			call chrin
			jp clr_buffer






RND8
		call fastRND
		and %00000111	; 0-7

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
; vars


bat_pos 	defb 03
last_key	defb 00

our_bullet 		defb $04,$ff	; x first then y, rem y top-bottom, ff in y means no bullet
their_bullet 	defb $04,$ff 	; x first then y, rem y top-bottom, ff in y means no bullet


seed 		defb 00,00
seed_at_start 		defb 00,00

speed 		defb 00





introduction:
	dm "Introduction string here",'$'
	
	
menu
	dm "press a key to start",'$'	
	
	




	
buffer1: 		defs BUFFERLENGTH,NOCELL 	; 40 x 20
				;defb 00;


matrixbuffer:	defs 8,$ff				; 8 bytes


smiley:

				defb NOCELL, NOCELL, CELL, CELL, CELL, CELL, NOCELL, NOCELL
				defb NOCELL, CELL, NOCELL, NOCELL, NOCELL, NOCELL, CELL, NOCELL
				defb CELL, NOCELL, CELL, NOCELL, CELL, NOCELL, NOCELL, CELL
				defb CELL, NOCELL, CELL, NOCELL, CELL, NOCELL, NOCELL, CELL
				defb CELL, NOCELL, NOCELL, NOCELL, NOCELL, CELL, NOCELL, CELL
				defb CELL, NOCELL, CELL, CELL, CELL, NOCELL, NOCELL, CELL
				defb NOCELL, CELL, NOCELL, NOCELL, NOCELL, NOCELL, CELL, NOCELL
				defb NOCELL, NOCELL, CELL, CELL, CELL, CELL, NOCELL, NOCELL






