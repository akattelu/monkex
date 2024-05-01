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

  defp test_integer({obj, expected}), do: assert obj.value == expected
  defp test_boolean({obj, expected}), do: assert obj.value == expected

  test "evaluate integers" do
    [ {"5", 5}, {"10", 10} ] |> Enum.map(fn {input, output} -> {input |> eval, output} end) |> Enum.map(&test_integer/1)
  end

  test "evaluate booleans" do
    [ {"true", true}, {"false", false} ] |> Enum.map(fn {input, output} -> {input |> eval, output} end) |> Enum.map(&test_boolean/1)
  end
end
