defmodule EvaluatorTest do
  use ExUnit.Case
  alias Monkex.Object.Node
  alias Monkex.Lexer
  alias Monkex.Parser

  defp eval(input) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    program |> Node.eval()
  end

  test "evaluate integers" do
    cases = [
      {"5", 5},
      {"10", 10}
    ]

    cases
    |> Enum.each(fn {input, expected} ->
      assert input |> eval == expected
    end)
  end

  test "evaluate booleans" do
    cases = [
      {"true", true},
      {"false", false}
    ]

    cases
    |> Enum.each(fn {input, expected} ->
      assert input |> eval == expected
    end)
  end
end
