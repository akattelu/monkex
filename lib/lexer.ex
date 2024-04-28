defmodule Monkex.Token do
  @enforce_keys [:type, :literal]
  defstruct [:type, :literal]

  @keywords %{
    "fn" => :function,
    "let" => :let,
    "true" => true,
    "false" => false,
    "if" => :if,
    "else" => :else,
    "return" => :return
  }

  def lookup_ident(ident) do
    # default to :ident type
    Map.get(@keywords, ident, :ident)
  end

  def from_ch("="), do: %Monkex.Token{type: :assign, literal: "="}
  def from_ch("+"), do: %Monkex.Token{type: :plus, literal: "+"}
  def from_ch("("), do: %Monkex.Token{type: :lparen, literal: "("}
  def from_ch(")"), do: %Monkex.Token{type: :rparen, literal: ")"}
  def from_ch("{"), do: %Monkex.Token{type: :lbrace, literal: "{"}
  def from_ch("}"), do: %Monkex.Token{type: :rbrace, literal: "}"}
  def from_ch(","), do: %Monkex.Token{type: :comma, literal: ","}
  def from_ch(";"), do: %Monkex.Token{type: :semicolon, literal: ";"}
  def from_ch("!"), do: %Monkex.Token{type: :bang, literal: "!"}
  def from_ch("*"), do: %Monkex.Token{type: :asterisk, literal: "*"}
  def from_ch("/"), do: %Monkex.Token{type: :slash, literal: "/"}
  def from_ch("-"), do: %Monkex.Token{type: :minus, literal: "-"}
  def from_ch("<"), do: %Monkex.Token{type: :lt, literal: "<"}
  def from_ch(">"), do: %Monkex.Token{type: :gt, literal: ">"}
  def from_ch(nil), do: %Monkex.Token{type: :eof, literal: ""}
  def from_ch(illegal), do: %Monkex.Token{type: :illegal, literal: illegal}


  def is_letter(char) when char == "" or char == nil, do: false
  def is_letter(char) do
    # convert to ascii val
    ch = char |> String.to_charlist() |> hd
    (?a <= ch and ch <= ?z) or (?A <= ch and ch <= ?Z) or ch == ?_
  end

  def is_digit(char) when char == "" or char == nil, do: false
  def is_digit(char) do
    # convert to ascii val
    ch = char |> String.to_charlist() |> hd
    ?0 <= ch and ch <= ?9
  end
end

defmodule Monkex.Lexer do
  alias Monkex.Token
  @enforce_keys [:input, :position, :read_position, :ch]
  defstruct [:input, :position, :read_position, :ch]

  def new(input_string) do
    l = %Monkex.Lexer{input: input_string, position: 0, read_position: 0, ch: nil}
    read_char(l)
  end

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

  defp skip_whitespace(l) do
    if l.ch == " " or l.ch == "\t" or l.ch == "\n" or l.ch == "\r" do
      next_ch_lexer = read_char(l)
      skip_whitespace(next_ch_lexer)
    else
      l
    end
  end

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

  defp peek_char(l) do
    if l.read_position >= String.length(l.input) do
      nil
    else
      String.at(l.input, l.read_position)
    end
  end
end
