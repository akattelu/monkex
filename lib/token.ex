defmodule Monkex.Token do
  alias __MODULE__
  @enforce_keys [:type, :literal]
  defstruct [:type, :literal]

  @type t :: %Token{type: atom, literal: String.t()}

  @keywords %{
    "fn" => :function,
    "let" => :let,
    "true" => true,
    "false" => false,
    "if" => :if,
    "else" => :else,
    "return" => :return
  }

  @doc "Looks up special keywords and defaults to :ident"
  @spec lookup_ident(String.t()) :: atom
  def lookup_ident(ident), do: Map.get(@keywords, ident, :ident)

  @spec from_ch(String.t()) :: Token.t()
  def from_ch("="), do: %Token{type: :assign, literal: "="}
  def from_ch("+"), do: %Token{type: :plus, literal: "+"}
  def from_ch("("), do: %Token{type: :lparen, literal: "("}
  def from_ch(")"), do: %Token{type: :rparen, literal: ")"}
  def from_ch("{"), do: %Token{type: :lbrace, literal: "{"}
  def from_ch("}"), do: %Token{type: :rbrace, literal: "}"}
  def from_ch(","), do: %Token{type: :comma, literal: ","}
  def from_ch(";"), do: %Token{type: :semicolon, literal: ";"}
  def from_ch("!"), do: %Token{type: :bang, literal: "!"}
  def from_ch("*"), do: %Token{type: :asterisk, literal: "*"}
  def from_ch("/"), do: %Token{type: :slash, literal: "/"}
  def from_ch("-"), do: %Token{type: :minus, literal: "-"}
  def from_ch("<"), do: %Token{type: :lt, literal: "<"}
  def from_ch(">"), do: %Token{type: :gt, literal: ">"}
  def from_ch(nil), do: %Token{type: :eof, literal: ""}
  def from_ch(illegal), do: %Token{type: :illegal, literal: illegal}

  @spec is_letter(String.t()) :: boolean
  def is_letter(char) when char == "" or char == nil, do: false
  def is_letter(char) do
    # convert to ascii val
    ch = char |> String.to_charlist() |> hd
    (?a <= ch and ch <= ?z) or (?A <= ch and ch <= ?Z) or ch == ?_
  end

  @spec is_digit(String.t()) :: boolean
  def is_digit(char) when char == "" or char == nil, do: false
  def is_digit(char) do
    # convert to ascii val
    ch = char |> String.to_charlist() |> hd
    ?0 <= ch and ch <= ?9
  end
end
