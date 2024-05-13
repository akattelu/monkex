defmodule Monkex.VM do
  alias Monkex.Instructions
  alias Monkex.Compiler.Bytecode
  alias __MODULE__

  @moduledoc """
  VM for running bytecode generated from compiler
  """
  @enforce_keys [:constants, :instructions, :stack]
  defstruct [:constants, :instructions, :stack]

  def new(%Bytecode{constants: constants, instructions: instructions}) do
    %VM{
      constants: constants,
      instructions: instructions,
      stack: []
    }
  end

  def stack_top(%VM{stack: [top | _]}), do: top
  def stack_top(%VM{stack: []}), do: nil

  def run(%VM{instructions: %Instructions{raw: raw}, stack: stack, constants: constants}) do
    {:ok, s, c} = run_raw(raw, stack, constants)

    {:ok,
     %VM{
       stack: s,
       constants: c,
       instructions: <<>>
     }}
  end

  def run_raw(<<>>, stack, constants), do: {:ok, stack, constants}

  def run_raw(<<first::binary-size(1)-unit(8), rest::binary>>, stack, constants) do
    case first do
      <<1::8>> ->
        <<int::big-integer-size(2)-unit(8), next::binary>> = rest
        # TODO: make this list access faster
        obj = Enum.at(constants, int)
        run_raw(next, [obj | stack], constants)
    end
  end
end
