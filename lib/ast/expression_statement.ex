defmodule Monkex.AST.ExpressionStatement do
  @enforce_keys [:token, :expression]
  defstruct [:token, :expression]
end

defimpl Monkex.AST.Statement, for: Monkex.AST.ExpressionStatement do
  def token_literal(%Monkex.AST.ExpressionStatement{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.ExpressionStatement do
  def to_string(%Monkex.AST.ExpressionStatement{expression: expression}) do
    "#{expression}"
  end
end
