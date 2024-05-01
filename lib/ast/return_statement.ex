defmodule Monkex.AST.ReturnStatement do
  @enforce_keys [:token, :return_value]
  defstruct [:token, :return_value]
end

defimpl Monkex.AST.Statement, for: Monkex.AST.ReturnStatement do
  def token_literal(%Monkex.AST.ReturnStatement{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.ReturnStatement do
  def to_string(%Monkex.AST.ReturnStatement{token: token, return_value: return_value}) do
    "#{token.literal} #{return_value};"
  end
end
