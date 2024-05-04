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
    def eval(%Program{statements: []}), do: %Monkex.Object.Null{}

    def eval(%Program{statements: [s | []]}) do
      case Node.eval(s) do
        %Error{} = err -> err
        %ReturnValue{value: val} -> val
        val -> val
      end
    end

    def eval(%Program{statements: statements}) do
      statements
      |> Enum.reduce_while(Null.object(), fn s, _ ->
        case Node.eval(s) do
          %Error{} = err -> {:halt, err}
          %ReturnValue{value: val} -> {:halt, val}
          val -> {:cont, val}
        end
      end)
    end
  end
end
