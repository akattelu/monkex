defmodule InstructionsTest do
  import Monkex.Instructions
  use ExUnit.Case, async: true

  test "replace at" do
    a = from(<<1, 2, 3, 4, 5>>)
    b = from(<<9, 9>>)
    assert replace_at(a, 1, b) == from(<<1, 9, 9, 4, 5>>)
  end

  test "trim" do
    assert trim(from(<<1, 2, 3, 4, 5>>), 2) == from(<<1, 2, 3>>)
  end

  test "length" do
    assert <<1, 2, 3, 4, 5>> |> from |> Monkex.Instructions.length() == 5
  end
end
