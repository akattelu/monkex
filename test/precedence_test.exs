defmodule PrecedenceTest do
  use ExUnit.Case, async: true
  alias Monkex.Parser.Precedence

  test "precedence compare" do
    assert Precedence.compare(:lowest, :equals) == -1
    assert Precedence.compare(:lowest, :lessgreater) == -2
    assert Precedence.compare(:equals, :equals) == 0
    assert Precedence.compare(:product, :sum) == 1
  end
end
