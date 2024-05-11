defmodule Mix.Tasks.Repl do
  @moduledoc "Start the Monkex REPL\r\n
  --lex
    Start the REPL as a tokenizer and print out tokens

  --parse
    Start the REPL as a parser and print out string representations of ASTs

  --eval (default)
    Start the REPL as an evaluator and evaluate monkex programs
  "
  @shortdoc "Start the Monkex REPL"
  @requirements ["app.config"]

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {name, _} = System.cmd("whoami", [])
    IO.puts("Hello #{name |> String.trim()}, this is MonkEx")
    IO.puts("Feel free to type in some commands!\n")

    cond do
      "--lex" in args ->
        Monkex.REPL.start_lexer()

      "--parse" in args ->
        Monkex.REPL.start_parser()

      true ->
        Monkex.REPL.start_evaluator(
          Monkex.Environment.new()
          |> Monkex.Environment.with_builtins()
        )
    end

    IO.puts("Bye!")
  end
end
