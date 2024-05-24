defmodule Monkex.Instructions do
  alias __MODULE__
  alias Monkex.Opcode.Definition
  alias Monkex.Opcode.Bytes

  @moduledoc """
  A wrapper for working with a list of bytes
  This is what `Opcode.make` should return 
  Helps with disassembling bytes back to human readable opcodes and operands
  """

  @type t() :: %Instructions{}

  @enforce_keys [:raw]
  defstruct [:raw]

  def new(), do: %Instructions{raw: <<>>}
  def from(bytes), do: %Instructions{raw: bytes}
  def raw(%Instructions{raw: raw}), do: raw
  def add(%Instructions{raw: raw}, next), do: (raw <> next) |> from

  @doc "trim the trailing n bytes from the end of the instructions list"
  @spec trim(t(), integer()) :: t()
  def trim(%Instructions{raw: raw}, n) do
    binary_length = byte_size(raw)
    new_length = binary_length - n
    raw |> binary_part(0, new_length) |> from
  end

  @doc "Replace the portion of the instruction at position, with the next instruction"
  @spec replace_at(t(), integer(), t()) :: t()
  def replace_at(%Instructions{raw: base}, position, %Instructions{raw: sub}) do
    first = binary_part(base, 0, position)
    second = sub
    length_until_sub = byte_size(first) + byte_size(second)
    third = binary_part(base, length_until_sub, byte_size(base) - length_until_sub)
    (first <> second <> third) |> from
  end

  def concat(%Instructions{raw: first}, %Instructions{raw: second}),
    do: (second <> first) |> from

  def merge(raw_list) do
    Enum.reduce(raw_list, Instructions.new(), &Instructions.concat/2)
  end

  def length(%Instructions{raw: raw}), do: byte_size(raw)

  defimpl String.Chars, for: Instructions do
    defp reduce(<<>>, acc, _), do: acc

    defp reduce(b, initial, reducer) do
      {val, rest} = reducer.(b, initial)
      reduce(rest, val, reducer)
    end

    def to_string(%Instructions{raw: ""}), do: ""

    def to_string(%Instructions{raw: raw}) do
      raw
      |> reduce({0, ""}, fn bin, {offset, str} ->
        <<first::binary-size(1)-unit(8), rest::binary>> = bin

        %Definition{name: name, operand_widths: widths} =
          Definition.lookup_from_code(first)

        offset_length = Enum.sum(widths) + 1
        offset_string = offset |> Integer.to_string() |> String.pad_leading(4, "0")
        {int, rest} = Bytes.from_big_binary(rest, widths)

        if length(int) > 0 do
          {{offset + offset_length, "#{str}#{offset_string} #{name} #{Enum.join(int, " ")}\n"},
           rest}
        else
          {{offset + offset_length, "#{str}#{offset_string} #{name}\n"}, rest}
        end
      end)
      # drop offset
      |> elem(1)
    end
  end
end
