defmodule Bench do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Token
  alias Monkex.Object.Node

  def tokenize() do
    {:ok, program} = File.read("./examples/string_split.mx")
    lexer = Lexer.new(program)

    Stream.unfold(lexer, fn l ->
      case Lexer.next_token(l) do
        {_, %Token{type: :eof}} -> nil
        {next, _} -> {:ok, next}
      end
    end)
    |> Enum.to_list()
  end

  def parse() do
    {:ok, program} = File.read("./examples/string_split.mx")
    {_p, _ast} = program |> Lexer.new() |> Parser.new() |> Parser.parse_program()
  end

  def eval(parsed_program, env) do
    {_result, _env} = Node.eval(parsed_program, env)
  end
end

env = Monkex.Environment.new() |> Monkex.Environment.with_builtins()

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
    "tokenize" => &Bench.tokenize/0,
    "parse" => &Bench.parse/0,
    "evaluate.string_split" => fn -> Bench.eval(parsed_string_split, env) end,
    "evaluate.fib10" => fn -> Bench.eval(parsed_fib, env) end
  },
  formatters: [{Benchee.Formatters.Console, extended_statistics: true, comparison: false}]
)
