\ 	8x8 Matrix Toolbox
\ 	S Dixon https://peacockmedia.software
\ 
\ 	for RC2014's 8x8 Matrix 
\ 	This version adjusted and tested on Minstrel the Forth (Jupiter Ace)
\   and calibrated for 6.5Mhz and NTSC
\ 	to calibrate for other configurations, use the number indicated in clinc
\ 
\ 
\ 	For easy data entry you can type using a modern keyboard
\ 	or simply paste the code using the Minstrel USB keyboard / terminal adaptor: 
\ 	https://peacockmedia.software/RC2014/minstrelkb/

\ 	NB, the Minstrel / Ace doesn't understand comments like this. 
\ 	leave them out.


00 constant row_port
02 constant data_port

01 constant on_time		\ amount of time each digit is displayed during the flush
				
				
\ config above this line, internal stuff below
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 
 
create display_buffer	60 c, 66 c, 137 c, 181 c, 133 c, 181 c, 66 c, 60 c, 	
									\ default 8 zeros
									\ sideways smiley face inserted here for testing

\ Some forths have a 'raise to power' but this is a faster way to do '2 to the power'

create twos 1 c, 2 c, 4 c, 8 c, 16 c, 32 c, 64 c, 128 c, 

: power2 ( x -- r )  				( 2 to the power of x, useful for selecting bits )
				twos + c@		 
; 


: sendDataToRow ( d r -- )	
				power2		 ( convert row from 0-7 to 1-128. 2 to the power of what is sent )		
				row_port out
				data_port out
;



: pause begin 1 - dup 0= until drop ;



\ low-level stuff above this line, high-level stuff below
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\				

	
: flushdb
				8 0 do 
					\ i is 0 - 7 
					display_buffer i + c@			
					i 								
					sendDataToRow
					on_time pause					
					0 i sendDataToRow				
				loop
;
		

\ example (infinite) program loop
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
		
: display
				begin
					flushdb
					0 
				until
;


