defmodule Monkex.AST.IntegerLiteral do
  @moduledoc """
  AST Node for an integer literal like `42`
  """
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node
  alias Monkex.Object.Integer
  alias Monkex.Compiler

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl Expression, for: IntegerLiteral do
    def token_literal(%IntegerLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: IntegerLiteral do
    def to_string(%IntegerLiteral{token: token}), do: token.literal
  end

  defimpl Node, for: IntegerLiteral do
    def compile(%IntegerLiteral{value: value}, compiler) do
      {next, pointer} = compiler |> Compiler.with_constant(Integer.from(value))
      {final, _} = Compiler.emit(next, :constant, [pointer])
      {:ok, final}
    end

    def eval(%IntegerLiteral{value: value}, env), do: {Integer.from(value), env}
  end
end
