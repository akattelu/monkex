defmodule Monkex.AST.AccessExpression do
  @moduledoc """
  AST Node for AccessExpression such as `arr[0]`
  """

  alias __MODULE__
  alias Monkex.Object
  alias Monkex.AST.Expression
  alias Monkex.Object.{Error, Array, Integer, Dictionary, Node}
  alias Monkex.Compiler

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
    def compile(%AccessExpression{indexable_expr: indexable, index_expr: index}, compiler) do
      {:ok, c} = Node.compile(indexable, compiler)
      {:ok, c} = Node.compile(index, c)
      {c, _} = Compiler.emit(c, :index, [])
      {:ok, c}
    end

    defp indexable?(obj) do
      case obj do
        %Array{} = result -> {:ok, result}
        %Dictionary{} = result -> {:ok, result}
        other -> {:error, "tried to access non-indexable object: #{Object.type(other)}"}
      end
    end

    defp index?(obj, indexable_type) do
      case {obj, indexable_type} do
        {%Integer{}, :array} ->
          {:ok, obj}

        {%Object.String{}, :dict} ->
          {:ok, obj}

        {other, expected} ->
          {:error, "tried to access #{expected} with invalid index type: #{Object.type(other)}"}
      end
    end

    def eval(%AccessExpression{indexable_expr: indexable_expr, index_expr: index_expr}, env) do
      with {indexable_obj, _} <- Node.eval(indexable_expr, env),
           {:ok, %Array{} = arr} <- indexable?(indexable_obj) do
        eval_array(index_expr, env, arr)
      else
        {:ok, %Dictionary{} = dict} -> eval_dict(index_expr, env, dict)
        {:error, msg} -> {Error.with_message(msg), env}
        {%Error{}, _} = result -> result
      end
    end

    def eval_dict(index_expr, env, dict) do
      with {index_obj, _} <- Node.eval(index_expr, env),
           {:ok, index} <- index?(index_obj, :dict) do
        {Dictionary.at(dict, index), env}
      else
        {:error, msg} -> {Error.with_message(msg), env}
        {%Error{}, _} = result -> result
      end
    end

    def eval_array(index_expr, env, arr) do
      with {index_obj, _} <- Node.eval(index_expr, env),
           {:ok, %Integer{value: index}} <- index?(index_obj, :array),
           {:ok, val} <- Array.at(arr, index) do
        {val, env}
      else
        {:error, msg} -> {Error.with_message(msg), env}
        {%Error{}, _} = result -> result
      end
    end
  end
end
