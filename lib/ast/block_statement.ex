defmodule Monkex.AST.BlockStatement do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.Object.ReturnValue
  alias Monkex.Object.Error
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
    def eval(%BlockStatement{statements: []}, env), do: {Null.object(), env}
    def eval(%BlockStatement{statements: [s | []]}, env), do: Node.eval(s, env)

    def eval(%BlockStatement{statements: statements}, env) do
      statements
      |> Enum.reduce_while(Null.object(), fn s, _ ->
        case Node.eval(s, env) do
          %Error{} = err -> {:halt, err}
          %ReturnValue{} = val -> {:halt, val}
          val -> {:cont, val}
        end
      end)
    end
  end
end
