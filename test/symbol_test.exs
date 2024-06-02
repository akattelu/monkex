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

  test "enclosure" do
    table = new() |> with_definition("a") |> with_definition("b")
    enclosed = table |> enclose() |> with_definition("c") |> with_definition("d")
    third = enclosed |> enclose() |> with_definition("e") |> with_definition("f")
    assert third |> resolve("a") == {:ok, %Symbol{name: "a", index: 0, scope: :global}}
    assert third |> resolve("b") == {:ok, %Symbol{name: "b", index: 1, scope: :global}}
    assert third |> resolve("c") == {:ok, %Symbol{name: "c", index: 0, scope: :local}}
    assert third |> resolve("d") == {:ok, %Symbol{name: "d", index: 1, scope: :local}}
    assert third |> resolve("e") == {:ok, %Symbol{name: "e", index: 0, scope: :local}}
    assert third |> resolve("f") == {:ok, %Symbol{name: "f", index: 1, scope: :local}}
    assert third |> resolve("g") == :undefined
  end
end
