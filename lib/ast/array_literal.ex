defmodule Monkex.AST.ArrayLiteral do
  @moduledoc """
  AST Node for an array literal like `[1,2,3]`
  """
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.Object.Error
  alias Monkex.Object.Array
  alias Monkex.AST.Expression
  alias Monkex.Compiler

  @enforce_keys [:token, :items]
  defstruct [:token, :items]

  defimpl Expression, for: ArrayLiteral do
    def token_literal(%ArrayLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: ArrayLiteral do
    def to_string(%ArrayLiteral{items: items}), do: "[#{Enum.join(items, ", ")}]"
  end

  defimpl Node, for: ArrayLiteral do
    def compile(%ArrayLiteral{items: items}, compiler) do
      c =
        Enum.reduce(items, compiler, fn item, acc ->
          {:ok, c} = Node.compile(item, acc)
          c
        end)

      {c, _} = Compiler.emit(c, :array, [length(items)])
      {:ok, c}
    end

    def eval(%ArrayLiteral{items: items}, env) do
      {Enum.reduce_while(items, [], fn expr, acc ->
         case Node.eval(expr, env) do
           {%Error{} = e, _} -> {:halt, e}
           {obj, _} -> {:cont, [obj | acc]}
         end
       end)
       |> Enum.reverse()
       |> Array.from(), env}
    end
  end
end
