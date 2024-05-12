defmodule Bench do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Token
  alias Monkex.Object.Node

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

  def eval(parsed_program, env) do
    {_result, _env} = Node.eval(parsed_program, env)
  end

  def parse_and_eval(program, env) do
    {_, ast} = program |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    {_result, _} = Node.eval(ast, env)
  end
end

env = Monkex.Environment.new() |> Monkex.Environment.with_builtins()

{:ok, fib_string} = File.read("./examples/fib.mx")
{:ok, split_string} = File.read("./examples/string_split.mx")

{_, parsed_fib} =
  File.read("./examples/fib.mx")
  |> elem(1)
  |> Monkex.Lexer.new()
  |> Monkex.Parser.new()
  |> Monkex.Parser.parse_program()

{_, parsed_string_split} =
  File.read("./examples/string_split.mx")
  |> elem(1)
  |> Monkex.Lexer.new()
  |> Monkex.Parser.new()
  |> Monkex.Parser.parse_program()

Benchee.run(
  %{
    "tokenize" => fn -> Bench.tokenize(split_string) end,
    "parse" => fn -> Bench.parse(split_string) end,
    "evaluate.string_split" => fn -> Bench.eval(parsed_string_split, env) end,
    "evaluate.fib10" => fn -> Bench.eval(parsed_fib, env) end,
    "parse_and_evaluate.string_split" => fn -> Bench.parse_and_eval(split_string, env) end,
    "parse_and_evaluate.fib10" => fn -> Bench.parse_and_eval(fib_string, env) end
  },
  formatters: [{Benchee.Formatters.Console, extended_statistics: false, comparison: false}]
)
