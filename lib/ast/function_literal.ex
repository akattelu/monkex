defmodule Monkex.AST.FunctionLiteral do
  @moduledoc """
  AST Node for an function literal like `fn (x, y) { x + y }`
  """
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.AST.Identifier
  alias Monkex.Object.{Node, Function, CompiledFunction}
  alias Monkex.Compiler

  @enforce_keys [:token, :params, :body, :name]
  defstruct [:token, :params, :body, :name]

  defimpl Expression, for: FunctionLiteral do
    def token_literal(%FunctionLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: FunctionLiteral do
    def to_string(%FunctionLiteral{
          token: token,
          params: params,
          body: body,
          name: name
        }),
        do: "#{token.literal} #{name}(#{Enum.join(params, ", ")}) #{body}"
  end

  defimpl Node, for: FunctionLiteral do
    def compile(%FunctionLiteral{params: params, body: body, name: name}, compiler) do
      c = Compiler.enter_scope(compiler)

      c =
        if name != "" do
          Compiler.with_function_definition(c, name)
        else
          c
        end

      c =
        Enum.reduce(params, c, fn %Identifier{symbol_name: param}, acc ->
          Compiler.with_symbol_definition(acc, param)
        end)

      {:ok, c} = Node.compile(body, c)
      c = Compiler.with_last_pop_as_return(c)

      c =
        if Compiler.last_instruction_is?(c, :return_value) do
          c
        else
          {c, _} = Compiler.emit(c, :return, [])
          c
        end

      num_locals = Compiler.num_symbols(c)
      free_symbols = Compiler.free_symbols(c)

      {c, instructions} = Compiler.leave_scope(c)
      c = Enum.reduce(free_symbols, c, fn sym, acc -> Compiler.load_symbol(acc, sym) end)
      compiled_func = CompiledFunction.from(instructions, num_locals, length(params))

      {c, pointer} = Compiler.with_constant(c, compiled_func)
      {c, _} = Compiler.emit(c, :closure, [pointer, length(free_symbols)])

      {:ok, c}
    end

    def eval(%FunctionLiteral{params: params, body: body}, env) do
      {Function.new(params, body, env), env}
    end
  end
end
