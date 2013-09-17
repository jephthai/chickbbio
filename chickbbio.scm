;; This is a library for controlling the GPIO, ADC, and I2C features
;; on the beaglebone black single board computer.
;;
;; Author:  Josh Stone
;; Date:    2013-08-24
;; Contact: yakovdk@gmail.com
;;

(module chickbbio (lookup-gpio 
		   open-pin 
		   close-pin 
		   read-pin 
		   write-pin
		   openI2C
		   writeByte
                   init-adc
                   read-adc
		   writeList)

	(import chicken scheme)
	(use srfi-4)
	(use srfi-18)
        (use srfi-13)
        (use extras)
        (use directory-utils)
	(require-extension bind)


        ; These are two functions written in the accompanying
        ; C file (i2c.c).  Chicken scheme does not give us
        ; IOCTL functions that I can find, so this seemed like
        ; an easy way to get the I2C stuff to work.

	(bind "int openI2C(char *, int);")
	(bind "void writeBuf(int, unsigned char*, int);")

        
        ; We need to make sure that the beaglebone black is 
        ; configured for ADC operation.  This global variable
        ; will be used to keep track of whether or not we have
        ; confirmed it yet.

        (define *adc-dir* #f)

        
        ; A lookup table is used to correlate IO pin numbers with
        ; header locations.  You can use atoms of the form 'pX-YZ
        ; where X is one of the headers (representing either P8 or
        ; P9) and YZ represent the number of the socket in the
        ; header.  The result will be an integer (coincidentally
        ; the IO pin number recognized by the kernel).

	(define (lookup-gpio q)
	  (let ((r (assq q *gpios*)))
	    (if r (cadr r) r)))


        ; Opens an I/O pin in the given mode.  This mode should be
        ; the atom 'in or 'out, depending on how you want to use
        ; it.  The result will be #f if there is a failure.

	(define (open-pin pin mode)
	  (with-output-to-file "/sys/class/gpio/export"
	    (lambda () (print pin)))
	  (with-output-to-file (format "/sys/class/gpio/gpio~a/direction" pin)
	    (lambda ()
	      (cond
	       [(equal? mode 'in)  (print "in")  #t]
	       [(equal? mode 'out) (print "out") #t]
	       [#t #f]))))

        
        ; When we are done using an I/O pin, we can instruct the
        ; kernel to configure it to be no longer available using
        ; this function.  

	(define (close-pin pin)
	  (with-output-to-file "/sys/class/gpio/unexport"
	    (lambda () (print pin))))

        
        ; Assuming that we have exported a pin for input using the
        ; open-pin function above, this function will return the
        ; current value of the pin (either high (1) or low (0)). 
        ; If an error is encountered, this will be #f.

	(define (read-pin pin)
	  (with-input-from-file (format "/sys/class/gpio/gpio~a/value" pin)
	    (lambda ()
	      (let ((value (read)))
		(cond
		 [(not (number? value))    #f]
		 [#t                    value])))))


        ; If we have configured a pin for output mode using the
        ; open-pin function above, this function will write out
        ; the indicated value.  The values should be indicated 
        ; with the atoms 'high and 'low.  Any errors will result
        ; in a return value of #f.

	(define (write-pin pin level)
	  (with-output-to-file (format "/sys/class/gpio/gpio~a/value" pin)
	    (lambda ()
	      (cond
	       [(eq? level 'high) (print 1) #f]
	       [(eq? level 'low)  (print 0)  #f]
	       [#t #f]))))


        ; Given a reference to an open I2C bus connection, we can
        ; write the single byte x out to the device.  Behavior is
        ; not defined if the bus has not been properly opened
        ; with the openI2C function.

	(define (writeByte bus x)
	  (writeBuf bus (list->u8vector (list x)) 1))
	
        
        ; Write a list of bytes out as one communication with an
        ; open I2C bus connection.  This assumes that the device
        ; has been properly opened with the openI2C function.  
        ; Behavior is not defined when this is not the case.

	(define (writeList bus xs)
	  (writeBuf bus (list->u8vector xs) (length xs)))


        ; This is an internal function that validates that the
        ; beaglebone is configured with the iio interface, which
        ; will indicate that the ADC is accessible.  If it's not
        ; loaded, then this will request that the kernel load
        ; this interface.

        (define (check-iio-slot)
          (let [(lines (read-lines "/sys/devices/bone_capemgr.8/slots"))
                (fn (lambda (a b) (or a b)))
                (gn (lambda (x) (string-contains x "cape-bone-iio")))]
            (if (foldl fn #f (map gn lines))
                #t
                (with-output-to-file "/sys/devices/bone_capemgr.8/slots"
                  (lambda ()
                    (print "cape-bone-iio")
                    #t)))))


        ; We need to make sure that the BeagleBone Black is configured
        ; to use the ADC.  Run this function at the beginning of your 
        ; program.  Any calls to the ADC reading function below will
        ; fail with #f until this function is run.  If there is a 
        ; failure to configure ADC operation, this will return #f.

        (define (init-adc)
          (check-iio-slot)
          (cond
           [*adc-dir* #t]
           [(not (file-exists/directory? "ocp.2" "/sys/devices")) #f]
           [(not (file-exists/directory? "helper.14" "/sys/devices/ocp.2")) #f]
           [#t
              (set! *adc-dir* "/sys/devices/ocp.2/helper.14")
              #t]))


        ; This function will ensure that the ADC interface has been
        ; initialized.  Following this check, it will return a value
        ; in the range [0,4095] for the pin supplied.  The argument
        ; should be a string of the form "AINX" where X refers to the
        ; analog input pin number.  E.g., "AIN6".  Errors will 
        ; return a #f.

        (define (read-adc pin)
          (cond
           [(not *adc-dir*) #f]
           [#t
            (with-input-from-file (format "/sys/devices/ocp.2/helper.14/~a" pin)
              (lambda ()
                (let ((value (read)))
                  (cond
                   [(not (number? value)) #f]
                   [#t                 value]))))]))

	(define *gpios*
	  '((p9-01 #f)    (p8-01 #f)
	    (p9-02 #f)    (p8-02 #f)
	    (p9-03 #f)    (p8-03 #f)
	    (p9-04 #f)    (p8-04 #f)
	    (p9-05 #f)    (p8-05 #f)
	    (p9-06 #f)    (p8-06 #f)
	    (p9-07 #f)    (p8-07 66)
	    (p9-08 #f)    (p8-08 67)
	    (p9-09 #f)    (p8-09 69)
	    (p9-10 #f)    (p8-10 68)
	    (p9-11 30)    (p8-11 45)
	    (p9-12 60)    (p8-12 44)
	    (p9-13 31)    (p8-13 23)
	    (p9-14 40)    (p8-14 26)
	    (p9-15 48)    (p8-15 47)
	    (p9-16 51)    (p8-16 46)
	    (p9-17  4)    (p8-17 27)
	    (p9-18  5)    (p8-18 65)
	    (p9-19 #f)    (p8-19 22)
	    (p9-20 #f)    (p8-20 #f)
	    (p9-21  3)    (p8-21 #f)
	    (p9-22  2)    (p8-22 #f)
	    (p9-23 49)    (p8-23 #f)
	    (p9-24 15)    (p8-24 #f)
	    (p9-25 117)   (p8-25 #f)
	    (p9-26 14)    (p8-26 61)
	    (p9-27 125)   (p8-27 #f)
	    (p9-28 #f)    (p8-28 #f)
	    (p9-29 #f)    (p8-29 #f)
	    (p9-30 122)   (p8-30 #f)
	    (p9-31 #f)    (p8-31 #f)
	    (p9-32 #f)    (p8-32 #f)
	    (p9-33 #f)    (p8-33 #f)
	    (p9-34 #f)    (p8-34 #f)
	    (p9-35 #f)    (p8-35 #f)
	    (p9-36 #f)    (p8-36 #f)
	    (p9-37 #f)    (p8-37 #f)
	    (p9-38 #f)    (p8-38 #f)
	    (p9-39 #f)    (p8-39 #f)
	    (p9-40 #f)    (p8-40 #f)
	    (p9-41 20)    (p8-41 #f)
	    (p9-42  7)    (p8-42 #f)
	    (p9-43 #f)    (p8-43 #f)
	    (p9-44 #f)    (p8-44 #f)
	    (p9-45 #f)    (p8-45 #f)
	    (p9-46 #f)    (p8-46 #f)))
)
