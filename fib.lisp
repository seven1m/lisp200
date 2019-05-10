(def fib
  (fn [n]
    (if (< n 2)
        n
        (+
          (fib (- n 1))
          (fib (- n 2))))))

(prn (map fib '(1 2 3 4 5 6 7 8 9 10)))
