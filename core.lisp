(def cons (fn [a b] (. (. Array "[]" a) "+" (if b b (. Array "new")))))
(def concat (fn [a b] (. a "+" b)))

(def = (fn [a b] (. a "==" b)))
(def < (fn [a b] (. a "<" b)))
(def <= (fn [a b] (. a "<=" b)))
(def > (fn [a b] (. a ">" b)))
(def >= (fn [a b] (. a ">=" b)))

(def nil? (fn [a] (. a "nil?")))
(def throw (fn [a] (. Kernel "raise" a)))

(def length (fn [a] (if a (. a "length") 0)))
(def empty? (fn [a] (= 0 (length a))))
(def list (fn [& args] args))
(def range (fn [first last] (. (. Range "new" first last true) "to_a")))
(def first (fn [a] (. a "first")))
(def rest (fn [a] (if (< (length a) 2) (list) (. a "[]" (. Range "new" 1 -1)))))
(def last (fn [a] (. a "last")))
(def nth (fn [a b] (. a "[]" b)))

(defmacro cond
  (fn [& args]
      (if (empty? args)
        nil
        (if (= (first args) :else)
          (nth args 1)
          `(if ,(first args)
            ,(nth args 1)
            (cond ,@(rest (rest args))))))))

(defmacro and
  (fn [& args]
      (cond (empty? args)
              true
            (= 1 (length args))
              (first args)
            :else
              `(if ,(first args)
                 (and ,@(rest args))
                 ,(first args)))))

(defmacro or
  (fn [& args]
      (cond (empty? args)
              false
            (= 1 (length args))
              (first args)
            :else
              `(if ,(first args)
                 ,(first args)
                 (or ,@(rest args))))))

(def reduce
     (fn [f init coll]
         (. coll "inject" (block f))))

(def filter
     (fn [pred a]
         (cond (empty? a)
                 nil
               (pred (first a))
                 (cons (first a) (filter pred (rest a)))
               :else
                 (filter pred (rest a)))))

(def * (fn [& args]
           (or
             (reduce (fn [t n] (. t "*" n)) 1 args)
             1)))
(def / (fn [& args]
           (if (= 1 (length args))
             (. 1 "/" (. (first args) "to_f"))
             (. args "inject"
                (block (fn [t n] (. t "/" (. n "to_f"))))))))
(def + (fn [& args]
           (.
             (. args "inject"
                (block (fn [t n] (. t "+" n))))
             "to_i")))
(def - (fn [& args]
           (if (= 1 (length args))
             (* -1 (first args))
             (.
               (reduce (fn [t n] (. t "-" n)) 0 args)
               "to_i"))))

(def each
     (fn [f l]
         (if (empty? l)
           nil
           (do
             (f (first l))
             (each f (rest l))))))

(def map
     (fn [f l]
         (if (empty? l)
           l
           (cons (f (first l)) (map f (rest l))))))

(def map-indexed
     (fn [f l]
         ; we don't have let yet, and this function is used by let :-)
         ((fn [mi]
             (mi f l 0 mi))
             (fn [f l i mi]
                 (if (empty? l)
                   l
                   (cons
                     (f i (first l))
                     (mi f (rest l) (+ i 1) mi)))))))

(def str
     (fn [& args]
         (if (empty? args)
           ""
           (.
             (. (first args) "to_s")
             "+"
             (apply str (rest args))))))

(def print (fn [a] (. Kernel "print" (. a "to_s"))))
(def println (fn [a] (print a) (print "\n")))
(def pr-str (fn [a] (. Kernel "PRINT" a)))
(def pr (fn [a] (print (pr-str a))))
(def prn (fn [a] (pr a) (print "\n")))

(defmacro not (fn [a] `(if ,a false true)))
(defmacro unless (fn [pred t f] `(if ,pred ,f ,t)))
(def even? (fn [a] (. a "even?")))
(def odd? (fn [a] (. a "odd?")))

(defmacro let
  (fn [binds & body]
      ((fn [binds vals]
          (if (empty? binds)
            `(do ,@body)
            `((fn ,binds ,@body) ,@vals)
            ))
       (map last (filter (fn [v] (even? (first v))) (map-indexed list binds)))
       (map last (filter (fn [v] (odd? (first v))) (map-indexed list binds))))))

(defmacro letrec
  (fn [binds & body]
      (if (empty? binds)
        `(do ,@body)
        `(let [,(first binds) ,(nth binds 1)] (letrec ,(rest (rest binds)) ,@body))
        )))

(defmacro assert
  (fn [pred & messages]
      `(if ,pred
         (print ".")
         (println
           (str
             "assertion failure: "
             (if ,(not (empty? messages))
               ,(first messages)
               (str "expected " ,(pr-str pred) " be truthy")))))))

(defmacro refute
  (fn [pred & messages]
      `(if ,pred
         (println
           (str
             "assertion failure: "
             (if ,(not (empty? messages))
               ,(first messages)
               (str "expected " ,(pr-str pred) " be false or nil"))))
         (print "."))))

(defmacro assert=
  (fn [expected actual & messages]
      `(if (= ,expected ,actual)
         (print ".")
         (println
           (str
             "\n"
             "assertion failure: "
             (if ,(not (empty? messages))
               ,(first messages)
               (str "expected " ,(pr-str actual) " to return " (pr-str ,expected) ", but got " (pr-str ,actual))))))))

(def eval
     (fn [ast]
         (let [b (. Kernel "binding")
               ruby (. Kernel "compile" ast b)]
           (. b "eval" ruby))))
