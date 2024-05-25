defmodule InstructionSetTest do
  use ExUnit.Case, async: true

  import Monkex.Instructions
  import Monkex.VM.InstructionSet

  test "at" do
    assert from(<<99>>) |> new |> read() == <<99::8>>
    assert from(<<99, 100, 101>>) |> new |> read(3) == <<99::8, 100::8, 101::8>>
    assert from(<<99, 100, 101>>) |> new |> read(3) == <<99::8, 100::8, 101::8>>
  end

  test "jump" do
    assert from(<<99, 100, 101>>) |> new |> jump(2) |> read() == <<101::8>>
  end

  test "out of bounds" do
    assert from(<<99, 100, 101>>) |> new |> jump(3) |> read() == <<>>
  end
end
