defmodule Monkex.AST.BooleanLiteral do
  @enforce_keys [:token, :value]
  defstruct [:token, :value]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.BooleanLiteral do
  def token_literal(%Monkex.AST.BooleanLiteral{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.BooleanLiteral do
  def to_string(%Monkex.AST.BooleanLiteral{token: token}) do
    token.literal
  end
end
