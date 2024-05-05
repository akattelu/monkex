defmodule Monkex.AST.ArrayLiteral do
  alias __MODULE__
  alias Monkex.AST.Expression

  @enforce_keys [:token, :items]
  defstruct [:token, :items]

  defimpl Expression, for: ArrayLiteral do
    def token_literal(%ArrayLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: ArrayLiteral do
    def to_string(%ArrayLiteral{items: items}), do: "[#{Enum.join(items, ", ")}]"
  end
end
