defmodule Monkex.AST.Identifier do
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node
  alias Monkex.Object.Error
  alias Monkex.Environment

  @enforce_keys [:token, :symbol_name]
  defstruct [:token, :symbol_name]

  defimpl Expression, for: Identifier do
    def token_literal(%Identifier{token: token}), do: token.literal
  end

  defimpl String.Chars, for: Identifier do
    def to_string(%Identifier{symbol_name: symbol_name}), do: symbol_name
  end

  defimpl Node, for: Identifier do
    def compile(compiler, _node), do: compiler

    def eval(%Identifier{symbol_name: symbol_name}, env) do
      case Environment.get(env, symbol_name) do
        :undefined -> {Error.with_message("identifier not found: #{symbol_name}"), env}
        {:ok, obj} -> {obj, env}
      end
    end
  end
end
