defmodule Monkex.Compiler do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.Opcode
  alias Monkex.Instructions

  @moduledoc """
  MonkEx Compiler
  Walks AST and emits bytecode into struct `Instructions`
  """

  @type t :: %Compiler{}

  defmodule Bytecode do
    alias __MODULE__
    @enforce_keys [:instructions, :constants]
    defstruct [:instructions, :constants]

    @moduledoc """
    A intermediate in-memory representation of bytecode
    Contains a set of byte instructions with `Monkex.Instructions`
    Contains a list of constants as `Monkex.Object`s
    """

    @type t() :: %Bytecode{}
  end

  # instructions is a byte array
  # constants is a list of objects
  @enforce_keys [:instructions, :constants]
  defstruct [:instructions, :constants]

  @doc "Create a new empty Compiler struct"
  @spec new() :: t()
  def new() do
    %Compiler{
      instructions: Instructions.new(),
      constants: []
    }
  end

  @doc "Compile the AST starting at the provided node"
  @spec compile(t(), any()) :: {:ok, t()}
  def compile(compiler, node) do
    Node.compile(node, compiler)
  end

  @doc "Retrieve the bytecode from the current state of the Compiler"
  @spec bytecode(t()) :: Bytecode.t()
  def bytecode(%Compiler{instructions: i, constants: c}) do
    %Bytecode{
      instructions: i,
      constants: c
    }
  end

  @doc "Add a constant definition to the compiler state and return the new Compiler"
  @spec with_constant(t(), any()) :: {t(), integer()}
  def with_constant(%Compiler{constants: constants} = compiler, constant) do
    {%Compiler{
       compiler
       | constants: constants ++ [constant]
     }, length(constants)}
  end

  @doc "Add an instruction to the Compiler state and return the new Compiler"
  @spec with_instruction(t(), Instructions.t()) :: {t(), integer()}
  def with_instruction(%Compiler{instructions: instructions} = compiler, instruction) do
    {%Compiler{
       compiler
       | instructions: Instructions.concat(instruction, instructions)
     }, Instructions.length(instructions)}
  end

  @doc "Convert an opcode with operands into an instruction, add it to the Compiler, and return a new Compiler"
  @spec emit(t(), atom(), [integer()]) :: {t(), integer()}
  def emit(compiler, opcode, operands) do
    code = Opcode.make(opcode, operands)
    Compiler.with_instruction(compiler, code)
  end
end
