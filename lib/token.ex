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

  @spec lookup_ident(String.t) :: atom
  def lookup_ident(ident) do
    # default to :ident type
    Map.get(@keywords, ident, :ident)
  end

  @spec from_ch(String.t) :: %Monkex.Token{}
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


  @spec is_letter(String.t) :: boolean
  def is_letter(char) when char == "" or char == nil, do: false
  def is_letter(char) do
    # convert to ascii val
    ch = char |> String.to_charlist() |> hd
    (?a <= ch and ch <= ?z) or (?A <= ch and ch <= ?Z) or ch == ?_
  end

  @spec is_digit(String.t) :: boolean
  def is_digit(char) when char == "" or char == nil, do: false
  def is_digit(char) do
    # convert to ascii val
    ch = char |> String.to_charlist() |> hd
    ?0 <= ch and ch <= ?9
  end
end
