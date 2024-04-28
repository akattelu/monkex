defmodule Monkex.AST.Program do
  alias __MODULE__
  alias Monkex.AST.Statement

  @enforce_keys [:statements]
  defstruct statements: []
  @type t :: %Program{statements: [Statement]}

  def token_literal(%Program{statements: statements}) do
    case hd(statements) do
      nil -> ""
      first -> Statement.token_literal(first)
    end
  end

  @spec new([Statement.t()]) :: t
  def new(statements) do
    %Program{
      statements: statements
    }
  end
end

defimpl String.Chars, for: Monkex.AST.Program do
  def to_string(%Monkex.AST.Program{statements: statements}) do
    statements |> Enum.map(fn s -> "#{s}" end) |> Enum.join("\n")
  end
end
