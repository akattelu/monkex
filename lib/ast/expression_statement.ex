defmodule Monkex.AST.ExpressionStatement do
  alias __MODULE__
  alias Monkex.AST.Statement
  alias Monkex.Object.Node
  alias Monkex.Compiler

  @enforce_keys [:token, :expression]
  defstruct [:token, :expression]

  defimpl Statement, for: ExpressionStatement do
    def token_literal(%ExpressionStatement{token: token}), do: token.literal
  end

  defimpl String.Chars, for: ExpressionStatement do
    def to_string(%ExpressionStatement{expression: expression}), do: "#{expression}"
  end

  defimpl Node, for: ExpressionStatement do
    def compile(%ExpressionStatement{expression: expression}, compiler) do
      with {:ok, c} <- Node.compile(expression, compiler),
           {emitted, _} <- Compiler.emit(c, :pop, []) do
        {:ok, emitted}
      end
    end

    def eval(%ExpressionStatement{expression: expression}, env), do: Node.eval(expression, env)
  end
end
