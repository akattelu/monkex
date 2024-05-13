defmodule Monkex.AST.Program do
  alias __MODULE__
  alias Monkex.AST.Statement
  alias Monkex.Object.Node
  alias Monkex.Object.Error
  alias Monkex.Object.ReturnValue
  alias Monkex.Object.Null

  @enforce_keys [:statements]
  defstruct statements: []
  @type t :: %Program{statements: [Statement]}

  def token_literal(%Program{statements: statements}) do
    case hd(statements) do
      nil -> ""
      first -> Statement.token_literal(first)
    end
  end

  defimpl String.Chars, for: Monkex.AST.Program do
    def to_string(%Monkex.AST.Program{statements: statements}),
      do: statements |> Enum.map(fn s -> "#{s}" end) |> Enum.join("")
  end

  defimpl Node, for: Program do
    def compile(%Program{statements: []}, compiler), do: {:ok, compiler}

    def compile(%Program{statements: [s | rest]}, compiler) do
      case Node.compile(s, compiler) do
        {:ok, c} -> compile(%Program{statements: rest}, c)
        error -> error
      end
    end

    def eval(%Program{statements: []}, env), do: {Null.object(), env}

    def eval(%Program{statements: [s | []]}, env) do
      case Node.eval(s, env) do
        {%ReturnValue{value: val}, e} -> {val, e}
        result -> result
      end
    end

    def eval(%Program{statements: statements}, env) do
      statements
      |> Enum.reduce_while({Null.object(), env}, fn s, {_, e} ->
        case Node.eval(s, e) do
          {%Error{}, _} = acc -> {:halt, acc}
          {%ReturnValue{value: val}, e_next} -> {:halt, {val, e_next}}
          val -> {:cont, val}
        end
      end)
    end
  end
end
