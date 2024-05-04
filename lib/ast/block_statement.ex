defmodule Monkex.AST.BlockStatement do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.Object.ReturnValue
  alias Monkex.Object.Null
  alias Monkex.AST.Statement

  @enforce_keys [:token, :statements]
  defstruct [:token, :statements]

  defimpl Statement, for: BlockStatement do
    def token_literal(%BlockStatement{token: token}), do: token.literal 
  end

  defimpl String.Chars, for: BlockStatement do
    def to_string(%BlockStatement{token: token, statements: []}), do: "#{token.literal} }"
    def to_string(%BlockStatement{token: token, statements: statements}),
      do: "#{token.literal} #{Enum.join(statements, " ")} }"
  end

  defimpl Node, for: BlockStatement do
    def eval(%BlockStatement{statements: []}), do: %Monkex.Object.Null{}
    def eval(%BlockStatement{statements: [s | []]}), do: Node.eval(s)
    def eval(%BlockStatement{statements: statements}) do
      statements
      |> Enum.reduce_while(Null.object(), fn s, _ ->
        case Node.eval(s) do
          %ReturnValue{value: v} -> {:halt, v |> ReturnValue.from}
          val -> {:cont, val}
        end
      end)
    end

  end
end
