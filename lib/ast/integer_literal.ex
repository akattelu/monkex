defmodule Monkex.AST.IntegerLiteral do
  @enforce_keys [:token, :value]
  defstruct [:token, :value]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.IntegerLiteral do
  def token_literal(%Monkex.AST.IntegerLiteral{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.IntegerLiteral do
  def to_string(%Monkex.AST.IntegerLiteral{token: token}) do
    token.literal
  end
end
