defmodule Monkex.Opcode do
  @doc """
  Helpers for converting to and from binaries
  """
  defmodule Bytes do
    def to_big_binary(operand, size), do: <<operand::big-integer-size(size)-unit(8)>>
  end

  defmodule Definition do
    @op_constant <<1>>

    @enforce_keys [:name, :operand_widths]
    defstruct name: nil, operand_widths: []

    def lookup(code) do
      # be explicit
      case Map.fetch(all(), code) do
        {:ok, def} -> {:ok, def}
        :error -> :undefined
      end
    end

    def all() do
      %{
        @op_constant => %Definition{name: "OpConstant", operand_widths: [2]}
      }
    end
  end

  def make(opcode, operands) do
    with {:ok, %Definition{operand_widths: widths}} <- Definition.lookup(opcode) do
      widths
      |> Enum.zip(operands)
      |> Enum.reduce(opcode, fn {width, operand}, acc ->
        acc <> Bytes.to_big_binary(operand, width)
      end)
    else
      :undefined -> <<>>
    end
  end
end
