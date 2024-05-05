defmodule Monkex.AST.StringLiteral do
  alias __MODULE__
  alias Monkex.AST.Expression

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Expression, for: StringLiteral do
    def token_literal(%StringLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: StringLiteral do
    def to_string(%StringLiteral{value: value}), do: "\"#{value}\""
  end
end
