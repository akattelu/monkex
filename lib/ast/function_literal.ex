defmodule Monkex.AST.FunctionLiteral do
  @moduledoc """
  AST Node for an function literal like `fn (x, y) { x + y }`
  """
  alias Monkex.AST.Expression
  alias Monkex.Object.{Node, Function, CompiledFunction}
  alias Monkex.Compiler
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
    def compile(%FunctionLiteral{params: _params, body: body}, compiler) do
      c = Compiler.enter_scope(compiler)
      {:ok, c} = Node.compile(body, c)
      c = Compiler.with_last_pop_as_return(c)

      c =
        if Compiler.last_instruction_is?(c, :return_value) do
          c
        else
          {c, _} = Compiler.emit(c, :return, [])
          c
        end

      {c, instructions} = Compiler.leave_scope(c)
      compiled_func = CompiledFunction.from(instructions)

      {c, pointer} = Compiler.with_constant(c, compiled_func)
      {c, _} = Compiler.emit(c, :constant, [pointer])

      {:ok, c}
    end

    def eval(%FunctionLiteral{params: params, body: body}, env) do
      {Function.new(params, body, env), env}
    end
  end
end
