defmodule Monkex do
  @moduledoc false
  alias Monkex.Object
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Compiler
  alias Monkex.VM

  defp check_errors(%Parser{errors: []}), do: :ok
  defp check_errors(%Parser{errors: errors}), do: {:error, Enum.join(errors, "\n")}
  defp check_errors(%Object.Error{} = err), do: {:error, err}
  defp check_errors(_), do: :ok

  def run(filename) do
    with {:ok, input} <- File.read(filename),
         {p, program} <-
           input |> String.trim() |> Lexer.new() |> Parser.new() |> Parser.parse_program(),
         :ok <- check_errors(p),
         {:ok, c} <- Compiler.new() |> Compiler.compile(program),
         {:ok, result} <- c |> Compiler.bytecode() |> VM.new() |> VM.run(),
         :ok <- check_errors(result) do
      IO.puts(VM.stack_last_top(result))
    else
      {:error, msg} ->
        IO.puts(msg)
        System.halt(1)
    end
  end
end

defmodule Monkex.CLI do
  @moduledoc "Entrypoint methods for interacting with the monkex via CLI"

  def main([]) do
    # Start REPL
    Monkex.REPL.start_evaluator(
      Monkex.Environment.new()
      |> Monkex.Environment.with_builtins()
    )

    System.halt(0)
  end

  def main(["--lex" | _]) do
    # Start REPL in lexing mode
    Monkex.REPL.start_lexer()
    System.halt(0)
  end

  def main(["--parse" | _]) do
    # Start REPL in lexing mode
    Monkex.REPL.start_parser()
    System.halt(0)
  end

  def main(["--help" | _]) do
    IO.puts("Usage: monkex [--lex|--parse|<filename>]")
    System.halt(0)
  end

  def main([arg]) do
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
  end

  def main(_) do
    IO.puts("Usage: monkex [--lex|--parse|<filename>]")
    System.halt(1)
  end
end
