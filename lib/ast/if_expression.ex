defmodule Monkex.AST.IfExpression do
  @moduledoc """
  AST Node for an if expression like `if (1 > 2) { 1 } else { 2 }`
  """
  alias __MODULE__
  alias Monkex.AST.Expression
  alias Monkex.Object.Node

  @enforce_keys [:token, :condition, :then_block, :else_block]
  defstruct [:token, :condition, :then_block, :else_block]

  defimpl Expression, for: IfExpression do
    def token_literal(%IfExpression{token: token}), do: token.literal
  end

  defimpl String.Chars, for: IfExpression do
    def to_string(%IfExpression{
          token: token,
          condition: condition,
          then_block: then_block,
          else_block: else_block
        }),
        do: "#{token.literal} (#{condition}) #{then_block} else #{else_block}"
  end

  defimpl Node, for: IfExpression do
    alias Monkex.Object.Null
    alias Monkex.Object.Boolean
    alias Monkex.Object.Integer
    alias Monkex.Object.Error
    alias Monkex.Compiler
    alias Monkex.Opcode

    def compile(
          %IfExpression{condition: condition, then_block: then_block, else_block: else_block},
          compiler
        ) do
      {:ok, comp_c} = Node.compile(condition, compiler)
      {jump_not_truthy_c, jump_not_truthy_pos} = Compiler.emit(comp_c, :jump_not_truthy, [9999])

      {:ok, then_c} = Node.compile(then_block, jump_not_truthy_c)

      then_c =
        Compiler.without_last_instruction(then_c, :pop)

      {jump_after_else_c, jump_pos} = Compiler.emit(then_c, :jump, [9999])

      # point the first jump_not_truthy to after the jump
      pre_else_c =
        Compiler.with_replaced_instruction(
          jump_after_else_c,
          jump_not_truthy_pos,
          Opcode.make(:jump_not_truthy, [Compiler.instructions_length(jump_after_else_c)])
        )

      # if there is no else block, use a null expr as the else block
      else_c =
        if else_block != nil do
          {:ok, else_c} = Node.compile(else_block, pre_else_c)
          Compiler.without_last_instruction(else_c, :pop)
        else
          {else_c, _} = Compiler.emit(pre_else_c, :null, [])
          else_c
        end

      # point the unconditional jump block to after the else block
      else_c =
        Compiler.with_replaced_instruction(
          else_c,
          jump_pos,
          Opcode.make(:jump, [Compiler.instructions_length(else_c)])
        )

      {:ok, else_c}
    end

    def eval(%Error{} = err, env), do: {err, env}

    def eval(
          %IfExpression{condition: condition, then_block: then_block, else_block: else_block},
          env
        ) do
      case {Node.eval(condition, env) |> elem(0), else_block} do
        {%Error{} = err, _} ->
          {err, env}

        # true then always do the then
        {%Boolean{value: true}, _} ->
          Node.eval(then_block, env)

        {%Integer{value: value}, nil} ->
          if value > 0 do
            Node.eval(then_block, env)
          else
            {Null.object(), env}
          end

        {%Integer{value: value}, else_block} ->
          if value > 0 do
            Node.eval(then_block, env)
          else
            Node.eval(else_block, env)
          end

        # falsy and no else block
        {_, nil} ->
          {Null.object(), env}

        # falsy but there is an else block
        {%Boolean{value: false}, else_expr} ->
          Node.eval(else_expr, env)
      end
    end

    def eval(_, env), do: {Null.object(), env}
  end
end
