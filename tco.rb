code = <<-CODE
  def factorial(n, accumulator = 1)
    raise InvalidArgument, "negative input given" if n < 0

    return accumulator if n == 0
    return factorial(n - 1, accumulator * n)
  end
CODE

options = {
  tailcall_optimization: true,
  trace_instruction: false,
}
p RubyVM::InstructionSequence.new(code, nil, nil, nil, options).eval
p RubyVM::InstructionSequence.new('factorial(100000)', nil, nil, nil, options).eval
