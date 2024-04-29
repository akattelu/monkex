defmodule Monkex.AST.PrefixExpression do
  @enforce_keys [:token, :operator, :right]
  defstruct [:token, :operator, :right]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.PrefixExpression do
  def token_literal(%Monkex.AST.PrefixExpression{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.PrefixExpression do
  def to_string(%Monkex.AST.PrefixExpression{operator: op, right: right}) do
    "(#{op} #{right})"
  end
end
