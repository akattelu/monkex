defmodule Monkex.AST.StringLiteral do
  @moduledoc """
  AST Node for a string literal like `"hello world"`
  """
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object
  alias Monkex.Object.Node

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Expression, for: StringLiteral do
    def token_literal(%StringLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: StringLiteral do
    def to_string(%StringLiteral{value: value}), do: "\"#{value}\""
  end

  defimpl Node, for: StringLiteral do
    def compile(_node, compiler), do: compiler
    def eval(%StringLiteral{value: value}, env), do: {Object.String.from(value), env}
  end
end
