defmodule Monkex.REPL do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Object.Node

  @monkey_face ~S"""
              __,__
     .--.  .-"     "-.  .--.
    / .. \/  .-. .-.  \/ .. \
   | |  '|  /   Y   \  |'  | |
   | \   \  \ x | x /  /   / |
    \ '- ,\.-\"""\""""-./, -' /
     ''-' /_   ^ ^   _\ '-''
         |  \._   _./  |
         \   \ '~' /   /
          '._ '-=-' _.'
             '-----'
  """
  def start_lexer() do
    input = IO.gets(">> ")

    unless input == :eof do
      line = input |> String.trim()

      tokens =
        Lexer.new(line)
        |> Stream.unfold(fn l ->
          {lex, tok} = Lexer.next_token(l)

          if tok.type == :eof do
            nil
          else
            {tok, lex}
          end
        end)
        # get list of parsed tokens
        |> Enum.to_list()

      if Enum.empty?(tokens) do
        nil
      else
        # print tokens
        tokens |> Enum.map(&IO.inspect/1)

        # loop
        start_lexer()
      end
    end
  end

  defp get_line(input) do
    case input do
      :eof -> {:end}
      "\n" -> {:end}
      line -> {:ok, line |> String.trim()}
    end
  end

  def start_parser() do
    with input <- IO.gets(">> "), # read
         {:ok, line} <- get_line(input),
         {parser, program} = line |> Lexer.new() |> Parser.new() |> Parser.parse_program() do # eval
      if parser.errors != [] do
        IO.puts("\nWoops! We ran into some monkey business here!")
        IO.puts(@monkey_face)
        IO.puts("Here are the parser errors:")

        parser.errors
        |> Enum.each(fn err ->
          IO.puts("\t - #{err}")
        end)
      else
        IO.puts("#{program}") # print
      end

      # loop
      start_parser()
    else
      {:end} -> nil
    end
  end

  def start_evaluator() do
    with input <- IO.gets(">> "), # read
         {:ok, line} <- get_line(input),
         {parser, program} = line |> Lexer.new() |> Parser.new() |> Parser.parse_program() do # parse
      if parser.errors != [] do
        IO.puts("\nWoops! We ran into some monkey business here!")
        IO.puts(@monkey_face)
        IO.puts("Here are the parser errors:")

        parser.errors
        |> Enum.each(fn err ->
          IO.puts("\t - #{err}")
        end)
      else
        env = nil
        {result, _}= Node.eval(program, env) # eval 
        IO.puts(result) # print
      end

      # loop
      start_evaluator()
    else
      {:end} -> nil
    end
  end
end
