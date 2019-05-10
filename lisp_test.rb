require 'minitest/autorun'

require_relative './lisp'

class TestRead < Minitest::Test
  def test_tokenize
    code = "(hello 1 2 (/ 3) [* 4 5] \"(lispworld\")\n"
    assert_equal ['(', 'hello', '1', '2', '(', '/', '3', ')', '[', '*', '4', '5', ']', "\"(lispworld\"", ')'], tokenize(code)
  end

  def test_read
    assert_equal :foo, READ('foo')
    assert_equal :foo, READ('foo ; comment')
    assert_equal [:hello, :world], READ("(hello ; comment\n world)")
    assert_equal 1, READ('1')
    assert_equal -1, READ('-1')
    assert_equal 2.3, READ('2.3')
    assert_equal -2.3, READ('-2.3')
    code = '(hello 1 2 (/ 3) [* 4 5] "(lispworld")'
    assert_equal [:hello, 1, 2, [:/, 3], [:*, 4, 5], "(lispworld"], READ(code)
    assert_equal [:def, :"=", [:fn, [:a, :b], [:".", :a, :==, :b]]], READ("(def = (fn [a b] (. a == b)))")
    assert_equal [:quote, :foo], READ("'foo")
    assert_equal [:quote, [1, 2, 3]], READ("'(1 2 3)")
    assert_equal [:quasiquote, :foo], READ("`foo")
    assert_equal [:quasiquote, [1, 2, 3]], READ("`(1 2 3)")
    assert_equal [:unquote, :foo], READ(",foo")
    assert_equal [:unquote, [:list, 1, 2, 3]], READ(",(list 1 2 3)")
    assert_equal [:splice_unquote, [:list, 1, 2, 3]], READ(",@(list 1 2 3)")
    assert_raises('unbalanced parens') { READ('(foo') }
    assert_raises('unbalanced parens') { READ('(foo bar (baz)') }
  end
end

class TestPrint < Minitest::Test
  def test_print
    ast = [:hello, :world, [:list, 1, 2], "string"]
    assert_equal "'(hello world '(list 1 2) \"string\")", PRINT(ast)
  end
end

class TestCompileAndEval < MiniTest::Test
  def test_number
    b = binding
    code = compile(1, b)
    assert_equal 1, b.eval(code)
  end

  def test_string
    b = binding
    code = compile("string", b)
    assert_equal "string", b.eval(code)
  end

  #ARGV.concat ['-n', 'test_def']

  def test_def
    b = binding
    assert_equal 1, b.eval(compile([:def, :foo, 1], b))
    assert_equal 1, b.eval(compile(:foo, b))
  end

  def test_fn
    b = binding
    l1 = b.eval(compile([:fn, [], 1], b))
    assert_equal 1, l1.()
    eval(compile([:def, :foo, [:fn, [], 2]], b))
    l2 = b.eval(compile([:def, :foo, [:fn, [], 2]], b))
    assert_equal 2, l2.()
    l3 = b.eval(compile([:def, :bar, [:fn, [], [:foo]]], b))
    assert_equal 2, l3.()
    l4 = b.eval(compile([:def, :restargs, [:fn, [:&, :args], :args]], b))
    assert_equal [6, 7], l4.(6, 7)
  end

  def test_fn_args
    b = core_binding
    l1 = b.eval(compile([:def, :f, [:fn, [:x], :x]], b))
    assert_equal 1, l1.(1)
    assert_equal 2, b.eval(compile([:f, [:+, 1, 1]], b))
  end

  def test_core_throw
    b = core_binding
    assert_raises "error" do
      b.eval(compile([:throw, "error"], b))
    end
  end

  def test_core_print
    b = core_binding
    assert_output("hello world") { b.eval(compile([:print, "hello world"], b)) }
    assert_output("hello world\n") { b.eval(compile([:println, "hello world"], b)) }
  end

  def test_core_first_rest_last
    b = core_binding
    assert_equal 1, b.eval(compile([:first, [:cons, 1, [:cons, 2, [:cons, 3, nil]]]], b))
    assert_nil b.eval(compile([:first, [:list]], b))
    assert_equal [2, 3], b.eval(compile([:rest, [:cons, 1, [:cons, 2, [:cons, 3, nil]]]], b))
    assert_equal [3], b.eval(compile([:rest, [:cons, 2, [:cons, 3, nil]]], b))
    assert_equal [], b.eval(compile([:rest, [:cons, 3, nil]], b))
    assert_equal [], b.eval(compile([:rest, [:list]], b))
    assert_equal 3, b.eval(compile([:last, [:cons, 1, [:cons, 2, [:cons, 3, nil]]]], b))
    assert_nil b.eval(compile([:last, [:list]], b))
  end

  def test_try
    b = core_binding
    result = b.eval(compile([:try, [:throw, "error"], [:catch, :e, :e]], b))
    assert_kind_of RuntimeError, result
    assert_equal 'error', result.message
  end

  def test_apply
    b = core_binding
    assert_equal 6, b.eval(compile([:apply, :+, [:cons, 1, [:cons, 2, [:cons, 3, nil]]]], b))
  end

  def test_quote
    b = core_binding
    assert_equal '1', compile([:quote, 1], b)
    assert_equal '"string"', compile([:quote, "string"], b)
    assert_equal ':symbol', compile([:quote, :symbol], b)
    assert_equal '[:foo, 1]', compile([:quote, [:foo, 1]], b)
  end

  def test_quasiquote_and_unquote
    b = core_binding
    assert_equal [0, 1, 2], b.eval(compile([:quasiquote, [0, 1, 2]], b))
    assert_equal [0, [:+, 1, 2], 4], b.eval(compile([:quasiquote, [0, [:+, 1, 2], 4]], b))
    assert_equal [0, 3, 4], b.eval(compile([:quasiquote, [0, [:unquote, [:+, 1, 2]], 4]], b))
    assert_equal [0, 1, 2, 3], b.eval(compile([:quasiquote, [0, [:splice_unquote, [:cons, 1, [:cons, 2, nil]]], 3]], b))
  end

  def test_if
    b = core_binding
    assert_equal 1, b.eval(compile([:if, true, 1, 2], b))
    assert_equal 2, b.eval(compile([:if, false, 1, 2], b))
    assert_equal 1, b.eval(compile([:if, true, 1], b))
    assert_nil b.eval(compile([:if, false, 1], b))
  end

  def test_not
    b = core_binding
    assert_equal true, b.eval(compile([:not, false], b))
    assert_equal false, b.eval(compile([:not, true], b))
  end

  def test_cons
    b = core_binding
    assert_equal [1, 2, 3], b.eval(compile([:cons, 1, [:cons, 2, [:cons, 3, nil]]], b))
  end

  def test_concat
    b = core_binding
    assert_equal [1, 2, 3], b.eval(compile([:concat, [:cons, 1, nil], [:cons, 2, [:cons, 3, nil]]], b))
  end

  def test_defmacro
    b = core_binding
    assert_nil b.eval(compile([:defmacro, :identity, [:fn, [:x], :x]], b))
    assert_equal '1', compile([:identity, 1], b)
    assert_nil b.eval(compile([:defmacro, :two, [:fn, [], 2]], b))
    assert_equal '2', compile([:two], b)
    assert_nil b.eval(compile([:defmacro, :three, [:fn, [], [:identity, 3]]], b))
    assert_equal '3', compile([:three], b)
    assert_equal 'false ? 5 : 4', compile([:unless, false, 4, 5], b)
    assert_equal 'true ? _43.(2, 3) : _43.(1, 1)', compile([:unless, true, [:+, 1, 1], [:+, 2, 3]], b)
    assert_equal 5, b.eval(compile([:unless, true, [:+, 1, 1], [:+, 2, 3]], b))
    assert_nil b.eval(compile([:defmacro, :restargs, [:fn, [:&, :args], [:quasiquote, [:list, [:splice_unquote, :args]]]]], b))
    assert_equal 'list.(6, 7)', compile([:restargs, 6, 7], b)
  end

  def test_raise
    assert_raises StandardError do
      b = core_binding
      b.eval(compile([:raise, 'error'], b))
    end
  end
end
