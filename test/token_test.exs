defmodule TokenTest do
  use ExUnit.Case, async: true
  alias Monkex.Token

  test "is digit" do
    assert Token.digit?("1") == true
    assert Token.digit?("0") == true
    assert Token.digit?("9") == true
    assert Token.digit?("a") == false
  end

  test "is letter" do
    assert Token.letter?("a") == true
    assert Token.letter?("z") == true
    assert Token.letter?("A") == true
    assert Token.letter?("Z") == true
    assert Token.letter?("_") == true
    assert Token.letter?("0") == false
    assert Token.letter?("9") == false
    assert Token.letter?(" ") == false
    assert Token.letter?("!") == false
  end
end
