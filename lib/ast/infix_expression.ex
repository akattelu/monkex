defmodule Monkex.AST.InfixExpression do
  @enforce_keys [:token, :left, :operator, :right]
  defstruct [:token, :left, :operator, :right]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.InfixExpression do
  def token_literal(%Monkex.AST.InfixExpression{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.InfixExpression do
  def to_string(%Monkex.AST.InfixExpression{left: left, operator: op, right: right}) do
    "(#{left} #{op} #{right})"
  end
end
