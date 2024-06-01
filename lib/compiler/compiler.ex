defmodule Monkex.Compiler do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.Opcode
  alias Monkex.Instructions
  alias Monkex.SymbolTable
  alias Monkex.Symbol

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
  @enforce_keys [:instructions, :constants, :symbols, :scopes]
  defstruct [:instructions, :constants, :symbols, :scopes]

  @doc "Create a new empty Compiler struct"
  @spec new() :: t()
  def new() do
    %Compiler{
      instructions: Instructions.new(),
      constants: [],
      symbols: SymbolTable.new(),
      scopes: []
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

  @doc "Add an instruction to the Compiler state and return the new Compiler with the total length"
  @spec with_instruction(t(), Instructions.t()) :: {t(), integer()}
  def with_instruction(%Compiler{instructions: instructions} = compiler, instruction) do
    {%Compiler{
       compiler
       | instructions: Instructions.concat(instruction, instructions)
     }, Instructions.length(instructions)}
  end

  @doc "Add a symbol into the compiler's symbol table and return the new compiler"
  @spec with_global_symbol(t(), String.t()) :: t()
  def with_global_symbol(%Compiler{symbols: symbols} = c, name) do
    %Compiler{
      c
      | symbols: symbols |> SymbolTable.with_definition(name)
    }
  end

  @spec get_symbol_index(t(), String.t()) :: integer() | :undefined
  def get_symbol_index(%Compiler{symbols: symbols}, name) do
    with {:ok, %Symbol{index: idx}} <- SymbolTable.resolve(symbols, name) do
      {:ok, idx}
    end
  end

  @doc "Convert an opcode with operands into an instruction, add it to the Compiler, and return a new Compiler"
  @spec emit(t(), atom(), [integer()]) :: {t(), integer()}
  def emit(compiler, opcode, operands) do
    code = Opcode.make(opcode, operands)
    Compiler.with_instruction(compiler, code)
  end

  @doc """
  Remove the latest instruction that was emitted from the compiler
  Uses the type passed in to determine the length of the instruction to be trimmed
  """
  @spec without_last_instruction(t(), atom()) :: t()
  def without_last_instruction(%Compiler{instructions: instructions} = c, opcode) do
    size = Opcode.Definition.oplength(opcode)
    %Compiler{c | instructions: Instructions.trim(instructions, size)}
  end

  @doc "Return a compiler with instructions subsituted at the specified position"
  @spec with_replaced_instruction(t(), integer(), Instructions.t()) :: t()
  def with_replaced_instruction(%Compiler{instructions: instr} = c, pos, sub) do
    %Compiler{
      c
      | instructions: Instructions.replace_at(instr, pos, sub)
    }
  end


  @doc """
  Track a new set of bytecode instructions on a stack of scopes
  Use `leave_scope` to return to the prior scope
  """
  @spec enter_scope(t()) :: t()
  def enter_scope(c) do
    c
  end

  @doc """
  End tracking of the current scope
  Return the bytecode instructions from the ended scope
  """
  @spec leave_scope(t()) :: {t(), Instructions.t()}
  def leave_scope(c) do
    {c, nil}
  end

  @doc "Retrieve the byte length of the instructions inside the compiler"
  @spec instructions_length(t()) :: integer()
  def instructions_length(%Compiler{instructions: instructions}),
    do: Instructions.length(instructions)
end
