defmodule Monkex.Lexer do
  alias __MODULE__
  alias Monkex.Token

  @enforce_keys [:input, :position, :read_position, :ch]
  defstruct [:input, :position, :read_position, :ch]

  @type t :: %Lexer{}

  @spec new(String.t()) :: Lexer.t()
  def new(input_string) do
    %Lexer{input: input_string, position: 0, read_position: 0, ch: nil} |> read_char
  end

  @doc "Read characters on lexer until reducer function returns false on the current character"
  @spec advance_while(Lexer.t(), (String.t() -> boolean())) :: Lexer.t()
  def advance_while(l, reducer) do
    case reducer.(l.ch) do
      false -> l
      true -> l |> read_char |> advance_while(reducer)
    end
  end

  @spec next_token(Lexer.t()) :: {Lexer.t(), Monkex.Token.t()}
  def next_token(lex) do
    l = skip_whitespace(lex)

    cond do
      l.ch == "=" ->
        if peek_char(l) == "=" do
          # consume

          tok = %Token{type: :eq, literal: "=="}
          {l |> read_char |> read_char, tok}
        else
          # just assigns
          {l |> read_char, Token.from_ch("=")}
        end

      l.ch == "!" ->
        if peek_char(l) == "=" do
          # consume
          {l |> read_char |> read_char, %Token{type: :not_eq, literal: "!="}}
        else
          # just bang
          {l |> read_char, Token.from_ch("!")}
        end

      l.ch == "\"" ->
        l |> read_string |> then(fn {l, str} -> {l, %Token{type: :string, literal: str}} end)

      Token.is_letter(l.ch) ->
        {lexer, identifier} = read_identifier(l)
        tok = %Token{type: Token.lookup_ident(identifier), literal: identifier}
        {lexer, tok}

      Token.is_digit(l.ch) ->
        {lexer, number} = read_digit(l)
        tok = %Token{type: :int, literal: number}
        {lexer, tok}

      true ->
        {l |> read_char, l.ch |> Token.from_ch()}
    end
  end

  @spec skip_whitespace(Lexer.t()) :: Lexer.t()
  defp skip_whitespace(l) when l.ch in ["\t", "\n", "\r", " "],
    do: l |> read_char |> skip_whitespace

  defp skip_whitespace(l), do: l

  @spec read_identifier(Lexer.t()) :: {Lexer.t(), String.t()}
  defp read_identifier(initial) do
    final = initial |> advance_while(&Token.is_letter(&1))
    {final, String.slice(final.input, initial.position, final.position - initial.position)}
  end

  @spec read_digit(Lexer.t()) :: {Lexer.t(), String.t()}
  defp read_digit(initial) do
    final = initial |> advance_while(&Token.is_digit(&1))
    {final, String.slice(final.input, initial.position, final.position - initial.position)}
  end

  @spec read_string(Lexer.t()) :: {Lexer.t(), String.t()}
  defp read_string(initial) do
    final = initial |> read_char |> advance_while(&(&1 != "\"")) |> read_char
    # do not read the first quote or the end quote
    {final,
     String.slice(final.input, initial.position + 1, final.position - initial.position - 2)}
  end

  @spec read_char(Lexer.t()) :: Lexer.t()
  defp read_char(l) do
    %Lexer{
      l
      | position: l.read_position,
        read_position: l.read_position + 1,
        # get current character, or nil
        ch: String.at(l.input, l.read_position)
    }
  end

  @spec peek_char(Lexer.t()) :: String.t()
  defp peek_char(l), do: String.at(l.input, l.read_position)
end
