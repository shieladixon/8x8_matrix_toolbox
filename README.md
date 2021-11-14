# 8x8_matrix_toolbox

These are example and toolbox files to get you started with the 8x8 matrix module for RC2014. 

This module allows you to control a small 8 pixel by 8 pixel display. You can use it to display scrolling messages, patterns and animations, run John Conway’s Life and even play games! It is designed for the RC2014 and compatible computers, including the Jupiter Ace clone, Minstrel the Forth.

The assembly examples are designed to build with zasm and run on a RC2014 with CP/M or ROMWBW

A good starting point is 8x8-template, which handles the necessary multiplexing and gives you one simple callback where you can put your program loop.  It includes a smiley face, so you only need to build and run that to see a static image on the matrix display.

The hardware assembly instructions are included here (pdf). That file includes an explanation of multiplexing and why that's necessary, along with some simple BASIC code to test your display and get started.

The 8x8 matrix module and more information about the RC2014 is available here:
