defmodule Monkex.AST.Identifier do
  @moduledoc """
  AST Node for an identifier like `foo`
  """

  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node
  alias Monkex.Object.Error
  alias Monkex.Environment
  alias Monkex.Compiler
  alias Monkex.Symbol

  @enforce_keys [:token, :symbol_name]
  defstruct [:token, :symbol_name]

  defimpl Expression, for: Identifier do
    def token_literal(%Identifier{token: token}), do: token.literal
  end

  defimpl String.Chars, for: Identifier do
    def to_string(%Identifier{symbol_name: symbol_name}), do: symbol_name
  end

  defimpl Node, for: Identifier do
    def compile(%Identifier{symbol_name: symbol_name}, compiler) do
      case Compiler.get_symbol(compiler, symbol_name) do
        {:ok, %Symbol{index: idx, scope: :global}} ->
          {c, _} = Compiler.emit(compiler, :get_global, [idx])
          {:ok, c}

        {:ok, %Symbol{index: idx, scope: :local}} ->
          {c, _} = Compiler.emit(compiler, :get_local, [idx])
          {:ok, c}

        {:ok, %Symbol{index: idx, scope: :builtin}} ->
          {c, _} = Compiler.emit(compiler, :get_builtin, [idx])
          {:ok, c}

        :undefined ->
          {:error, "undefined symbol #{symbol_name}"}
      end
    end

    def eval(%Identifier{symbol_name: symbol_name}, env) do
      case Environment.get(env, symbol_name) do
        :undefined -> {Error.with_message("identifier not found: #{symbol_name}"), env}
        {:ok, obj} -> {obj, env}
      end
    end
  end
end
