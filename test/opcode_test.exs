defmodule OpcodeTest do
  alias Monkex.Instructions
  alias Monkex.Opcode, as: Code
  use ExUnit.Case, async: true

  test "instruction disassembled strings" do
    [
      {[
         Code.make(:constant, [1]),
         Code.make(:constant, [2]),
         Code.make(:constant, [65535])
       ],
       """
       0000 OpConstant 1
       0003 OpConstant 2
       0006 OpConstant 65535
       """},
      {
        [Code.make(:add, []), Code.make(:constant, [2]), Code.make(:constant, [65535])],
        """
        0000 OpAdd 
        0001 OpConstant 2
        0004 OpConstant 65535
        """
      }
    ]
    |> Enum.map(fn {actual, expected} ->
      concatted = Instructions.merge(actual)
      assert "#{concatted}" == expected
    end)
  end

  def assert_instruction(<<>>, <<>>), do: nil

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
      # {:add, [], <<2::8>>}
    ]
    |> Enum.map(fn {opcode, operands, expected} ->
      %Instructions{raw: instr} = Code.make(opcode, operands)
      assert byte_size(instr) == byte_size(expected)
      assert_instruction(instr, expected)
    end)
  end
end
