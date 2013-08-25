;; This is a library for controlling the GPIO features on the 
;; beaglebone black single board computer.
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
		   writeList)

	(import chicken scheme)
	(use srfi-4)
	(use srfi-18)
	(require-extension bind)

	(bind "int openI2C(char *, int);")
	(bind "void writeBuf(int, unsigned char*, int);")

	(define (lookup-gpio q)
	  (let ((r (assq q *gpios*)))
	    (if r (cadr r) r)))

	(define (open-pin pin mode)
	  (with-output-to-file "/sys/class/gpio/export"
	    (lambda () (print pin)))
	  (with-output-to-file (format "/sys/class/gpio/gpio~a/direction" pin)
	    (lambda ()
	      (cond
	       [(equal? mode 'in)  (print "in")  #t]
	       [(equal? mode 'out) (print "out") #t]
	       [#t #f]))))

	(define (close-pin pin)
	  (with-output-to-file "/sys/class/gpio/unexport"
	    (lambda () (print pin))))

	(define (read-pin pin)
	  (with-input-from-file (format "/sys/class/gpio/gpio~a/value" pin)
	    (lambda ()
	      (let ((value (read)))
		(cond
		 [(not (number? value))    #f]
		 [#t                    value])))))

	(define (write-pin pin level)
	  (with-output-to-file (format "/sys/class/gpio/gpio~a/value" pin)
	    (lambda ()
	      (cond
	       [(eq? level 'high) (print 1) #f]
	       [(eq? level 'low)  (print 0)  #f]
	       [#t #f]))))

	(define (writeByte bus x)
	  (writeBuf bus (list->u8vector (list x)) 1))
	
	(define (writeList bus xs)
	  (writeBuf bus (list->u8vector xs) (length xs)))

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