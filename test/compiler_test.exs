defmodule CompilerTest do
  alias Monkex.Parser
  alias Monkex.Compiler
  alias Monkex.Lexer
  alias Monkex.Opcode
  alias Monkex.Opcode.Instructions

  use ExUnit.Case, async: true

  def assert_instructions(actual, expected_list) do
    concatted = Enum.reduce(expected_list, Instructions.new(), &Instructions.concat/2)
    if concatted != actual do
      IO.puts("expected: #{concatted}, got: #{actual}")
      assert concatted == actual
    end
  end

  def assert_constants([], []), do: nil

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
      {"1 + 2", [1, 2], [Opcode.make(:constant, [1]), Opcode.make(:constant, [2])]}
    ]
    |> Enum.map(&compiler_test/1)
  end
end