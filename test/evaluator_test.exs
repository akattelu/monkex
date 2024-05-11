defmodule EvaluatorTest do
  use ExUnit.Case
  alias Monkex.Object.Dictionary
  alias Monkex.Object
  alias Monkex.Object.Node
  alias Monkex.Object.Null
  alias Monkex.Object.Array
  alias Monkex.Lexer
  alias Monkex.Environment
  alias Monkex.Parser

  defp eval(input) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    env = Environment.new() |> Environment.with_builtins()
    {obj, _env} = program |> Node.eval(env)
    obj
  end

  def eval_input({input, output}), do: {input |> eval, output}

  defp test_literal_array({obj, []}), do: assert(obj.items == [])

  defp test_literal_array({%Array{items: [first | rest]}, [h | t]}) do
    test_literal({first, h})
    test_literal_array({%Array{items: rest}, t})
  end

  defp test_literal_dict({%Dictionary{map: map}, expected}) do

    map |> Map.to_list() |> Enum.each(fn {act_k, act_v} -> 
      assert %Object.String{} = act_k
      k = act_k.value 
      assert Map.has_key?(expected, k)

      case {act_v, Map.get(expected, k)} do
        {%Object.Array{} = arr, e} -> test_literal_array({arr, e})
        {%Object.Dictionary{} = d, e} -> test_literal_dict({d, e})
        {a, e} -> test_literal({a, e})
      end
     
    end)
  end

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

  test "infix expressions" do
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
      {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50},
      {"true == true", true},
      {"false == false", true},
      {"true == false", false},
      {"true != false", true},
      {"false != true", true},
      {"(1 < 2) == true", true},
      {"(1 < 2) == false", false},
      {"(1 > 2) == true", false},
      {"(1 > 2) == false", true},
      {~s("hello" + " " + "world"), "hello world"}
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
        "5 > true;",
        "type mismatch: integer > boolean"
      },
      {
        "5 < true;",
        "type mismatch: integer < boolean"
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
        ~s("hello" + true;),
        "type mismatch: string + boolean"
      },
      {
        ~s("hello" + 9;),
        "type mismatch: string + integer"
      },
      {"1 == true", "type mismatch: integer == boolean"},
      {"1 != true", "type mismatch: integer != boolean"},
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

  test "let statements" do
    [
      {"let a = 5; a;", 5},
      {"let a = 5 * 5; a;", 25},
      {"let a = 5; let b = a; b;", 5},
      {"let a = 5; let b = a; let c = a + b + 5; c;", 15}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "function definition" do
    input = "fn(x) { x + 2 }"
    result = eval(input)
    assert result.params |> length() == 1
    assert "#{result.params |> hd}" == "x"
    assert "#{result.body}" == "{ (x + 2) }"
  end

  test "function calls" do
    [
      {"let identity = fn(x) { x; }; identity(5);", 5},
      {"let identity = fn(x) { return x; }; identity(5);", 5},
      {"let double = fn(x) { x * 2; }; double(5);", 10},
      {"let add = fn(x, y) { x + y; }; add(5, 5);", 10},
      {"let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20},
      {"fn(x) { x; }(5)", 5}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "builtin functions" do
    [
      {"len([1, 2, 3])", 3},
      {"len([1])", 1},
      {~s(charAt("hello", 0\)), "h"},
      {~s(charAt("hello", 3\)), "l"}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "closure calls" do
    [
      {"let adder = fn(x) { fn(y) { x + y; } }; let newAdder = adder(5); newAdder(3);", 8},
      {"let threeFn = fn() { return fn() { return 3; } }; let three = threeFn(); three();", 3}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "function errors" do
    [
      {"let f = fn(x) { 1 + x }; f();", "expected 1 args in function call but was given 0"},
      {"let f = fn(x) { 1 + x }; f(1 + true);", "type mismatch: integer + boolean"},
      {"charAt(1)", "incorrect number of arguments passed to builtin function"},
      {"let adder = fn(x) { fn(y) { x + y; } }; let newAdder = adder(5); newAdder(3); x;",
       "identifier not found: x"}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&expect_error/1)
  end

  test "string literals" do
    [
      {~s("foobar"), "foobar"},
      {~s("foo bar"), "foo bar"}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "array literals" do
    [
      {"[]", []},
      {"[2]", [2]},
      {~s(["hello", 2, true]), ["hello", 2, true]}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal_array/1)
  end

  test "array access" do
    [
      {~s(["hello", 2, true][0]), "hello"},
      {~s(["hello", 2, true][1]), 2},
      {~s(["hello", 2, true][2]), true},
      {"let arr = [1,2, 3]; arr[2];", 3}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "array access errors" do
    [
      {"[][0]", "index out of bounds"},
      {"2[0]", "tried to access non-indexable object: integer"},
      {"[0][true]", "tried to access array with invalid index type: boolean"}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&expect_error/1)
  end

  test "dictionary literals" do
    [
      {"{}", %{}},
      {~s({"a": 1}), %{"a" => 1}},
      {~s(let var = "hello"; {"a": 1, "b" : true, var : "world"}),
       %{"a" => 1, "b" => true, "hello" => "world"}}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal_dict/1)
  end
  test "dictionary access" do
    [
      {~s({"a": 1}["a"]), 1},
      {~s({"a": 1}["b"]), nil},
      {~s(let var = "hello"; let d = {"a": 1, "b" : true, var : "world"}; d[var]),
       "world"}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&test_literal/1)
  end

  test "dictionary access errors" do
    [
      {~s({"a": 1}[true]), "tried to access dict with invalid index type: boolean"},
      {~s(2["b"]), "tried to access non-indexable object: integer"},
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&expect_error/1)
  end

  test "dictionary literal errors" do
    [
      {~s(let var = true; {"a": 1, "b" : true, var : "world"}), "expected string as key, got boolean"}
    ]
    |> Enum.map(&eval_input/1)
    |> Enum.map(&expect_error/1)
  end
end
