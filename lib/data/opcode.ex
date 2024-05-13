defmodule Monkex.Opcode do
  alias Monkex.Instructions

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
