chickbbio
=========

Chicken scheme library for GPIO on a BeagleBone Black

Introduction
============

I wrote this so I could use one of my favorite languages on the BeagleBone Black.  Chicken Scheme is a Scheme programming environment that compiles through C to make binaries, and has a convenient interface to C libraries.  It seemed to make sense for an embedded environment.

This code is alpha quality -- it does only the first layer of useful things, and is likely very buggy and/or dangerous.  Your mileage may vary, etc.  Nevertheless, I have found it sufficient for some basic I/O and interfacing with I2C devices.

Installation
============

I assume that you have already compiled Chicken Scheme on your BeagleBone.  If I recall correctly, that process was quite straightforward -- maybe there was a library or two to install with opkg, but that was about it.  I found that Chicken works very well on my BeagleBone Black.  

If you download the git repo, run the following from within the directory. 

    $ cd chickbbio
    $ chicken-install

Usage Example
=============

    ;; Blinks LED on P9-41
    ;;
    
    ; If you've installed the library, this should work
    (use chickbbio)

    ; For sleeping (not necessary strictly speaking for I/O)
    (use srfi-18)
    
    ; Symbols of the form "pX-YY" refer to the physical pins
    ; in the expansion headers on the BBB.  The library
    ; maps this to the "actual" GPIO pin numbers on the 
    ; CPU for you.
    (define pin (lookup-gpio 'p9-41))
    
    (define (loop delay)
      ; Symbols 'high and 'low for output levels
      (write-pin pin 'high)
      (thread-sleep! (/ delay 2))
      (write-pin pin 'low)
      (thread-sleep! (/ delay 2))
      (loop delay))
    
    ; Exports the pin in /sys as an output
    (open-pin pin 'out)
    (loop 0.25)
    (close-pin pin)

