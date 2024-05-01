defmodule Mix.Tasks.Repl do
  @moduledoc "Start the Monkex REPL\r\n
  --lex
    Start the REPL as a tokenizer and print out tokens

  --parse (default)
    Start the REPL as a parser and print out string representations of ASTs
  "
  @shortdoc "Start the Monkex REPL"
  @requirements ["app.config"]

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {name, _} = System.cmd("whoami", [])
    IO.puts("Hello #{name |> String.trim()}, this is MonkEx")
    IO.puts("Feel free to type in some commands!\n")

    if "--lex" in args do
      Monkex.REPL.start_lexer()
    else
      Monkex.REPL.start_parser()
    end

    IO.puts("Bye!")
  end
end
