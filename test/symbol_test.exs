defmodule SymbolTest do
  use ExUnit.Case, async: true

  alias Monkex.Symbol
  import Monkex.SymbolTable

  test "symbol table" do
    table = new() |> with_definition("a") |> with_definition("b")

    assert table |> resolve("a") == {:ok, %Symbol{name: "a", index: 0, scope: :global}}
    assert table |> resolve("b") == {:ok, %Symbol{name: "b", index: 1, scope: :global}}
    assert table |> resolve("c") == :undefined
  end
end
