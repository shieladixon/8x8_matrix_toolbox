\ 	jiffy.f - a jiffyclock
\ 	S Dixon https://peacockmedia.software
\ 
\ 	for RC2014's 8x8 matrix module
\ 	
\ 	Usage:  include jiffy.f
\ 			call clinc every 1/60s
\ 			if unable to guarantee exactly 1/60s
\ 			then call as often as convenient
\ 			and use the number indicated to calibrate
\ 
\ 			to read use jiffyclock c@ for jiffies
\ 			secs for seconds
\ 			mins minutes
\ 			hrs for hours
\ 

create jiffyclock 0 c, 0 c, 0 c, 0 c, 

: inc_clock_recursive ( a -- a ) 
	dup dup c@ 1 + swap	C!
	dup C@ 60 = if  dup 0 swap C! 1 + RECURSE then ;
	
: clinc ( -- )	
	jiffyclock dup c@ 1 + swap c!
	
	jiffyclock c@ 62 = if				
	\ use this number ^ for calibration
		jiffyclock 1 + inc_clock_recursive 
		drop 
		0 jiffyclock c!
	then
	
	jiffyclock 3 + c@ 24 = if
		0 jiffyclock 3 + c!
	then
;

: secs ( -- n )
	jiffyclock 1 + c@
;
: mins ( -- n )
	jiffyclock 2 + c@
;
: hrs ( -- n )
	jiffyclock 3 + c@
;

: timf
	jiffyclock 3 + c@ . 58 emit
	jiffyclock 2 + c@ . 58 emit
	jiffyclock 1 + c@ . 
	32 emit 32 emit 32 emit 
;