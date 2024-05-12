defmodule EnvironmentTest do
  use ExUnit.Case, async: true
  alias Monkex.Object.Integer
  import Monkex.Environment

  test "env get" do
    e = from_store(%{"a" => Integer.from(1)})
    assert get(e, "a") == {:ok, Integer.from(1)}
    assert get(e, "b") == :undefined
  end

  test "env set" do
    e = from_store(%{"a" => Integer.from(1)})

    assert e |> set("b", Integer.from(2)) |> get("b") == {:ok, Integer.from(2)}
  end

  test "env merge" do
    a = new() |> set("a", 1) |> set("c", 3)
    b = new() |> set("b", 2) |> set("c", 4)
    c = merge(a, b)
    assert get(c, "a") == {:ok, 1}
    assert get(c, "b") == {:ok, 2}
    assert get(c, "c") == {:ok, 4}
  end
end
