defmodule Monkex.REPL do
  @moduledoc """
  Functions for running read-eval-print-loops
  Allows running the REPL in different modes, like lexer, parser, interpreter, vm
  """
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Object.Node
  alias Monkex.Compiler
  alias Monkex.VM

  @monkey_face ~S"""
              __,__
     .--.  .-"     "-.  .--.
    / .. \/  .-. .-.  \/ .. \
   | |  '|  /   Y   \  |'  | |
   | \   \  \ X___X /  /   / |
    \ '- ,\.-\"""\""""-./, -' /
     ''-' /_   ^ ^   _\ '-''
         |  \._____./  |
         \   \     /   /
          '._ '-=-' _.'
             '-----'
  """
  def start_lexer() do
    input = IO.gets(">> ")

    unless input == :eof do
      line = input |> String.trim()

      tokens = line |> Lexer.new() |> list_tokens_from_lexer()

      if Enum.empty?(tokens) do
        nil
      else
        # print tokens
        tokens |> Enum.each(&print_token/1)

        # loop
        start_lexer()
      end
    end
  end

  defp list_tokens_from_lexer(lexer) do
    Stream.unfold(lexer, fn l ->
      {lex, tok} = Lexer.next_token(l)

      if tok.type == :eof do
        nil
      else
        {tok, lex}
      end
    end)
    # get list of parsed tokens
    |> Enum.to_list()
  end

  defp print_token(%Monkex.Token{type: type, literal: literal}),
    do: IO.puts("token type: #{type}, literal: #{literal}")

  defp get_line(input) do
    case input do
      :eof -> {:end}
      "\n" -> {:end}
      line -> {:ok, line |> String.trim()}
    end
  end

  def start_parser() do
    # read
    with input <- IO.gets(">> "),
         {:ok, line} <- get_line(input) do
      # eval
      {parser, program} = line |> Lexer.new() |> Parser.new() |> Parser.parse_program()

      if parser.errors != [] do
        IO.puts("\nWoops! We ran into some monkey business here!")
        IO.puts(@monkey_face)
        IO.puts("Here are the parser errors:")

        parser.errors
        |> Enum.each(fn err ->
          IO.puts("\t - #{err}")
        end)
      else
        # print
        IO.puts("#{program}")
      end

      # loop
      start_parser()
    else
      {:end} -> nil
    end
  end

  def start_compiler_and_vm(compiler) do
    with input <- IO.gets(">> "),
         {:ok, line} <- get_line(input) do
      # parse
      {parser, program} = line |> Lexer.new() |> Parser.new() |> Parser.parse_program()

      if parser.errors != [] do
        IO.puts("\nWoops! We ran into some monkey business here!")
        IO.puts(@monkey_face)
        IO.puts("Here are the parser errors:")

        parser.errors
        |> Enum.each(fn err ->
          IO.puts("\t - #{err}")
        end)

        # loop with old env
        start_compiler_and_vm(compiler)
      else
        # eval 
        {:ok, c} = Node.compile(program, compiler)

        vm = c |> Compiler.bytecode() |> VM.new()

        {:ok, result} = VM.run(vm)
        # print
        result |> VM.stack_last_top() |> IO.puts()

        # loop with new env
        start_compiler_and_vm(c)
      end
    else
      {:end} -> nil
    end
  end

  def start_evaluator(env) do
    # read
    with input <- IO.gets(">> "),
         {:ok, line} <- get_line(input) do
      # parse
      {parser, program} = line |> Lexer.new() |> Parser.new() |> Parser.parse_program()

      if parser.errors != [] do
        IO.puts("\nWoops! We ran into some monkey business here!")
        IO.puts(@monkey_face)
        IO.puts("Here are the parser errors:")

        parser.errors
        |> Enum.each(fn err ->
          IO.puts("\t - #{err}")
        end)

        # loop with old env
        start_evaluator(env)
      else
        # eval 
        {result, next_env} = Node.eval(program, env)
        # print
        IO.puts(result)

        # loop with new env
        start_evaluator(next_env)
      end
    else
      {:end} -> nil
    end
  end
end
