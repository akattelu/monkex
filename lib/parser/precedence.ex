defmodule Monkex.Parser.Precedence do
  @moduledoc """
  Utilities for comparing and getting parser expression precedence
  Useful for Monkex's Pratt parser
  """
  alias Monkex.Token

  @precedence [:lowest, :equals, :lessgreater, :sum, :product, :prefix, :access, :call]
  @token_to_precedence %{
    :eq => :equals,
    :not_eq => :equals,
    :lt => :lessgreater,
    :gt => :lessgreater,
    :plus => :sum,
    :minus => :sum,
    :slash => :product,
    :asterisk => :product,
    :lparen => :call,
    :lbracket => :access
  }

  @spec of_token(Token.t()) :: atom()
  def of_token(tok), do: Map.get(@token_to_precedence, tok, :lowest)

  @doc "Compares two precedence levels"
  @spec compare(atom(), atom()) :: integer()
  def compare(p1, p2) do
    to_num = fn x -> Enum.find_index(@precedence, fn p -> p == x end) end
    to_num.(p1) - to_num.(p2)
  end
end
