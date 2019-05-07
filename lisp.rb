#!/usr/bin/env ruby -W0

MACROS = {}

def is_pair(node)
  node.is_a?(Array) && node.any?
end

def quasiquote(ast)
  if is_pair(ast)
    if ast.first == :unquote
      ast[1]
    elsif is_pair(ast.first) && ast.first.first == :splice_unquote
      [:concat, ast.first[1], quasiquote(ast[1..-1])]
    else
      [:cons, quasiquote(ast.first), quasiquote(ast[1..-1])]
    end
  else
    [:quote, ast]
  end
end

def compile(ast, b)
  if ast.is_a?(Array)
    case ast.first
    when :apply
      (_, fn, args) = ast
      fn = compile(fn, b)
      args = compile(args, b)
      if (method(fn) rescue nil)
        "#{fn}(*#{args})"
      else
        "#{fn}.(*#{args})"
      end
    when :block
      fn = ast[1]
      '&' + compile(ast[1], b)
    when :def
      (_, name, val) = ast
      val = compile(val, b)
      "#{safe_name name} = #{val}"
    when :defmacro
      (_, name, fn) = ast
      MACROS[name] = b.eval(compile(fn, b))
      'nil'
    when :do
      ast[1..-1].map { |n| compile(n, b) }.join("\n")
    when :fn
      (_, arg_list, *body) = ast
      body = compile([:do] + body, b)
      arg_list[-1] = "*#{arg_list.pop}" if arg_list[-2] == :&
      "->(#{arg_list.join(', ')}) { #{body} }"
    when :if
      (_, pred, t, f) = ast
      "#{compile pred, b} ? #{compile t, b} : #{compile f, b}"
    when :"."
      (_, obj, message, *args) = ast
      obj = compile(obj, b)
      args.map! { |a| compile(a, b) }
      if args.any?
        "#{obj}.send(#{message.inspect}, #{args.join(', ')})"
      else
        "#{obj}.send(#{message.inspect})"
      end
    when :quasiquote
      compile(quasiquote(ast[1]), b)
    when :quote
      ast[1].inspect
    when :try
      (_, try_node, catch_node) = ast
      "begin; #{compile(ast[1], b)}; rescue => #{catch_node[1]}; #{compile(catch_node[2], b)}; end"
    else
      (fn, *args) = ast
      if MACROS[fn]
        compile(MACROS[fn].(*args), b)
      else
        fn = compile(fn, b)
        args.map! { |a| compile(a, b) }
        if (method(fn) rescue nil)
          "#{fn}(#{args.join(', ')})"
        else
          "#{fn}.(#{args.join(', ')})"
        end
      end
    end
  elsif ast.is_a?(Symbol)
    safe_name(ast).to_s
  else
    ast.inspect
  end
end

def compile_block(nodes, b)
  nodes.map { |ast| compile(ast, b) }.join("\n")
end

SAFE_CHARS = /^[A-Za-z_]+$/
ALT_NAMES = {
  :throw => :throw_,
  :print => :print_,
}

def safe_name(name)
  return ALT_NAMES[name] if ALT_NAMES.key?(name)
  name.to_s.chars.map { |c| c =~ SAFE_CHARS ? c : "_#{c.ord}" }.join.to_sym
end

def core_binding
  cons = ->(h, t) { [h] + (t || []) }
  concat = ->(l1, l2) { l1 + l2 }
  b = binding
  require 'pp'
  eval(File.read('core.lisp.rb')).each do |node|
    b.eval(compile(node, b))
  end
  b
end

if $0 == __FILE__
  if ARGV.any?
    b = core_binding
    b.eval(compile_block(eval(File.read(ARGV.first)), b))
  else
    b = core_binding
    loop do
      print "user> "
      str = $stdin.gets
      exit if str.nil?
      ast = eval(str)
      begin
        result = b.eval(compile(ast, b))
      rescue StandardError => e
        puts "#{e.class}: #{e.message}"
        puts e.backtrace
      else
        p result
      end
    end
  end
end
