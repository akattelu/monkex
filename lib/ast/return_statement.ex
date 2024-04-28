defmodule Monkex.AST.ReturnStatement do
  @enforce_keys [:token, :return_value]
  defstruct [:token, :return_value]
end

defimpl Monkex.AST.Statement, for: Monkex.AST.ReturnStatement do
  def token_literal(%Monkex.AST.ReturnStatement{token: token}) do
    token.literal
  end
end
