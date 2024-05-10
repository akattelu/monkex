defmodule Monkex.AST.AccessExpression do
  alias __MODULE__
  alias Monkex.AST.Expression

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
end
