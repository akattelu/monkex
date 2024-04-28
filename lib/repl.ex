defmodule Monkex.REPL do
  alias Monkex.Lexer

  def start() do
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
        start()
      end
    end
  end
end
