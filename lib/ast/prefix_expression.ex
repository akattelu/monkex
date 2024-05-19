defmodule Monkex.AST.PrefixExpression do
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node

  @enforce_keys [:token, :operator, :right]
  defstruct [:token, :operator, :right]

  defimpl Expression, for: PrefixExpression do
    def token_literal(%PrefixExpression{token: token}), do: token.literal
  end

  defimpl String.Chars, for: PrefixExpression do
    def to_string(%PrefixExpression{operator: op, right: right}), do: "(#{op}#{right})"
  end

  defimpl Node, for: PrefixExpression do
    alias Monkex.Compiler
    alias Monkex.Object
    alias Monkex.Object.Integer
    alias Monkex.Object.Boolean
    alias Monkex.Object.Null
    alias Monkex.Object.Error

    def compile(%PrefixExpression{operator: "!", right: right}, compiler) do
      {:ok, c} = Node.compile(right, compiler)
      {final, _} = Compiler.emit(c, :bang, [])
      {:ok, final}
    end

    def compile(%PrefixExpression{operator: "-", right: right}, compiler) do
      {:ok, c} = Node.compile(right, compiler)
      {final, _} = Compiler.emit(c, :minus, [])
      {:ok, final}
    end

    def eval(%PrefixExpression{operator: "!", right: right}, env) do
      {case Node.eval(right, env) |> elem(0) do
         %Error{} = err -> err
         %Integer{} -> Boolean.no()
         %Boolean{value: true} -> Boolean.no()
         %Boolean{value: false} -> Boolean.yes()
         %Null{} -> Boolean.yes()
         _ -> Boolean.no()
       end, env}
    end

    def eval(%PrefixExpression{operator: "-", right: right}, env) do
      {case Node.eval(right, env) |> elem(0) do
         %Error{} = err ->
           err

         %Integer{value: value} ->
           Integer.from(value * -1)

         _ ->
           Error.with_message(
             "unknown operator: -#{Node.eval(right, env) |> elem(0) |> Object.type()}"
           )
       end, env}
    end

    def eval(%PrefixExpression{operator: unknown, right: right}, env) do
      {Error.with_message(
         "unknown operator: #{unknown}#{Node.eval(right, env) |> elem(0) |> Object.type()}"
       ), env}
    end
  end
end
