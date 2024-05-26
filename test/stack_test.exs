defmodule StackTest do
  use ExUnit.Case, async: true
  import Monkex.VM.Stack

  test ~c"basic operations" do
    s = new()
    pushed = s |> push(1) |> push(2) |> push(3)

    {next, popped} = pop(pushed)
    assert popped == 3
    assert last_popped(next) == 3
    assert top(next) == 2
  end

  test "take" do
    s = new() |> push(1) |> push(2) |> push(3) |> push(4)
    {s, arr} = take(s, 3)
    assert arr == [2, 3, 4]
    assert pop(s) |> elem(1) == 1
  end
end
