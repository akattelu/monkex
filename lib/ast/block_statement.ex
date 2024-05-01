defmodule Monkex.AST.BlockStatement do
  @enforce_keys [:token, :statements]
  defstruct [:token, :statements]
end

defimpl Monkex.AST.Statement, for: Monkex.AST.BlockStatement do
  def token_literal(%Monkex.AST.BlockStatement{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.BlockStatement do
  def to_string(%Monkex.AST.BlockStatement{token: token, statements: []}), do: "#{token.literal} }"
  def to_string(%Monkex.AST.BlockStatement{token: token, statements: statements}), do: "#{token.literal} #{Enum.join(statements, " ")} }"
end
