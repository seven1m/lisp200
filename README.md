# Lisp 200

This is just an experiment to see how small a fairly usable lisp could be if
implemented in Ruby. 

My goal is to keep the actual Ruby bits under 200 LOC. The rest of the
implementation lives in the core.lisp file. Interop with the parent Ruby
language is used there, so one might call that cheating.

But in any case, the hard-to-grok bits live in Ruby, and that is contained to
a very small and hopefully readable nugget of code.


## Features

- Eval
- Macros
- Compilation to Ruby output


## How to Use

This should work with Ruby 2.3 and newer.

```sh
ruby lisp.rb
```

Then you'll get a REPL:

```
user> 1
1
user> (+ 1 2)
3
user> (def double (fn [a] (* a 2)))
#<Proc:0x00007fcd91002ba0@lisp.rb:170 (lambda)>
user> (double 3)
6
user> (map double '(1 2 3 4))
'(2 4 6 8)
```

You can run a lisp file:

```
ruby lisp.rb fib.lisp
1
1
2
3
5
8
13
21
34
55
```

You can compile to Ruby:

```
ruby lisp.rb --compile fib.lisp > fib.rb
ruby fib.rb
1
1
2
3
5
8
13
21
34
55
```

## Copyright

Copyright Tim Morgan

Licensed under MIT
