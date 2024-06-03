defmodule VMTest do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Compiler
  alias Monkex.Object.{Null, Array, Dictionary}
  alias Monkex.VM
  use ExUnit.Case, async: true

  def test_literal({actual, nil}) do
    assert actual == Null.object()
  end

  def test_literal({%Dictionary{map: map}, expected}) do
    map
    |> Map.keys()
    |> Enum.each(fn k ->
      # will not work on arrays or nulls inside dicts
      test_literal({map[k], expected[k.value]})
    end)
  end

  def test_literal({%Array{items: [ah | at]}, [eh | et]}) do
    test_literal({ah, eh})
    test_literal({%Array{items: at}, et})
  end

  def test_literal({%Array{items: []}, []}) do
    assert [] == []
  end

  def test_literal({actual, expected}) do
    assert actual.value == expected
  end

  def vm_test({input, {:error, msg}}) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    {:ok, compiler} = Compiler.new() |> Compiler.compile(program)

    {:error, actual_msg} = compiler |> Compiler.bytecode() |> VM.new() |> VM.run()
    assert actual_msg == msg
  end

  def vm_test({input, expected}) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    {:ok, compiler} = Compiler.new() |> Compiler.compile(program)

    {:ok, final} = compiler |> Compiler.bytecode() |> VM.new() |> VM.run()
    test_literal({VM.stack_last_top(final), expected})
  end

  test "integer arithmetic" do
    [
      {"1", 1},
      {"2", 2},
      {"1 + 2", 3},
      {"1 - 2", -1},
      {"1 * 2", 2},
      {"4 / 2", 2},
      {"50 / 2 * 2 + 10 - 5", 55},
      {"5 + 5 + 5 + 5 - 10", 10},
      {"2 * 2 * 2 * 2 * 2", 32},
      {"5 * 2 + 10", 20},
      {"5 + 2 * 10", 25},
      {"5 * (2 + 10)", 60},
      {"-5", -5},
      {"-10", -10},
      {"-50 + 100 + -50", 0},
      {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "boolean literals" do
    [
      {"true", true},
      {"false", false}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "comparsion operators" do
    [
      {"1 < 2", true},
      {"1 > 2", false},
      {"1 < 1", false},
      {"1 > 1", false},
      {"1 == 1", true},
      {"1 != 1", false},
      {"1 == 2", false},
      {"1 != 2", true},
      {"true == true", true},
      {"false == false", true},
      {"true == false", false},
      {"true != false", true},
      {"false != true", true},
      {"(1 < 2) == true", true},
      {"(1 < 2) == false", false},
      {"(1 > 2) == true", false},
      {"(1 > 2) == false", true}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "boolean operators" do
    [
      {"!true", false},
      {"!false", true},
      {"!5", false},
      {"!!true", true},
      {"!!false", false},
      {"!!5", true},
      {"!(if (false) { 5; })", true}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "if expressions" do
    [
      {"if (true) { 10 }", 10},
      {"if (true) { 10 } else { 20 }", 10},
      {"if (false) { 10 } else { 20 } ", 20},
      {"if (1) { 10 }", 10},
      {"if (1 < 2) { 10 }", 10},
      {"if (1 < 2) { 10 } else { 20 }", 10},
      {"if (1 > 2) { 10 } else { 20 }", 20},
      {"if (1 > 2) { 10 }", nil},
      {"if (false) { 10 }", nil},
      {"if ((if (false) { 10 })) { 10 } else { 20 }", 20}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "let statements and global identifiers" do
    [
      {"let one = 1; one", 1},
      {"let one = 1; let two = 2; one + two", 3},
      {"let one = 1; let two = one + one; one + two", 3}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "string literals and concatenation" do
    [
      {~S("monkey"), "monkey"},
      {~S("mon"+"key"), "monkey"},
      {~S("mon" + "key" + "banana"), "monkeybanana"}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "array literals" do
    [
      {"[]", []},
      {"[1, 2, 3]", [1, 2, 3]},
      {"[1 + 2, 3 * 4, 5 + 6]", [3, 12, 11]}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "dict literals" do
    [
      {"{}", %{}},
      {"{1: 2, 3: 4}", %{1 => 2, 3 => 4}},
      {"{1 + 1: 2 * 2, 3 + 3: 4 * 4}", %{2 => 4, 6 => 16}}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "index expressions" do
    [
      {"[1, 2, 3][1]", 2},
      {"[1, 2, 3][0 + 2]", 3},
      {"[[1, 1, 1]][0][0]", 1},
      {"[][0]", nil},
      {"[1, 2, 3][99]", nil},
      {"[1][-1]", nil},
      {"{1: 1, 2: 2}[1]", 1},
      {"{1: 1, 2: 2}[2]", 2},
      {"{1: 1}[0]", nil},
      {"{}[0]", nil}
    ]
    |> Enum.map(&vm_test/1)
  end

  test "functions without arguments" do
    [
      {"let fivePlusTen = fn() { 5 + 10; }; fivePlusTen();", 15},
      {
        """
          
        let one = fn() { 1; };
        let two = fn() { 2; };
        one() + two()
        """,
        3
      },
      {
        """
        let a = fn() { 1 };
        let b = fn() { a() + 1 };
        let c = fn() { b() + 1 };
        c();
          
        """,
        3
      },
      {
        """
          let earlyExit = fn() { return 99; 100; };
          earlyExit();
          
        """,
        99
      },
      {
        """
          let earlyExit = fn() { return 99; return 100; };
          earlyExit();
          
        """,
        99
      },
      {
        """
        let noReturn = fn() { };
        noReturn();
          
        """,
        nil
      },
      {
        """
        let noReturn = fn() { };
        let noReturnTwo = fn() { noReturn(); };
        noReturn();
        noReturnTwo();
          
        """,
        nil
      },
      {
        """
        let returnsOne = fn() { 1; };
        let returnsOneReturner = fn() { returnsOne; };
        returnsOneReturner()();
        """,
        1
      }
    ]
    |> Enum.map(&vm_test/1)
  end

  test "functions with local and global bindings" do
    [
      {
        """
        let one = fn() { let one = 1; one };
        one();
        """,
        1
      },
      {
        """
        let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
        oneAndTwo();
        """,
        3
      },
      {
        """
        let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
        let threeAndFour = fn() { let three = 3; let four = 4; three + four; };
        oneAndTwo() + threeAndFour();
        """,
        10
      },
      {
        """
        let firstFoobar = fn() { let foobar = 50; foobar; };
        let secondFoobar = fn() { let foobar = 100; foobar; };
        firstFoobar() + secondFoobar();
        """,
        150
      },
      {
        """
        let globalSeed = 50;
        let minusOne = fn() {
            let num = 1;
            globalSeed - num;
        }
        let minusTwo = fn() {
            let num = 2;
            globalSeed - num;
        }
        minusOne() + minusTwo();
        """,
        97
      },
      {
        """
        let identity = fn(a) { a; };
        identity(4);
        """,
        4
      },
      {
        """
        let sum = fn(a, b) { a + b; }
        sum(1, 2)
        """,
        3
      },
      {
        """
        let sum = fn(a, b) {
            let c = a + b;
            c;
        };
        sum(1, 2);
        """,
        3
      },
      {
        """
        let sum = fn(a, b) {
            let c = a + b;
            c;
        };
        sum(1, 2) + sum(3, 4);
        """,
        10
      },
      {
        """
        let sum = fn(a, b) {
            let c = a + b;
            c;
        };
        let outer = fn() {
            sum(1, 2) + sum(3, 4);
        };
        outer();
        """,
        10
      },
      {
        """
        let globalNum = 10;
        let sum = fn(a, b) {
            let c = a + b;
            c + globalNum;
        };
        let outer = fn() {
            sum(1, 2) + sum(3, 4) + globalNum;
        };
        outer() + globalNum;
        """,
        50
      }
    ]
    |> Enum.map(&vm_test/1)
  end

  test "calling functions with wrong arguments" do
    [
      {
        """
        fn(){ 1;}(1)
        """,
        {:error, "wrong number of arguments, expected: 0, got: 1"}
      },
      {
        """
        fn(a){ 1;}()
        """,
        {:error, "wrong number of arguments, expected: 1, got: 0"}
      },
      {
        """
        fn(a, b){ a + b;}(1)
        """,
        {:error, "wrong number of arguments, expected: 2, got: 1"}
      }
    ]
    |> Enum.map(&vm_test/1)
  end

  test "calling builtin functions" do
    [
      {~S(len(""\)), 0},
      {~S(len("four"\)), 4},
      {~S(len("hello world"\)), 11},
      {~S(len(1\)), {:error, "argument to `len` not supported, got integer"}},
      {~S(len("one", "two"\)), {:error, "wrong number of arguments, expected: 1, got: 2"}},
      {~S(len([1, 2, 3]\)), 3},
      {~S(len([]\)), 0},
      {~S(head([1, 2, 3]\)), 1},
      {~S(head([]\)), nil},
      {~S(head(1\)), {:error, "argument to `head` must be array, got integer"}},
      {~S(last([1, 2, 3]\)), 3},
      {~S(last([]\)), nil},
      {~S(last(1\)), {:error, "argument to `last` must be array, got integer"}},
      {~S(tail([1, 2, 3]\)), [2, 3]},
      {~S(tail([]\)), nil},
      {~S(tail([]\)), nil},
      {~S(push([], 1\)), [1]},
      {~S(push(1, 1\)), {:error, "argument to `push` must be array, got integer"}}
    ]
    |> Enum.map(&vm_test/1)
  end
end
