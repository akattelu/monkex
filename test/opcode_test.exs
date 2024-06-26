defmodule OpcodeTest do
  alias Monkex.Instructions
  alias Monkex.Opcode, as: Code
  use ExUnit.Case, async: true

  test "instruction disassembled strings" do
    [
      {[
         Code.make(:constant, [1]),
         Code.make(:constant, [2]),
         Code.make(:constant, [65_535])
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
          Code.make(:constant, [65_535]),
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
        [Code.make(:equal, []), Code.make(:not_equal, []), Code.make(:greater_than, [])],
        """
        0000 OpEqual
        0001 OpNotEqual
        0002 OpGreaterThan
        """
      },
      {
        [Code.make(true, []), Code.make(false, [])],
        """
        0000 OpTrue
        0001 OpFalse
        """
      },
      {
        [Code.make(:minus, []), Code.make(:bang, [])],
        """
        0000 OpMinus
        0001 OpBang
        """
      },
      {
        [Code.make(:jump_not_truthy, [100]), Code.make(:jump, [100]), Code.make(:pop, [])],
        """
        0000 OpJumpNotTruthy 100
        0003 OpJump 100
        0006 OpPop
        """
      },
      {
        [
          Code.make(:add, []),
          Code.make(:get_local, [1]),
          Code.make(:constant, [2]),
          Code.make(:constant, [255]),
          Code.make(:call, [3]),
          Code.make(:closure, [65_534, 255]),
          Code.make(:add, [])
        ],
        """
        0000 OpAdd
        0001 OpGetLocal 1
        0003 OpConstant 2
        0006 OpConstant 255
        0009 OpCall 3
        0011 OpClosure 65534 255
        0015 OpAdd
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
      {:constant, [65_534], <<1::8, 255::8, 254::8>>},
      {:pop, [], <<2::8>>},
      {:add, [], <<3::8>>},
      {:sub, [], <<4::8>>},
      {:mul, [], <<5::8>>},
      {:div, [], <<6::8>>},
      {true, [], <<7::8>>},
      {false, [], <<8::8>>},
      {:equal, [], <<9::8>>},
      {:not_equal, [], <<10::8>>},
      {:greater_than, [], <<11::8>>},
      {:minus, [], <<12::8>>},
      {:bang, [], <<13::8>>},
      {:jump_not_truthy, [65_534], <<14::8, 255::8, 254::8>>},
      {:jump, [65_534], <<15::8, 255::8, 254::8>>},
      {:null, [], <<16::8>>},
      {:set_global, [65_534], <<17::8, 255::8, 254::8>>},
      {:get_global, [65_534], <<18::8, 255::8, 254::8>>},
      {:array, [65_534], <<19::8, 255::8, 254::8>>},
      {:hash, [65_534], <<20::8, 255::8, 254::8>>},
      {:index, [], <<21::8>>},
      {:call, [255], <<22::8, 255::8>>},
      {:return_value, [], <<23::8>>},
      {:return, [], <<24::8>>},
      {:set_local, [255], <<25::8, 255::8>>},
      {:get_local, [255], <<26::8, 255::8>>},
      {:get_builtin, [255], <<27::8, 255::8>>},
      {:closure, [65_534, 255], <<28::8, 255::8, 254::8, 255::8>>},
      {:get_free, [255], <<29::8, 255::8>>},
      {:current_closure, [], <<30::8>>}
    ]
    |> Enum.map(fn {opcode, operands, expected} ->
      %Instructions{raw: instr} = Code.make(opcode, operands)
      assert byte_size(instr) == byte_size(expected)
      assert_instruction(instr, expected)
    end)
  end
end
