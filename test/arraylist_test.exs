defmodule ArrayListTest do
  use ExUnit.Case, async: true
  import Monkex.Container.ArrayList

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

  test "set" do
    array = new([1, 2, 3])
    assert size(array) == 3
    new_array = set(array, 500, 1000)
    assert size(new_array) == 500
    assert at(new_array, 500) == {:ok, 1000}
    assert at(new_array, 0) == {:ok, 1}
    assert new_array |> set(1, 5) |> at(1) == {:ok, 5}

    small = new([1]) |> set(0, 2)
    assert small |> at(0) == {:ok, 2}
    assert size(small) == 1
  end

  test "last" do
    assert new() |> push(1) |> push(2) |> push(3) |> last() == {:ok, 3}
    assert new() |> last() == :undefined
    assert new() |> push(1) |> push(2) |> push(3) |> set_last(5) |> last() == {:ok, 5}
    {after_pop, item} = new() |> push(1) |> push(2) |> pop
    assert item == 2
    assert last(after_pop) == {:ok, 1}
  end
end
