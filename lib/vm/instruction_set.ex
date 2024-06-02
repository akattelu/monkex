defmodule Monkex.VM.InstructionSet do
  alias __MODULE__
  alias Monkex.Instructions

  @moduledoc """
  Wrapper around `Instructions` that preserves the initial set of instructions
  Allows retrieving the head and tail of the instruction set
  Supports moving an instruction pointer for jump opcodes
  An InstructionSet is also used as a "stack frame"
  """

  @enforce_keys [:ip, :instructions, :base_pointer]
  defstruct [:ip, :instructions, :base_pointer]

  @type t() :: %InstructionSet{}

  @doc "Create a new instruction set from instructions"
  @spec new(Instructions.t(), integer()) :: t()
  def new(%Instructions{} = i, bp \\ 0) do
    %InstructionSet{
      instructions: i,
      ip: 0,
      base_pointer: bp
    }
  end

  @doc "Read n_bytes from the instructions at the instruction pointer"
  @spec read(t(), integer()) :: binary()
  def read(%InstructionSet{instructions: %Instructions{raw: raw}, ip: ip}, n_bytes \\ 1) do
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
