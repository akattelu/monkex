defmodule Monkex do
  alias Monkex.Object
  alias Monkex.Environment
  alias Monkex.Lexer
  alias Monkex.Parser

  defp check_errors(%Parser{errors: []}), do: :ok
  defp check_errors(%Parser{errors: errors}), do: {:error, Enum.join(errors, "\n")}
  defp check_errors(%Object.Error{} = err), do: {:error, err}
  defp check_errors(_), do: :ok

  def run(filename) do
    with {:ok, input} <- File.read(filename),
         {p, program} <-
           input |> String.trim() |> Lexer.new() |> Parser.new() |> Parser.parse_program(),
         :ok <- check_errors(p),
         env = Environment.new() |> Environment.with_builtins(),
         {result, _} = Object.Node.eval(program, env),
         :ok <- check_errors(result) do
      IO.puts(result)
    else
      {:error, msg} ->
        IO.puts(msg)
        System.halt(1)
    end
  end
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
            Monkex.run(arg)

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
