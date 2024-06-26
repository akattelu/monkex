defmodule Monkex.AST.InfixExpression do
  @moduledoc """
  AST Node for an infix expression like `1 + 2` or `(1 > 2) == false`
  """
  alias __MODULE__
  alias Monkex.Object
  alias Monkex.Object.Node
  alias Monkex.Object.Error
  alias Monkex.AST.Expression
  alias Monkex.Object.Integer
  alias Monkex.Object.Boolean
  alias Monkex.Compiler
  alias Monkex.Object.String, as: StringObj

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
    @boolean_result_operators ["==", "!=", ">", "<"]

    defp opcode_from_operator("+"), do: {:ok, :add}
    defp opcode_from_operator("-"), do: {:ok, :sub}
    defp opcode_from_operator("*"), do: {:ok, :mul}
    defp opcode_from_operator("/"), do: {:ok, :div}
    defp opcode_from_operator("=="), do: {:ok, :equal}
    defp opcode_from_operator("!="), do: {:ok, :not_equal}
    defp opcode_from_operator(">"), do: {:ok, :greater_than}
    defp opcode_from_operator(op), do: {:error, "unknown operator: #{op}"}

    def compile(%InfixExpression{left: left, right: right, operator: "<"}, compiler) do
      with {:ok, right_c} <- Node.compile(right, compiler),
           {:ok, left_c} <- Node.compile(left, right_c),
           {final, _} <- Compiler.emit(left_c, :greater_than, []) do
        {:ok, final}
      else
        err -> err
      end
    end

    def compile(%InfixExpression{left: left, right: right, operator: operator}, compiler) do
      with {:ok, left_c} <- Node.compile(left, compiler),
           {:ok, right_c} <- Node.compile(right, left_c),
           {:ok, op} <- opcode_from_operator(operator),
           {final, _} <- Compiler.emit(right_c, op, []) do
        {:ok, final}
      else
        err -> err
      end
    end

    def fn_from_operator("+"), do: &(&1 + &2)
    def fn_from_operator("*"), do: &(&1 * &2)
    def fn_from_operator("-"), do: &(&1 - &2)
    def fn_from_operator("/"), do: &(&1 / &2)
    def fn_from_operator("=="), do: &(&1 == &2)
    def fn_from_operator("!="), do: &(&1 != &2)
    def fn_from_operator(">"), do: &(&1 > &2)
    def fn_from_operator("<"), do: &(&1 < &2)

    defp assert_same_type(left, right, op) do
      case {Object.type(left), Object.type(right)} do
        {x, x} -> :ok
        {t1, t2} -> {:error, "type mismatch: #{t1} #{op} #{t2}"}
      end
    end

    defp assert_error_object(left, right) do
      case {left, right} do
        {%Error{message: msg}, _} -> {:error, msg}
        {_, %Error{message: msg}} -> {:error, msg}
        _ -> :ok
      end
    end

    # plus operator should handle string concat and integer addition
    def eval(%InfixExpression{operator: "+", left: left, right: right}, env) do
      with left_val <- Node.eval(left, env) |> elem(0),
           right_val <- Node.eval(right, env) |> elem(0),
           :ok <- assert_error_object(left_val, right_val),
           :ok <- assert_same_type(left_val, right_val, "+"),
           {%Integer{value: l}, %Integer{value: r}} <- {left_val, right_val} do
        {Integer.from(l + r), env}
      else
        {:error, msg} ->
          {Error.with_message(msg), env}

        {%StringObj{value: l}, %StringObj{value: r}} ->
          {StringObj.from(l <> r), env}

        {l, r} ->
          {Error.with_message("unknown operator: #{Object.type(l)} + #{Object.type(r)}"), env}
      end
    end

    def eval(%InfixExpression{operator: op, left: left, right: right}, env) do
      with left_val <- Node.eval(left, env) |> elem(0),
           right_val <- Node.eval(right, env) |> elem(0),
           :ok <- assert_error_object(left_val, right_val),
           :ok <- assert_same_type(left_val, right_val, op),
           {%{value: l}, %{value: r}} <- {left_val, right_val} do
        op
        |> fn_from_operator()
        |> then(fn f -> f.(l, r) end)
        |> then(fn val ->
          if op in @boolean_result_operators do
            {Boolean.from(val), env}
          else
            {Integer.from(val), env}
          end
        end)
      else
        {:error, msg} ->
          {Error.with_message(msg), env}

        {l, r} ->
          {Error.with_message("unknown operator: #{Object.type(l)} + #{Object.type(r)}"), env}
      end
    end
  end
end
