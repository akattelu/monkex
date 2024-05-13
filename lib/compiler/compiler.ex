defmodule Monkex.Compiler do
  alias Monkex.Object.Node
  alias Monkex.Opcode
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
      instructions: Instructions.new(),
      constants: []
    }
  end

  def compile(compiler, node) do
    Node.compile(node, compiler)
  end

  def bytecode(%Compiler{instructions: i, constants: c}) do
    %Bytecode{
      instructions: i,
      constants: c
    }
  end

  def with_constant(%Compiler{constants: constants} = compiler, constant) do
    {%Compiler{
       compiler
       | constants: constants ++ [constant]
     }, length(constants)}
  end

  def with_instruction(%Compiler{instructions: instructions} = compiler, instruction) do
    {%Compiler{
       compiler
       | instructions: Instructions.concat(instruction, instructions) 
     }, Instructions.length(instructions)}
  end

  def emit(compiler, opcode, operands) do
    code = Opcode.make(opcode, operands)
    Compiler.with_instruction(compiler, code)
  end
end
