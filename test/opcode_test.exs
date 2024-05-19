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
        [
          Code.make(:add, []),
          Code.make(:constant, [2]),
          Code.make(:constant, [65535]),
          Code.make(:sub, []),
          Code.make(:mul, []),
          Code.make(:div, [])
        ],
        """
        0000 OpAdd
        0001 OpConstant 2
        0004 OpConstant 65535
        0007 OpSub
        0008 OpMul
        0009 OpDiv
        """
      },
      {
        [Code.make(:pop, [])],
        """
        0000 OpPop
        """
      },
      {
        [Code.make(true, []), Code.make(false, [])],
        """
        0000 OpTrue
        0001 OpFalse
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
      {:constant, [65534], <<1::8, 255::8, 254::8>>},
      {:pop, [], <<2::8>>},
      {:add, [], <<3::8>>},
      {:sub, [], <<4::8>>},
      {:mul, [], <<5::8>>},
      {:div, [], <<6::8>>},
      {true, [], <<7::8>>},
      {false, [], <<8::8>>}
    ]
    |> Enum.map(fn {opcode, operands, expected} ->
      %Instructions{raw: instr} = Code.make(opcode, operands)
      assert byte_size(instr) == byte_size(expected)
      assert_instruction(instr, expected)
    end)
  end
end
