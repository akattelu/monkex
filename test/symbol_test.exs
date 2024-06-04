defmodule SymbolTest do
  use ExUnit.Case, async: true

  alias Monkex.Symbol
  import Monkex.SymbolTable

  test "symbol table" do
    table = new() |> with_definition("a") |> with_definition("b")

    assert table |> resolve("a") |> elem(2) == %Symbol{name: "a", index: 0, scope: :global}
    assert table |> resolve("b") |> elem(2) == %Symbol{name: "b", index: 1, scope: :global}
    assert table |> resolve("c") == :undefined
  end

  test "enclose" do
    table = new() |> with_definition("a") |> with_definition("b")
    enclosed = table |> enclose() |> with_definition("c") |> with_definition("d")
    third = enclosed |> enclose() |> with_definition("e") |> with_definition("f")
    assert table |> resolve("a") |> elem(2) == %Symbol{name: "a", index: 0, scope: :global}
    assert table |> resolve("b") |> elem(2) == %Symbol{name: "b", index: 1, scope: :global}
    assert enclosed |> resolve("c") |> elem(2) == %Symbol{name: "c", index: 0, scope: :local}
    assert enclosed |> resolve("d") |> elem(2) == %Symbol{name: "d", index: 1, scope: :local}
    assert third |> resolve("e") |> elem(2) == %Symbol{name: "e", index: 0, scope: :local}
    assert third |> resolve("f") |> elem(2) == %Symbol{name: "f", index: 1, scope: :local}
    assert third |> resolve("g") == :undefined
  end

  test "closure" do
    table = new() |> with_definition("a") |> with_definition("b")
    enclosed = table |> enclose() |> with_definition("c") |> with_definition("d")
    third = enclosed |> enclose() |> with_definition("e") |> with_definition("f")
    assert third |> resolve("a") |> elem(2) == %Symbol{name: "a", index: 0, scope: :global}
    assert third |> resolve("b") |> elem(2) == %Symbol{name: "b", index: 1, scope: :global}

    {:ok, t, sym} = third |> resolve("c")
    assert sym == %Symbol{name: "c", index: 0, scope: :free}
    {:ok, t, sym} = t |> resolve("d")
    assert sym == %Symbol{name: "d", index: 1, scope: :free}

    {:ok, t, sym} = t |> resolve("e")
    assert sym == %Symbol{name: "e", index: 0, scope: :local}
    {:ok, t, sym} = t |> resolve("f")
    assert sym == %Symbol{name: "f", index: 1, scope: :local}

    assert t |> get_free_symbols() == [
             %Symbol{name: "c", index: 0, scope: :local},
             %Symbol{name: "d", index: 1, scope: :local}
           ]

    assert third |> resolve("g") == :undefined
  end
end
