defmodule VMTest do
  alias Monkex.Lexer
  alias Monkex.Parser
  alias Monkex.Compiler
  alias Monkex.VM
  use ExUnit.Case, async: true

  def test_literal({actual, expected}) do
    assert actual.value == expected
  end

  def vm_test({input, expected}) do
    {parser, program} = input |> Lexer.new() |> Parser.new() |> Parser.parse_program()
    assert parser.errors == []
    {:ok, compiler} = Compiler.new() |> Compiler.compile(program)
    {:ok, final} = compiler |> Compiler.bytecode() |> VM.new() |> VM.run()
    test_literal({VM.stack_top(final), expected})
  end

  test "integer arithmetic" do
    [
      {"1", 1},
      {"2", 2},
      # FIXME
      {"1 + 2", 2}
    ]
    |> Enum.map(&vm_test/1)
  end
end
