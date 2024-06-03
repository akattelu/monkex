defmodule Monkex.VM.InstructionSet do
  alias __MODULE__
  alias Monkex.Instructions
  alias Monkex.Object.{Closure, CompiledFunction}

  @moduledoc """
  Wrapper around a `Closure` of a `CompiledFunction`, which contains `Instructions`
  Preserves the initial set of `Instructions`
  Allows retrieving the head and tail of the instruction set
  Supports moving an instruction pointer for jump opcodes
  An InstructionSet is also used as a "stack frame"
  """

  @enforce_keys [:ip, :closure, :base_pointer]
  defstruct [:ip, :closure, :base_pointer]

  @type t() :: %InstructionSet{}

  @doc "Create a new instruction set from instructions"
  @spec new(Instructions.t(), integer()) :: t()
  def new(%Instructions{} = i, bp \\ 0) do
    func = CompiledFunction.from(i, 0, 0)
    closure = Closure.from(func)

    %InstructionSet{
      closure: closure,
      ip: 0,
      base_pointer: bp
    }
  end

  @doc "Retrieve the instructions from the instruction set"
  @spec instructions(t()) :: Instructions.t()
  def instructions(%InstructionSet{closure: %Closure{func: %CompiledFunction{instructions: i}}}),
    do: i

  @doc "Read n_bytes from the instructions at the instruction pointer"
  @spec read(t(), integer()) :: binary()
  def read(%InstructionSet{ip: ip} = iset, n_bytes \\ 1) do
    %Instructions{raw: raw} = instructions(iset)

    if ip + n_bytes > byte_size(raw) do
      <<>>
    else
      binary_part(raw, ip, n_bytes)
    end
  end

  @doc "Advance the instruction pointer by n bytes"
  @spec advance(t(), integer()) :: t()
  def advance(%InstructionSet{ip: ip} = i, n_bytes \\ 1) do
    %InstructionSet{
      i
      | ip: ip + n_bytes
    }
  end

  @doc "Advance the instruction pointer to pos"
  @spec jump(t(), integer()) :: t()
  def jump(set, pos) do
    %InstructionSet{
      set
      | ip: pos
    }
  end
end
