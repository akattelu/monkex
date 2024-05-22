defmodule StackTest do
  use ExUnit.Case, async: true
  alias Monkex.VM.Stack

  test ~c"basic operations" do
    s = Stack.new()
    pushed = s |> Stack.push(1) |> Stack.push(2) |> Stack.push(3)

    {next, popped} = Stack.pop(pushed)
    assert popped == 3
    assert Stack.last_popped(next) == 3
    assert Stack.top(next) == 2
  end
end
