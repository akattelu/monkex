defmodule ArrayListTest do
  use ExUnit.Case, async: true
  import Monkex.VM.ArrayList

  test "basic operations" do
    table = new()
    assert table |> push(1) |> at(0) == {:ok, 1}
  end

  test "from other list" do
    array = new([1, 2, 3])
    assert size(array) == 3
    assert at(array, 0) == {:ok, 1}
    assert at(array, 1) == {:ok, 2}
    assert at(array, 2) == {:ok, 3}
    assert size(array) == 3
  end
end
