defmodule Monkex.AST.ReturnStatement do
  @moduledoc """
  AST Node for a return statement like `return 2;`
  """
  alias __MODULE__
  alias Monkex.AST.Statement
  alias Monkex.Object.Node
  alias Monkex.Object.Error
  alias Monkex.Compiler

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

    def compile(%ReturnStatement{return_value: expr}, compiler) do
      {:ok, c} = Node.compile(expr, compiler)
      {c, _} = Compiler.emit(c, :return_value, [])
      {:ok, c}
    end

    def eval(%ReturnStatement{return_value: expr}, env) do
      {case Node.eval(expr, env) |> elem(0) do
         %Error{} = err -> err
         val -> ReturnValue.from(val)
       end, env}
    end
  end
end
