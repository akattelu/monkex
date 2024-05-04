defmodule Monkex.AST.IfExpression do
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
    def eval(%Error{} = err), do: err

    def eval(%IfExpression{condition: condition, then_block: then_block, else_block: else_block}) do
      case {Node.eval(condition), else_block} do
        {%Error{} = err, _} -> err
        # true then always do the then
        {%Boolean{value: true}, _} ->
          Node.eval(then_block)

        {%Integer{value: value}, nil} ->
          if value > 0 do
            Node.eval(then_block)
          else
            Null.object()
          end

        {%Integer{value: value}, else_block} ->
          if value > 0 do
            Node.eval(then_block)
          else
            Node.eval(else_block)
          end

        # falsy and no else block
        {_, nil} ->
          Null.object()

        # falsy but there is an else block
        {%Boolean{value: false}, else_expr} ->
          Node.eval(else_expr)

        # anything else 
        _ ->
          Null.object()
      end
    end
  end
end
