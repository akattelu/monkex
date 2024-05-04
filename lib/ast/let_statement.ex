defmodule Monkex.AST.LetStatement do
  alias __MODULE__
  alias Monkex.AST.Statement
  alias Monkex.Object.Node

  @enforce_keys [:token, :name, :value]
  defstruct [:token, :name, :value]

  defimpl Statement, for: LetStatement do
    def token_literal(%LetStatement{token: token}), do: token.literal
  end

  defimpl String.Chars, for: LetStatement do
    def to_string(%LetStatement{name: name, value: value}), do: "let #{name} = #{value};"
  end

  # defimpl Node, for: LetStatement do
  #   def eval(%LetStatement{name: name, value: value}, env) do

  #   end
  # end
end
