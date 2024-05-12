defmodule BytecodeTest do
  alias Monkex.Bytecode, as: Code
  use ExUnit.Case, async: true

  @op_constant <<1::8>>

  def assert_instruction(<<instr_head::binary-size(1), instr_rest::binary>>, <<expected_head::binary-size(1), expected_rest::binary>>) do
    assert instr_head == expected_head
    assert_instruction(instr_rest, expected_rest)
  end

  test "make" do
    [
      {@op_constant, [65534], <<1::8, 255::8, 254::8>>}
    ]
    |> Enum.map(fn {opcode, operands, expected}->
      instr = Code.make(opcode, operands)
      assert byte_size(instr) == byte_size(expected)
    end)
  end
end
