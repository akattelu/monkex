defmodule Monkex.Lexer do
  alias Monkex.Token
  @enforce_keys [:input, :position, :read_position, :ch]
  defstruct [:input, :position, :read_position, :ch]

  @type t :: %Monkex.Lexer{}

  @spec new(String.t) :: Monkex.Lexer.t()
  def new(input_string) do
    l = %Monkex.Lexer{input: input_string, position: 0, read_position: 0, ch: nil}
    read_char(l)
  end

  @spec next_token(Monkex.Lexer.t()) :: { Monkex.Lexer.t(), Monkex.Token.t() }
  def next_token(lex) do
    l = skip_whitespace(lex)

    cond do
      l.ch == "=" ->
        if peek_char(l) == "=" do
          # consume

          tok = %Token{type: :eq, literal: "=="}
          {read_char(read_char(l)), tok}
        else
          # just assigns
          {read_char(l), Token.from_ch("=")}
        end

      l.ch == "!" ->
        if peek_char(l) == "=" do
          # consume
          {read_char(read_char(l)), %Token{type: :not_eq, literal: "!="}}
        else
          # just bang
          {read_char(l), Token.from_ch("!")}
        end

      Token.is_letter(l.ch) ->
        {lexer, identifier} = read_identifier(l)
        tok = %Token{type: Token.lookup_ident(identifier), literal: identifier}
        {lexer, tok}

      Token.is_digit(l.ch) ->
        {lexer, number} = read_digit(l)
        tok = %Token{type: :int, literal: number}
        {lexer, tok}

      true ->
        tok = Token.from_ch(l.ch)
        next_ch_lexer = read_char(l)
        {next_ch_lexer, tok}
    end
  end

  @spec skip_whitespace(Monkex.Lexer.t()) :: Monkex.Lexer.t()
  defp skip_whitespace(l) do
    if l.ch == " " or l.ch == "\t" or l.ch == "\n" or l.ch == "\r" do
      next_ch_lexer = read_char(l)
      skip_whitespace(next_ch_lexer)
    else
      l
    end
  end

  @spec read_identifier(Monkex.Lexer.t()) :: { Monkex.Lexer.t(), String.t }
  defp read_identifier(l) do
    start = l.position

    final =
      Stream.unfold(l, fn lexer ->
        if Token.is_letter(lexer.ch) do
          next = read_char(lexer)
          {next, next}
        else
          nil
        end
      end)
      # get the last lexer 
      |> Enum.to_list()
      |> Enum.at(-1)

    {final, String.slice(final.input, start, final.position - start)}
  end

  @spec read_digit(Monkex.Lexer.t()) :: { Monkex.Lexer.t(), String.t }
  defp read_digit(l) do
    start = l.position

    final =
      Stream.unfold(l, fn lexer ->
        if Token.is_digit(lexer.ch) do
          next = read_char(lexer)
          {next, next}
        else
          nil
        end
      end)
      # get the last lexer 
      |> Enum.to_list()
      |> Enum.at(-1)

    {final, String.slice(final.input, start, final.position - start)}
  end

  @spec read_char(Monkex.Lexer.t()) :: Monkex.Lexer.t()
  defp read_char(l) do
    %Monkex.Lexer{
      l
      | position: l.read_position,
        read_position: l.read_position + 1,
        # get current character, or nil
        ch:
          if l.read_position >= String.length(l.input) do
            nil
          else
            String.at(l.input, l.read_position)
          end
    }
  end

  @spec peek_char(Monkex.Lexer.t()) :: String.t
  defp peek_char(l) do
    if l.read_position >= String.length(l.input) do
      nil
    else
      String.at(l.input, l.read_position)
    end
  end
end
