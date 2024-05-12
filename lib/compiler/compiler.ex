defmodule Monkex.Compiler do
  alias __MODULE__

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
      instructions: <<>>,
      constants: []
    }
  end

  def compile(_compiler, _node) do
    nil
  end

  def bytecode(%Compiler{instructions: i, constants: c}) do
    %Bytecode{
      instructions: i,
      constants: c
    }
  end
end
