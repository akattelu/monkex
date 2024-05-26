defmodule VMTest do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Compiler
  alias Monkex.Object.Null
  alias Monkex.VM
  use ExUnit.Case, async: true

  def test_literal({actual, expected}) do
    if expected == nil do
      assert actual == Null.object()
    else
      assert actual.value == expected
    end
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
    ] |> Enum.map(&vm_test/1)
  end
end
