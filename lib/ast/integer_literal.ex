defmodule Monkex.AST.IntegerLiteral do
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node
  alias Monkex.Object.Integer

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Expression, for: IntegerLiteral do
    def token_literal(%IntegerLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: IntegerLiteral do
    def to_string(%IntegerLiteral{token: token}), do: token.literal
  end

  defimpl Node, for: IntegerLiteral do
    def eval(%IntegerLiteral{value: value}), do: %Integer{value: value}
  end
end
