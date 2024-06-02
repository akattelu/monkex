defmodule CompilerTest do
  alias Monkex.Parser
  alias Monkex.Compiler
  alias Monkex.Lexer
  alias Monkex.Opcode
  alias Monkex.Instructions
  alias Monkex.Object.CompiledFunction
  alias Monkex.Container.ArrayList

  use ExUnit.Case, async: true

  def assert_instructions(actual, expected_list) do
    concatted = Instructions.merge(expected_list)
    assert concatted == actual, "expected:\n#{concatted}\nactual:\n\n#{actual}"
  end

  def assert_constants([], []), do: nil

  def assert_constants(
        [%CompiledFunction{instructions: %Instructions{raw: actual_raw}} | objects],
        [%Instructions{raw: expect_raw} | rest]
      ) do
    assert actual_raw == expect_raw
    assert_constants(objects, rest)
  end

  def assert_constants([actual | objects], [expected | rest]) do
    assert actual.value == expected
    assert_constants(objects, rest)
  end

  def compiler_test({input, expected_constants, expected_instructions}) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []

    {:ok, compiler} = Compiler.new() |> Compiler.compile(program)

    %Compiler.Bytecode{instructions: actual_instructions, constants: actual_constants} =
      compiler |> Compiler.bytecode()

    assert_instructions(actual_instructions, expected_instructions)
    assert_constants(actual_constants, expected_constants)
  end

  test "integer arithmetic" do
    [
      {"1 + 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:add, []),
         Opcode.make(:pop, [])
       ]},
      {"1 - 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:sub, []),
         Opcode.make(:pop, [])
       ]},
      {"1 * 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:mul, []),
         Opcode.make(:pop, [])
       ]},
      {"2 / 1;", [2, 1],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:div, []),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "boolean literals" do
    [
      {"true", [], [Opcode.make(true, []), Opcode.make(:pop, [])]},
      {"false", [], [Opcode.make(false, []), Opcode.make(:pop, [])]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "comparison operators" do
    [
      {"1 > 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:greater_than, []),
         Opcode.make(:pop, [])
       ]},
      {"1 < 2;", [2, 1],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:greater_than, []),
         Opcode.make(:pop, [])
       ]},
      {"1 == 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:equal, []),
         Opcode.make(:pop, [])
       ]},
      {"1 != 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:not_equal, []),
         Opcode.make(:pop, [])
       ]},
      {"true == true;", [],
       [
         Opcode.make(true, []),
         Opcode.make(true, []),
         Opcode.make(:equal, []),
         Opcode.make(:pop, [])
       ]},
      {"true != false;", [],
       [
         Opcode.make(true, []),
         Opcode.make(false, []),
         Opcode.make(:not_equal, []),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "prefix expressions" do
    [
      {"-5", [5],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:minus, []),
         Opcode.make(:pop, [])
       ]},
      {"!true", [],
       [
         Opcode.make(true, []),
         Opcode.make(:bang, []),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "if expressions" do
    [
      {"if (true) { 5 }; 500;", [5, 500],
       [
         Opcode.make(true, []),
         Opcode.make(:jump_not_truthy, [10]),
         Opcode.make(:constant, [0]),
         Opcode.make(:jump, [11]),
         Opcode.make(:null, []),
         Opcode.make(:pop, []),
         Opcode.make(:constant, [1]),
         Opcode.make(:pop, [])
       ]},
      {"if (true) { 5 } else { 300 }; 500;", [5, 300, 500],
       [
         Opcode.make(true, []),
         Opcode.make(:jump_not_truthy, [10]),
         Opcode.make(:constant, [0]),
         Opcode.make(:jump, [13]),
         Opcode.make(:constant, [1]),
         Opcode.make(:pop, []),
         Opcode.make(:constant, [2]),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "getting and setting globals" do
    [
      {"let one = 1; let two = 2;", [1, 2],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:set_global, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:set_global, [1])
       ]},
      {"let one = 1; one;", [1],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:set_global, [0]),
         Opcode.make(:get_global, [0]),
         Opcode.make(:pop, [])
       ]},
      {"let one = 1; let two = one; two;", [1],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:set_global, [0]),
         Opcode.make(:get_global, [0]),
         Opcode.make(:set_global, [1]),
         Opcode.make(:get_global, [1]),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "string literals" do
    [
      {~S("monkey"), ["monkey"],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:pop, [])
       ]},
      {~S("mon" + "key"), ["mon", "key"],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:add, []),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "array literals" do
    [
      {"[]", [],
       [
         Opcode.make(:array, [0]),
         Opcode.make(:pop, [])
       ]},
      {"[1,2,3]", [1, 2, 3],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:constant, [2]),
         Opcode.make(:array, [3]),
         Opcode.make(:pop, [])
       ]},
      {"[1 + 2, 3 - 4, 5 * 6]", [1, 2, 3, 4, 5, 6],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:add, []),
         Opcode.make(:constant, [2]),
         Opcode.make(:constant, [3]),
         Opcode.make(:sub, []),
         Opcode.make(:constant, [4]),
         Opcode.make(:constant, [5]),
         Opcode.make(:mul, []),
         Opcode.make(:array, [3]),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "dictionary literals" do
    [
      {"{}", [],
       [
         Opcode.make(:hash, [0]),
         Opcode.make(:pop, [])
       ]},
      {"{1 : 2, 3 : 4, 5 : 6}", [1, 2, 3, 4, 5, 6],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:constant, [2]),
         Opcode.make(:constant, [3]),
         Opcode.make(:constant, [4]),
         Opcode.make(:constant, [5]),
         Opcode.make(:hash, [6]),
         Opcode.make(:pop, [])
       ]},
      {"{1 : 2 + 3, 4 : 5 * 6}", [1, 2, 3, 4, 5, 6],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:constant, [2]),
         Opcode.make(:add, []),
         Opcode.make(:constant, [3]),
         Opcode.make(:constant, [4]),
         Opcode.make(:constant, [5]),
         Opcode.make(:mul, []),
         Opcode.make(:hash, [4]),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "index/access operator" do
    [
      {"[1,2,3][1 + 1]", [1, 2, 3, 1, 1],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:constant, [2]),
         Opcode.make(:array, [3]),
         Opcode.make(:constant, [3]),
         Opcode.make(:constant, [4]),
         Opcode.make(:add, []),
         Opcode.make(:index, []),
         Opcode.make(:pop, [])
       ]},
      {"{1 : 2}[2 - 1]", [1, 2, 2, 1],
       [
         Opcode.make(:constant, [0]),
         Opcode.make(:constant, [1]),
         Opcode.make(:hash, [2]),
         Opcode.make(:constant, [2]),
         Opcode.make(:constant, [3]),
         Opcode.make(:sub, []),
         Opcode.make(:index, []),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "function literal" do
    [
      {"fn() { return 5 + 10; }",
       [
         5,
         10,
         Instructions.merge([
           Opcode.make(:constant, [0]),
           Opcode.make(:constant, [1]),
           Opcode.make(:add, []),
           Opcode.make(:return_value, [])
         ])
       ],
       [
         Opcode.make(:constant, [2]),
         Opcode.make(:pop, [])
       ]},
      {"fn() { 1; 2 }",
       [
         1,
         2,
         Instructions.merge([
           Opcode.make(:constant, [0]),
           Opcode.make(:pop, []),
           Opcode.make(:constant, [1]),
           Opcode.make(:return_value, [])
         ])
       ],
       [
         Opcode.make(:constant, [2]),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "function calls" do
    [
      {"fn() { 24 }();",
       [
         24,
         Instructions.merge([
           Opcode.make(:constant, [0]),
           Opcode.make(:return_value, [])
         ])
       ],
       [
         Opcode.make(:constant, [1]),
         Opcode.make(:call, []),
         Opcode.make(:pop, [])
       ]},
      {"let noArg = fn() { 24 }; noArg();",
       [
         24,
         Instructions.merge([
           Opcode.make(:constant, [0]),
           Opcode.make(:return_value, [])
         ])
       ],
       [
         Opcode.make(:constant, [1]),
         Opcode.make(:set_global, [0]),
         Opcode.make(:get_global, [0]),
         Opcode.make(:call, []),
         Opcode.make(:pop, [])
       ]}
    ]
    |> Enum.map(&compiler_test/1)
  end

  test "compiler scopes" do
    c = Compiler.new()
    assert ArrayList.size(c.scopes) == 1

    {c, _} = Compiler.emit(c, :mul, [])
    c = Compiler.enter_scope(c)
    assert ArrayList.size(c.scopes) == 2

    {c, _} = Compiler.emit(c, :sub, [])
    {c, _} = Compiler.emit(c, :div, [])
    assert Compiler.instructions_length(c) == 2

    {c, _} = Compiler.leave_scope(c)

    {c, _} = Compiler.emit(c, :add, [])
    assert Compiler.instructions_length(c) == 2
  end
end
