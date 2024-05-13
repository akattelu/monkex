defmodule Monkex.Opcode do
  defmodule Bytes do
    @moduledoc """
    Helpers for working with bytes and packing
    """
    def to_big_binary(operand, size), do: <<operand::big-integer-size(size)-unit(8)>>
    def from_big_binary(<<>>, _), do: []
    def from_big_binary(_, []), do: []

    def from_big_binary(<<int::big-integer-size(2)-unit(8), rest::binary>>, [2 | widths]) do
      {[int | from_big_binary(rest, widths)], rest}
    end
  end

  defmodule Definition do
    @enforce_keys [:name, :opcode, :operand_widths]
    defstruct name: nil, opcode: <<>>, operand_widths: []

    def lookup(code) do
      # be explicit
      case Map.fetch(all(), code) do
        {:ok, def} -> {:ok, def}
        :error -> :undefined
      end
    end

    def lookup_from_code(byte) do
      all() |> Map.values() |> Enum.find(:undefined, fn def -> def.opcode == byte end)
    end

    def opcode(op) do
      case lookup(op) do
        {:ok, %Definition{opcode: code}} -> code
        :undefined -> :undefined
      end
    end

    def all() do
      %{
        :constant => %Definition{name: "OpConstant", opcode: <<1::8>>, operand_widths: [2]}
      }
    end
  end

  defmodule Instructions do
    @moduledoc """
    A wrapper for working with a list of bytes
    This is what the `make` function of `Opcode` should return 
    Helps with disassembling bytes back to human readable opcodes and operands
    """

    @enforce_keys [:raw]
    defstruct [:raw]

    def new(), do: %Instructions{raw: <<>>}
    def from(bytes), do: %Instructions{raw: bytes}
    def raw(%Instructions{raw: raw}), do: raw

    def concat(%Instructions{raw: first}, %Instructions{raw: second}),
      do: (second <> first) |> from

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

  @doc "make a packed binary for a given opcode and operands"
  def make(opcode, operands) do
    with {:ok, %Definition{opcode: code, operand_widths: widths}} <- Definition.lookup(opcode) do
      widths
      |> Enum.zip(operands)
      |> Enum.reduce(code, fn {width, operand}, acc ->
        acc <> Bytes.to_big_binary(operand, width)
      end)
    else
      :undefined -> <<>>
    end
    |> Instructions.from()
  end
end
