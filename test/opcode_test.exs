defmodule OpcodeTest do
  alias Monkex.Opcode.Instructions
  alias Monkex.Opcode, as: Code
  use ExUnit.Case, async: true

  test "instruction disassembled strings" do
    actual = [
      Code.make(:constant, [1]),
      Code.make(:constant, [2]),
      Code.make(:constant, [65535])
    ]

    expected = """
    0000 OpConstant 1
    0003 OpConstant 2
    0006 OpConstant 65535
    """

    concatted = Enum.reduce(actual, Instructions.new(), &Instructions.concat/2)
    assert "#{concatted}" == expected
  end

  def assert_instruction(
        <<instr_head::binary-size(1), instr_rest::binary>>,
        <<expected_head::binary-size(1), expected_rest::binary>>
      ) do
    assert instr_head == expected_head
    assert_instruction(instr_rest, expected_rest)
  end

  test "make" do
    [
      {:constant, [65534], <<1::8, 255::8, 254::8>>}
    ]
    |> Enum.map(fn {opcode, operands, expected} ->
      instr = Code.make(opcode, operands) |> Code.Instructions.raw()
      assert byte_size(instr) == byte_size(expected)
    end)
  end
end