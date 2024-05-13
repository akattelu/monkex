defmodule Monkex.Instructions do
  alias __MODULE__
  alias Monkex.Opcode.Definition
  alias Monkex.Opcode.Bytes

  @moduledoc """
  A wrapper for working with a list of bytes
  This is what `Opcode.make` should return 
  Helps with disassembling bytes back to human readable opcodes and operands
  """

  @enforce_keys [:raw]
  defstruct [:raw]

  def new(), do: %Instructions{raw: <<>>}
  def from(bytes), do: %Instructions{raw: bytes}
  def raw(%Instructions{raw: raw}), do: raw
  def add(%Instructions{raw: raw}, next), do: (raw <> next) |> from

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
        with <<first::binary-size(1)-unit(8), rest::binary>> = bin,
             %Definition{name: name, operand_widths: widths} =
               Definition.lookup_from_code(first),
             offset_length = Enum.sum(widths) + 1,
             offset_string = offset |> Integer.to_string() |> String.pad_leading(4, "0"),
             {int, rest} = Bytes.from_big_binary(rest, widths) do
          {
            {offset + offset_length, "#{str}#{offset_string} #{name} #{Enum.join(int, " ")}\n"},
            rest
          }
        end
      end)
      # drop offset
      |> elem(1)
    end
  end
end
