defmodule Monkex.AST.Identifier do
  @enforce_keys [:token, :symbol_name]
  defstruct [:token, :symbol_name]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.Identifier do
  def token_literal(%Monkex.AST.Identifier{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.Identifier do
  def to_string(%Monkex.AST.Identifier{symbol_name: symbol_name}) do
    symbol_name
  end
end