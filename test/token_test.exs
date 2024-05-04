defmodule TokenTest do
  use ExUnit.Case
  alias Monkex.Token

  test "is digit" do
    assert Token.is_digit("1") == true
    assert Token.is_digit("0") == true
    assert Token.is_digit("9") == true
    assert Token.is_digit("a") == false
  end

  test "is letter" do
    assert Token.is_letter("a") == true
    assert Token.is_letter("z") == true
    assert Token.is_letter("A") == true
    assert Token.is_letter("Z") == true
    assert Token.is_letter("_") == true
    assert Token.is_letter("0") == false
    assert Token.is_letter("9") == false
    assert Token.is_letter(" ") == false
    assert Token.is_letter("!") == false
  end
end
