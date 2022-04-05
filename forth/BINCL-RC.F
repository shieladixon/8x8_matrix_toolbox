\ 	8x8 Matrix Toolbox
\ 	S Dixon https://peacockmedia.software
\ 
\ 	for the RC2014 8x8 Matrix 
\ 	This version adjusted and tested on the RC2014 running CP/M
\ 	to calibrate for other configurations, use the number indicated in jiffy.f
\ 


include jiffy.f

00 constant row_port
02 constant data_port

01 constant on_time		
 
 
create display_buffer	0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 	
create twos 1 c, 2 c, 4 c, 8 c, 16 c, 32 c, 64 c, 128 c, 
create ltor 128 c, 64 c, 32 c,  16 c, 8 c, 4 c, 2 c, 1 c, 


variable current_column


: VINC ( a -- )
 	dup @ 1+ swap !
;


: power2 ( x -- r )  		
	twos + c@		 
; 


: sendDataToRow ( d r -- )	
	power2		
	row_port pc!
	data_port pc!
;



: delay begin 1 - dup 0= until drop ;

: pdb 8 0 do display_buffer i + c@ . loop ;
	
: flushdb
	8 0 do 
		\ i is 0 - 7 

		display_buffer i + c@			
		i 								

		sendDataToRow

		on_time delay

		0 i sendDataToRow

	loop
;

: xy1  ( c r -- )				\ r zero based, c zero based, origin bottom left
	7 swap -  
	display_buffer + dup c@ 	\ c addr x
	rot							\ works the same in Ace and DXForth - addr x c
	ltor + c@
	or							\ addr newvalue
	swap c!
;

: xy0
	7 swap -  
	display_buffer + dup c@ 	\ c addr x
	rot							\ works the same in Ace and DXForth - addr x c
	ltor + c@
	255 swap - 
	and						\ addr newvalue
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
	
	dup 10 /		\ we have 10s
	dup d_dig		\ keep 10s
	\ still have 10s and original number
	10 *  -
	\ now column, units
	over 1 + current_column !
	d_dig
	
	drop
;

: upd_db
	0 hrs dispval
	3 mins dispval
	6 secs dispval
;




: bincl

	0 jiffyclock c!
	0 jiffyclock 1 + c!
	57 jiffyclock 2 + c!
	8 jiffyclock 3 + c!

	cr cr
	baseline
	
	begin
		
		clinc
		jiffyclock c@ 0 = if
			timf
			13 emit
		then
	
		upd_db
		flushdb
	0
	until
;


