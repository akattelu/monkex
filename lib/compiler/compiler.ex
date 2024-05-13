defmodule Monkex.Compiler do
  alias __MODULE__
  alias Monkex.Instructions

  defmodule Bytecode do
    @enforce_keys [:instructions, :constants]
    defstruct [:instructions, :constants]
  end

  # instructions is a byte array
  # constants is a list of objects
  @enforce_keys [:instructions, :constants]
  defstruct [:instructions, :constants]

  def new() do
    %Compiler{
      instructions: Instructions.new,
      constants: []
    }
  end

  def compile(compiler, _node) do
    {:ok, compiler}
  end

  def bytecode(%Compiler{instructions: i, constants: c}) do
    %Bytecode{
      instructions: i,
      constants: c
    }
  end
end
