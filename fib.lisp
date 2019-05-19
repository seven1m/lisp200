(def fib
  (fn [n]
    (if (< n 2)
        n
        (+
          (fib (- n 1))
          (fib (- n 2))))))

(def upper (string->number (if (> (length ARGV) 1) (nth ARGV 1) 10)))

(each (fn [n] (prn (fib n)))
      (range 1 (+ 1 upper)))
