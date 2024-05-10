defmodule Monkex.AST.AccessExpression do
  alias Monkex.Object
  alias Monkex.Object.Node
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Error
  alias Monkex.Object.Array
  alias Monkex.Object.Integer

  @enforce_keys [:token, :indexable_expr, :index_expr]
  defstruct [:token, :indexable_expr, :index_expr]

  defimpl Expression, for: AccessExpression do
    def token_literal(%AccessExpression{token: token}), do: token.literal
  end

  defimpl String.Chars, for: AccessExpression do
    def to_string(%AccessExpression{
          indexable_expr: indexable,
          index_expr: index
        }),
        do: "#{indexable}[#{index}]"
  end

  defimpl Node, for: AccessExpression do
    alias Monkex.Object.Null

    defp is_array_obj(obj) do
      case obj do
        %Array{} = result -> {:ok, result}
        other -> {:error, "tried to access non-array object: #{Object.type(other)}"}
      end
    end

    defp is_integer_obj(obj) do
      case obj do
        %Integer{} = result -> {:ok, result}
        other -> {:error, "tried to access array with non-integer index: #{Object.type(other)}"}
      end
    end

    defp check_array_bounds(items, index) do
      if index >= length(items) do
        {:error, "index out of bounds"}
      else
        :ok
      end
    end

    def eval(%AccessExpression{indexable_expr: indexable_expr, index_expr: index_expr}, env) do
      with {indexable_obj, _} <- Node.eval(indexable_expr, env),
           {:ok, %Array{items: items}} <- is_array_obj(indexable_obj),
           {index_obj, _} <- Node.eval(index_expr, env),
           {:ok, %Integer{value: index}} <- is_integer_obj(index_obj),
           :ok <- check_array_bounds(items, index) do
        {Enum.at(items, index, Null.object()), env}
      else
        {:error, msg} -> {Error.with_message(msg), env}
        {%Error{}, _} = result -> result
      end
    end
  end
end
