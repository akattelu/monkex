defmodule Monkex.AST.LetStatement do
  @moduledoc """
  AST Node for a let statement like `let x = 2;`
  """
  alias __MODULE__
  alias Monkex.AST.Statement
  alias Monkex.Object.{ Node, Error, Null}

  alias Monkex.AST.Identifier
  alias Monkex.Environment
  alias Monkex.Compiler
  alias Monkex.Symbol

  @enforce_keys [:token, :name, :value]
  defstruct [:token, :name, :value]

  defimpl Statement, for: LetStatement do
    def token_literal(%LetStatement{token: token}), do: token.literal
  end

  defimpl String.Chars, for: LetStatement do
    def to_string(%LetStatement{name: name, value: value}), do: "let #{name} = #{value};"
  end

  defimpl Node, for: LetStatement do
    def compile(%LetStatement{name: %Identifier{symbol_name: name}, value: value}, compiler) do
      with with_symbol <- Compiler.with_symbol_definition(compiler, name),
           {:ok, value_c} <- Node.compile(value, with_symbol),
           {:ok, c, %Symbol{index: idx, scope: scope}} <- Compiler.get_symbol(value_c, name) do
        {c, _} =
          Compiler.emit(
            c,
            case scope do
              :global ->
                :set_global

              :local ->
                :set_local

              :builtin ->
                :get_builtin
                # :free -> :get_free
            end,
            [idx]
          )

        {:ok, c}
      end
    end

    def eval(%LetStatement{name: %Identifier{symbol_name: name}, value: value}, env) do
      case Node.eval(value, env) do
        {%Error{}, _} = result -> result
        {obj, e} -> {Null.object(), e |> Environment.set(name, obj)}
      end
    end

    def eval(%LetStatement{name: not_ident}, env) do
      {Error.with_message("expected identifier on left side of let statement, got: #{not_ident}"),
       env}
    end
  end
end
