#!/usr/bin/env ruby -W0

def READ(chars)
  chars = chars.chars if chars.is_a?(String)
  chars.shift while chars.first == ' '
  case chars.first
  when '(', '['
    chars.shift
    list = []
    while (atom = READ(chars))
      list << atom
    end
    raise 'unbalanced parens' unless [')', ']'].include?(chars.first)
    chars.shift
    list
  when '"'
    chars.shift
    str = []
    while (char = chars.shift)
      case char
      when "\\"
        str << chars.shift
      when '"'
        break
      else
        str << char
      end
    end
    str.join
  when '0'..'9'
    num = []
    while chars.any? && ![' ', ')', ']'].include?(chars.first)
      num << chars.shift
    end
    num.index('.') ? num.join.to_f : num.join.to_i
  else
    symbol = []
    while chars.any? && ![' ', ')', ']'].include?(chars.first)
      symbol << chars.shift
    end
    return if symbol.empty?
    symbol.join.to_sym
  end
end

def compile(ast)
  if ast.is_a?(Array)
    case ast.first
    when :define
      (_, name, val) = ast
      val = compile(val)
      "#{name} = #{val}"
    when :lambda
      (_, arg_list, body) = ast
      body = compile(body)
      "->(#{arg_list.join(', ')}) { #{body} }"
    else
      (fn, *args) = ast
      fn = compile(fn)
      args.map! { |a| compile(a) }
      "#{fn}.(#{args.join(', ')})"
    end
  elsif ast.is_a?(Symbol)
    safe_name(ast)
  else
    ast.inspect
  end
end

def compile_block(*nodes)
  nodes.map { |ast| compile(ast) }.join("\n")
end

def PRINT(ast)
  ast.inspect
end

def rep(str, env)
  puts PRINT(ev(compile(READ(str)), env))
end

def safe_name(name)
  {
    '+' => 'add_op',
    '-' => 'sub_op',
    '*' => 'mul_op',
    '/' => 'div_op'
  }[name.to_s] ||
    name.to_s.sub(/^[^a-z]/, 'a').gsub(/[^a-z0-9_]/, '_')
end

def core_binding
  add_op = ->(*args) { args.inject(&:+) || 0 }
  sub_op = ->(*args) { args.size == 1 ? -args.first : args.inject(&:-) }
  mul_op = ->(*args) { args.inject(&:*) || 1 }
  div_op = ->(*args) { args.inject(&:/) }
  binding
end

if $0 == __FILE__
  if ARGV.any?
    # TODO
  else
    b = core_binding
    loop do
      print "user> "
      str = $stdin.gets
      exit if str == ''
      puts PRINT(b.eval(compile(READ(str))))
    end
  end
end
