defmodule Bench do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Token
  alias Monkex.Object.Node
  alias Monkex.Compiler
  alias Monkex.VM

  def tokenize(program) do
    lexer = Lexer.new(program)
    nil = read_tok(lexer)
  end

  defp read_tok(l) do
    case Lexer.next_token(l) do
      {_, %Token{type: :eof}} -> nil
      {next, _} -> read_tok(next)
    end
  end

  def parse(program) do
    {_p, _ast} = program |> Lexer.new() |> Parser.new() |> Parser.parse_program()
  end

  def eval_program_string(program, env) do
    {_, ast} = program |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    {_result, _} = Node.eval(ast, env)
  end

  def compile(program) do
    {_, ast} = program |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    {:ok, _} = Node.compile(ast, Compiler.new())
  end

  def eval_vm(program) do
    {_, ast} = program |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    {:ok, c} = Node.compile(ast, Compiler.new())
    {:ok, _} = Compiler.bytecode(c) |> VM.new() |> VM.run()
  end
end

env = Monkex.Environment.new() |> Monkex.Environment.with_builtins()

{:ok, fib_string} = File.read("./examples/fib.mx")
{:ok, cube_string} = File.read("./examples/cube.mx")
{:ok, hof_string} = File.read("./examples/hof.mx")

inputs = %{
  "fib" => fib_string,
  "cube" => cube_string,
  "hof" => hof_string
}

Benchee.run(
  %{
    # "tokenize" => fn input -> Bench.tokenize(input) end,
    # "parse" => fn input -> Bench.parse(input) end,
    # "evaluate with interpreter" => fn input -> Bench.eval_program_string(input, env) end,
    # "compile" => fn input -> Bench.compile(input) end,
    "evaluate with vm" => fn input -> Bench.eval_vm(input) end
  },
  inputs: inputs,
  parallel: 3,
  formatters: [{Benchee.Formatters.Console, extended_statistics: false, comparison: false}]
)
