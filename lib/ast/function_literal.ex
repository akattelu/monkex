defmodule Monkex.AST.FunctionLiteral do
  alias Monkex.AST.Expression
  alias Monkex.Object.Node
  alias Monkex.Object.Function
  alias __MODULE__

  @enforce_keys [:token, :params, :body]
  defstruct [:token, :params, :body]

  defimpl Expression, for: FunctionLiteral do
    def token_literal(%FunctionLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: FunctionLiteral do
    def to_string(%FunctionLiteral{
          token: token,
          params: params,
          body: body
        }),
        do: "#{token.literal} (#{Enum.join(params, ", ")}) #{body}"
  end

  defimpl Node, for: FunctionLiteral do
    def compile(compiler, _node), do: compiler

    def eval(%FunctionLiteral{params: params, body: body}, env) do
      {Function.new(params, body, env), env}
    end
  end
end
