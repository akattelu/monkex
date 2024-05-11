defmodule Monkex do
end

defmodule Monkex.CLI do
  def main(args) do
    # args = System.argv()

    case args do
      [] ->
        # Start REPL
        Monkex.REPL.start_evaluator(
          Monkex.Environment.new()
          |> Monkex.Environment.with_builtins()
        )

      ["--lex" | _] ->
        # Start REPL in lexing mode
        Monkex.REPL.start_lexer()

      ["--parse" | _] ->
        # Start REPL in parsing mode
        Monkex.REPL.start_parser()

      ["--help" | _] ->
        IO.puts("Usage: monkex [--lex|--parse|<filename>]")

      [arg] ->
        cond do
          String.starts_with?(arg, "--") ->
            IO.puts("Usage: monkex [--lex|--parse|<filename>]")
            System.halt(1)

          String.ends_with?(arg, ".mx") ->
            # Run interpreter on file
            # Monkex.run(filename)
            nil

          true ->
            IO.puts("Usage: monkex [--lex|--parse|<filename>]")
            System.halt(1)
        end

      _ ->
        IO.puts("Usage: monkex [--lex|--parse|<filename>]")
        System.halt(1)
    end

    System.halt(0)
  end
end
