defmodule Monkex.AST.IfExpression do
  @enforce_keys [:token, :condition, :then_block, :else_block]
  defstruct [:token, :condition, :then_block, :else_block]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.IfExpression do
  def token_literal(%Monkex.AST.IfExpression{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.IfExpression do
  def to_string(%Monkex.AST.IfExpression{
        token: token,
        condition: condition,
        then_block: then_block,
        else_block: else_block
      }) do
    "#{token.literal} (#{condition}) #{then_block} else #{else_block}"
  end
end
