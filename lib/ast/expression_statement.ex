defmodule Monkex.AST.ExpressionStatement do
  alias __MODULE__
  alias Monkex.AST.Statement
  alias Monkex.Object.Node

  @enforce_keys [:token, :expression]
  defstruct [:token, :expression]

  defimpl Statement, for: ExpressionStatement do
    def token_literal(%ExpressionStatement{token: token}), do: token.literal
  end

  defimpl String.Chars, for: ExpressionStatement do
    def to_string(%ExpressionStatement{expression: expression}), do: "#{expression}"
  end

  defimpl Node, for: ExpressionStatement do
    def compile(%ExpressionStatement{expression: expression}, compiler),
      do: Node.compile(expression, compiler)

    def eval(%ExpressionStatement{expression: expression}, env), do: Node.eval(expression, env)
  end
end
