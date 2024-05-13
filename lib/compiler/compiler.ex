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

  @doc "Create a new empty Compiler struct"
  def new() do
    %Compiler{
      instructions: Instructions.new(),
      constants: []
    }
  end

  @doc "Compile the AST starting at the provided node"
  def compile(compiler, node) do
    Node.compile(node, compiler)
  end

  @doc "Retrieve the bytecode from the current state of the Compiler"
  def bytecode(%Compiler{instructions: i, constants: c}) do
    %Bytecode{
      instructions: i,
      constants: c
    }
  end

  @doc "Add a constant definition to the compiler state and return the new Compiler"
  def with_constant(%Compiler{constants: constants} = compiler, constant) do
    {%Compiler{
       compiler
       | constants: constants ++ [constant]
     }, length(constants)}
  end

  @doc "Add an instruction to the Compiler state and return the new Compiler"
  def with_instruction(%Compiler{instructions: instructions} = compiler, instruction) do
    {%Compiler{
       compiler
       | instructions: Instructions.concat(instruction, instructions)
     }, Instructions.length(instructions)}
  end

  @doc "Convert an opcode with operands into an instruction, add it to the Compiler, and return a new Compiler"
  def emit(compiler, opcode, operands) do
    code = Opcode.make(opcode, operands)
    Compiler.with_instruction(compiler, code)
  end
end
