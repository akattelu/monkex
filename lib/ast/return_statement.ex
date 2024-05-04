defmodule Monkex.AST.ReturnStatement do
  alias Monkex.Object.Node
  alias __MODULE__
  alias Monkex.AST.Statement

  @enforce_keys [:token, :return_value]
  defstruct [:token, :return_value]

  defimpl Statement, for: ReturnStatement do
    def token_literal(%ReturnStatement{token: token}), do: token.literal
  end

  defimpl String.Chars, for: ReturnStatement do
    def to_string(%ReturnStatement{token: token, return_value: return_value}),
      do: "#{token.literal} #{return_value};"
  end

  defimpl Node, for: ReturnStatement do
    alias Monkex.Object.ReturnValue

    def eval(%ReturnStatement{return_value: expr}) do
      expr |> Node.eval() |> ReturnValue.from()
    end
  end
end
