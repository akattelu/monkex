defmodule Monkex.AST.InfixExpression do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.AST.Expression

  @enforce_keys [:token, :left, :operator, :right]
  defstruct [:token, :left, :operator, :right]

  defimpl Expression, for: InfixExpression do
    def token_literal(%InfixExpression{token: token}), do: token.literal
  end

  defimpl String.Chars, for: InfixExpression do
    def to_string(%InfixExpression{left: left, operator: op, right: right}),
      do: "(#{left} #{op} #{right})"
  end

  defimpl Node, for: InfixExpression do
    alias Monkex.Object.Null
    alias Monkex.Object.Integer
    alias Monkex.Object.Boolean

    @integer_operators ["+", "*", "-", "/"]
    @boolean_operators ["==", "!=", ">", "<"]

    def fn_from_operator("+"), do: &(&1 + &2)
    def fn_from_operator("*"), do: &(&1 * &2)
    def fn_from_operator("-"), do: &(&1 - &2)
    def fn_from_operator("/"), do: &(&1 / &2)
    def fn_from_operator("=="), do: &(&1 == &2)
    def fn_from_operator("!="), do: &(&1 != &2)
    def fn_from_operator(">"), do: &(&1 > &2)
    def fn_from_operator("<"), do: &(&1 < &2)

    def eval(%InfixExpression{operator: op, left: left, right: right})
        when op in @boolean_operators do
      case {Node.eval(left), Node.eval(right)} do
        {%Integer{value: left_value}, %Integer{value: right_value}} ->
          op |> fn_from_operator() |> then(fn f -> f.(left_value, right_value) end) |> Boolean.from

        {%Boolean{value: left_value}, %Boolean{value: right_value}} ->
          op |> fn_from_operator() |> then(fn f -> f.(left_value, right_value) end) |> Boolean.from

        _ ->
          Boolean.no()
      end
    end

    def eval(%InfixExpression{operator: op, left: left, right: right})
        when op in @integer_operators do
      with %Integer{value: left_value} <- Node.eval(left),
           %Integer{value: right_value} <- Node.eval(right) do
        op |> fn_from_operator() |> then(fn f -> f.(left_value, right_value) end) |> Integer.from
      else
        _ -> 
          Null.object()
      end   
     end
  end
end
