defmodule Monkex.AST.IfExpression do
  @moduledoc """
  AST Node for an if expression like `if (1 > 2) { 1 } else { 2 }`
  """
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node

  @enforce_keys [:token, :condition, :then_block, :else_block]
  defstruct [:token, :condition, :then_block, :else_block]

  defimpl Expression, for: IfExpression do
    def token_literal(%IfExpression{token: token}), do: token.literal
  end

  defimpl String.Chars, for: IfExpression do
    def to_string(%IfExpression{
          token: token,
          condition: condition,
          then_block: then_block,
          else_block: else_block
        }),
        do: "#{token.literal} (#{condition}) #{then_block} else #{else_block}"
  end

  defimpl Node, for: IfExpression do
    alias Monkex.Object.Null
    alias Monkex.Object.Boolean
    alias Monkex.Object.Integer
    alias Monkex.Object.Error
    def compile(_node, compiler), do: compiler
    def eval(%Error{} = err, env), do: {err, env}

    def eval(
          %IfExpression{condition: condition, then_block: then_block, else_block: else_block},
          env
        ) do
      case {Node.eval(condition, env) |> elem(0), else_block} do
        {%Error{} = err, _} ->
          {err, env}

        # true then always do the then
        {%Boolean{value: true}, _} ->
          Node.eval(then_block, env)

        {%Integer{value: value}, nil} ->
          if value > 0 do
            Node.eval(then_block, env)
          else
            {Null.object(), env}
          end

        {%Integer{value: value}, else_block} ->
          if value > 0 do
            Node.eval(then_block, env)
          else
            Node.eval(else_block, env)
          end

        # falsy and no else block
        {_, nil} ->
          {Null.object(), env}

        # falsy but there is an else block
        {%Boolean{value: false}, else_expr} ->
          Node.eval(else_expr, env)

        # anything else 
        _ ->
          {Null.object(), env}
      end
    end
  end
end
