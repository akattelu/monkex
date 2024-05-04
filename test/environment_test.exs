defmodule EnvironmentTest do
  use ExUnit.Case
  alias Monkex.Environment 
  alias Monkex.Object.Integer

  test "env get" do
    e = Environment.from_store(%{"a" => Integer.from(1)})
    assert Environment.get(e, "a") == {:ok, Integer.from(1)}
  end

  test "env set" do
    e = Environment.from_store(%{"a" => Integer.from(1)})
    assert e |> Environment.set("b", Integer.from(2)) |> Environment.get("b") == {:ok, Integer.from(2)}
  end
end
