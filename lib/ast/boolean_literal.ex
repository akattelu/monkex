defmodule Monkex.AST.BooleanLiteral do
  @moduledoc """
  AST Node for a boolean literal like `true` or `false`
  """

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
    alias Monkex.Compiler

    def compile(%BooleanLiteral{value: value}, compiler) do
      {c, _} = Compiler.emit(compiler, value, [])
      {:ok, c}
    end

    def eval(%BooleanLiteral{value: value}, env), do: {Boolean.from(value), env}
  end
end
