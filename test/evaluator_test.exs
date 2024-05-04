defmodule EvaluatorTest do
  use ExUnit.Case
  alias Monkex.Object
  alias Monkex.Object.Node
  alias Monkex.Object.Null
  alias Monkex.Lexer
  alias Monkex.Parser

  defp eval(input) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    env = nil

    # ignore env
    program |> Node.eval(env) |> elem(0)
  end

  def eval_input({input, output}), do: {input |> eval, output}

  defp test_literal({obj, nil}), do: assert(obj == Null.object())
  defp test_literal({obj, expected}), do: assert(obj.value == expected)

  defp expect_error({obj, expected}) do
    assert Object.type(obj) == :error
    assert obj.message == expected
  end

  test "evaluate integers" do
    [{"5", 5}, {"10", 10}]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "evaluate booleans" do
    [{"true", true}, {"false", false}]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "bang operator" do
    [
      {"!true", false},
      {"!false", true},
      {"!!true", true},
      {"!!false", false},
      {"!5", false}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "minus operator" do
    [
      {"-5", -5},
      {"-10", -10},
      {"5", 5},
      {"10", 10}
    ]
    |> Enum.map(&eval_input/1)  
    |> Enum.map(&test_literal/1)
  end

  test "infix expressions with integers" do
    [
      {"5", 5},
      {"10", 10},
      {"-5", -5},
      {"-10", -10},
      {"5 + 5 + 5 + 5 - 10", 10},
      {"2 * 2 * 2 * 2 * 2", 32},
      {"-50 + 100 + -50", 0},
      {"5 * 2 + 10", 20},
      {"5 + 2 * 10", 25},
      {"20 + 2 * -10", 0},
      {"50 / 2 * 2 + 10", 60},
      {"2 * (5 + 10)", 30},
      {"3 * 3 * 3 + 10", 37},
      {"3 * (3 * 3) + 10", 37},
      {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "infix expressions with booleans" do
    [
      {"true == true", true},
      {"false == false", true},
      {"true == false", false},
      {"true != false", true},
      {"false != true", true},
      {"(1 < 2) == true", true},
      {"(1 < 2) == false", false},
      {"(1 > 2) == true", false},
      {"(1 > 2) == false", true},
      {"1 == true", false},
      {"1 > true", false},
      {"1 < true", false},
      {"1 != true", false}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "if expressions" do
    [
      {"if (true) { 10 }", 10},
      {"if (false) { 10 }", nil},
      {"if (1) { 10 }", 10},
      {"if (1 < 2) { 10 }", 10},
      {"if (1 > 2) { 10 }", nil},
      {"if (1 > 2) { 10 } else { 20 }", 20},
      {"if (1 < 2) { 10 } else { 20 }", 10}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.each(&test_literal/1)
  end

  test "return statements" do
    [
      {"return 10;", 10},
      {"9; return 10; 9", 10},
      {"""

       if (10 > 1) {
       if (10 > 1) {
       return 10;
       }

       return 1;
       }
         
       """, 10},
      {"""

       if (10 > 1) {
       return 10;
       }
       return 1;
         
       """, 10}
    ]
    |> Enum.map(&eval_input/1) 
    |> Enum.each(&test_literal/1)
  end

  test "error messages" do
    [
      {
        "5 + true;",
        "type mismatch: integer + boolean"
      },
      {
        "5 + true; 5;",
        "type mismatch: integer + boolean"
      },
      {
        "-true",
        "unknown operator: -boolean"
      },
      {
        "true + false;",
        "unknown operator: boolean + boolean"
      },
      {
        "5; true + false; 5",
        "unknown operator: boolean + boolean"
      },
      {
        "if (10 > 1) { true + false; }",
        "unknown operator: boolean + boolean"
      },
      {
        """
        if (10 > 1) {
          if (10 > 1) {
            return true + false;
          }

          return 1;
        }
        """,
        "unknown operator: boolean + boolean"
      }
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&expect_error/1)
  end

  # test "let statements" do
  #   [
  #     {"let a = 5; a;", 5},
  #     {"let a = 5 * 5; a;", 25},
  #     {"let a = 5; let b = a; b;", 5},
  #     {"let a = 5; let b = a; let c = a + b + 5; c;", 15}
  #   ]
  #   |> Enum.map(&eval_input/1)
  #   |> Enum.map(&test_literal/1)
  # end
end
