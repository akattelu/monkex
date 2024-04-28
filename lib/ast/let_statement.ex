defmodule Monkex.AST.LetStatement do
  @enforce_keys [:token, :name, :value]
  defstruct [:token, :name, :value]
end

defimpl Monkex.AST.Statement, for: Monkex.AST.LetStatement do
  def token_literal(%Monkex.AST.LetStatement{token: token}) do
    token.literal
  end
end
