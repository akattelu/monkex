defmodule Monkex.AST.StringLiteral do
  @moduledoc """
  AST Node for a string literal like `"hello world"`
  """
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object
  alias Monkex.Object.Node
  alias Monkex.Compiler

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Expression, for: StringLiteral do
    def token_literal(%StringLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: StringLiteral do
    def to_string(%StringLiteral{value: value}), do: "\"#{value}\""
  end

  defimpl Node, for: StringLiteral do
    def compile(%StringLiteral{value: value}, compiler) do
      {next, pointer} = compiler |> Compiler.with_constant(Object.String.from(value))
      {final, _} = Compiler.emit(next, :constant, [pointer])
      {:ok, final}
    end
    def eval(%StringLiteral{value: value}, env), do: {Object.String.from(value), env}
  end
end
