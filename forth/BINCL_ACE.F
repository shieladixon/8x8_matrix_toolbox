\ 	8x8 Matrix Toolbox
\ 	S Dixon https://peacockmedia.software
\ 
\ 	for the RC2014 8x8 Matrix 
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

01 constant on_time		
 
 
create display_buffer	0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 	
create twos 1 c, 2 c, 4 c, 8 c, 16 c, 32 c, 64 c, 128 c, 
create ltor 128 c, 64 c, 32 c,  16 c, 8 c, 4 c, 2 c, 1 c, 


variable current_column

: vinc ( a -- )
 	dup @ 1+ swap !
;


: power2 ( x -- r )  		
	twos + c@		 
; 


: sendDataToRow ( d r -- )	
	power2			
	row_port out
	data_port out
;


: delay begin 1 - dup 0= until drop ;

: pdb 8 0 do display_buffer i + c@ . loop ;
	
: flushdb
	8 0 do 
		display_buffer i + c@			
		i 								
		sendDataToRow
		0 i sendDataToRow
	loop
;


: xy1  ( c r -- )
	( r zero based, c zero based, origin bottom left)
	7 swap -  
	display_buffer + dup c@
	rot
	ltor + c@
	or
	swap c!
;


: xy0
	( r zero based, c zero based, origin bottom left)
	7 swap -  
	display_buffer + dup c@
	rot
	ltor + c@
	255 swap - 
	and
	swap c!
;


: baseline
	255 display_buffer 7 + c!
;


: d_dig ( n -- )
	dup 1 and 1 = if
		current_column @ 2 xy1
	else
		current_column @ 2 xy0
	then
	dup 2 and 2 = if
		current_column @ 3 xy1
	else
		current_column @ 3 xy0
	then
	dup 4 and 4 = if
		current_column @ 4 xy1
	else
		current_column @ 4 xy0
	then
	dup 8 and 8 = if
		current_column @ 5 xy1
	else
		current_column @ 5 xy0
	then
	drop
;


: dispval ( c n -- )
	over current_column !
	dup 10 /
	dup d_dig
	10 *  -
	over 1 + current_column !
	d_dig
	drop
;









create jiffyclock 0 c, 0 c, 0 c, 0 c, 

: secs ( -- n )
	jiffyclock 1 + c@
;
: mins ( -- n )
	jiffyclock 2 + c@
;
: hrs ( -- n )
	jiffyclock 3 + c@
;

	
: hinc
	jiffyclock 3 +
	dup dup c@ 1 + swap c!
	c@ 24 = if
		0 jiffyclock 3 + c!
	then
	
	( new value for hours)
	0 hrs dispval
;

: minc
	jiffyclock 2 +
	dup dup c@ 1 + swap c!
	c@ 60 = if
		0 jiffyclock 2 + c!
		hinc
	then
	
	( new value for mins)
	3 mins dispval
;	

: sinc
	jiffyclock 1 +
	dup dup c@ 1 + swap c!
	c@ 60 = if
		0 jiffyclock 1 + c!
		minc
	then
	
	( new value for secs)
	6 secs dispval
;	
	
: clinc ( -- )	
	jiffyclock dup dup c@ 1 + swap c!
	
	c@ 96 = if				
	( use this number ^ for calibration )
		0 jiffyclock c!
		sinc
	then
;


: timf
	cls
	hrs . 58 emit 
	mins . 58 emit
	secs .
;



: settime
	." Set time..." cr
 	begin
		cr
		." Hours:"
		query number
	until
	
	dup 12 > if
		12 -
	then
	
	jiffyclock 3 + c!
	
 	begin
		cr
		." Minutes:"
		query number
	until
	
	jiffyclock 2 + c!
;



: bincl
	
	fast
	
	settime
	
	cr cr
	baseline
	
	0 hrs dispval
	3 mins dispval

	
	begin
		clinc
		flushdb
	0 until
;