defmodule Monkex.AST.BooleanLiteral do
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node
  alias Monkex.Object.Boolean

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Expression, for: BooleanLiteral do
    def token_literal(%BooleanLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: BooleanLiteral do
    def to_string(%BooleanLiteral{token: token}), do: token.literal
  end

  defimpl Node, for: BooleanLiteral do
    def eval(%BooleanLiteral{value: value}, env), do: {Boolean.from(value), env}
  end
end
