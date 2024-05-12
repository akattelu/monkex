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
end

env = Monkex.Environment.new() |> Monkex.Environment.with_builtins()

{:ok, program} = File.read("./examples/string_split.mx")

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
    "tokenize" => fn -> Bench.tokenize(program) end,
    "parse" => fn -> Bench.parse(program) end,
    "evaluate.string_split" => fn -> Bench.eval(parsed_string_split, env) end,
    "evaluate.fib10" => fn -> Bench.eval(parsed_fib, env) end
  },
  formatters: [{Benchee.Formatters.Console, extended_statistics: false, comparison: false}]
)
