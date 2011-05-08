(define (factorial n)
    "
        The factorial function
    "
    (let ((total 1)
          (_n    n))
      (while (> _n 1)
        (set! total (* total _n))
        (set! _n (- _n 1)))
      total))

;; I'
