require 'minitest/autorun'

require_relative './lisp'

class TestRead < MiniTest::Test
  def test_symbol
    assert_equal :foo, READ('foo')
    assert_equal :foo, READ('foo bar')
  end

  def test_list
    assert_equal [:foo], READ('(foo)')
    assert_equal [:foo, :bar], READ('(foo bar)')
    assert_equal [], READ('()')
    assert_equal [:foo, []], READ('(foo ())')
    assert_equal [:foo], READ('[foo]')
    assert_equal [:foo, :bar], READ('[foo bar]')
    assert_equal [:foo, [:bar, :baz], :qux], READ('(foo (bar baz) qux)')
    assert_equal [:foo, [:bar, :baz], :qux], READ('[foo (bar baz) qux]')
    assert_equal [:foo, [:bar, :baz], :qux], READ('(foo [bar baz] qux)')
  end

  def test_string
    assert_equal 'string', READ('"string"')
    assert_equal 'string "with quotes"', READ("\"string \\\"with quotes\\\"\"")
    assert_equal [:a, 'b', :c], READ('(a "b" c)')
    assert_equal '', READ('""')
  end

  def test_number
    assert_equal 1, READ('1')
    assert_equal 2.2, READ('2.2')
  end
end

class TestCompileAndEval < MiniTest::Test
  def test_number
    code = compile(1)
    b = binding
    assert_equal 1, b.eval(code)
  end

  def test_string
    code = compile("string")
    b = binding
    assert_equal "string", b.eval(code)
  end

  def test_define
    b = binding
    assert_equal 1, b.eval(compile([:define, :foo, 1]))
    assert_equal 1, b.eval(compile(:foo))
  end

  #ARGV.concat ['-n', 'test_lambda']

  def test_lambda
    b = binding
    l1 = b.eval(compile([:lambda, [], 1]))
    assert_equal 1, l1.()
    eval(compile([:define, :foo, [:lambda, [], 2]]))
    l2 = b.eval(compile([:define, :foo, [:lambda, [], 2]]))
    assert_equal 2, l2.()
    l3 = b.eval(compile([:define, :bar, [:lambda, [], [:foo]]]))
    assert_equal 2, l3.()
  end

  def test_lambda_args
    b = binding
    l1 = b.eval(compile([:lambda, [:x], :x]))
    assert_equal 1, l1.(1)
  end

  def test_core_add
    b = core_binding
    assert_equal 0, b.eval(compile([:"+"]))
    assert_equal 4, b.eval(compile([:"+", 4]))
    assert_equal 6, b.eval(compile([:"+", 4, 2]))
    assert_equal 7, b.eval(compile([:"+", 4, 2, 1]))
  end

  def test_core_sub
    b = core_binding
    assert_equal -1, b.eval(compile([:"-", 1]))
    assert_equal 2, b.eval(compile([:"-", 4, 2]))
    assert_equal 0, b.eval(compile([:"-", 4, 2, 2]))
  end

  def test_core_mul
    b = core_binding
    assert_equal 1, b.eval(compile([:"*"]))
    assert_equal 4, b.eval(compile([:"*", 4]))
    assert_equal 8, b.eval(compile([:"*", 4, 2]))
    assert_equal 24, b.eval(compile([:"*", 4, 2, 3]))
  end

  def test_core_div
    b = core_binding
    assert_equal 4, b.eval(compile([:"/", 24, 6]))
    assert_equal 2, b.eval(compile([:"/", 24, 6, 2]))
  end

  def test_compile_block
    code = compile_block(
      [:define, :x, 1],
      [:define, :y, [:"+", :x, 1]],
      [:define, :double, [:lambda, [:n], [:"*", :n, 2]]],
      [:define, :z, [:double, :y]]
    )
    b = core_binding
    b.eval(code)
    assert_equal 4, b.local_variable_get(:z)
  end
end
