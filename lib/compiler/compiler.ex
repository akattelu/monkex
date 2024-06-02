defmodule Monkex.Compiler do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.Opcode
  alias Monkex.Instructions
  alias Monkex.SymbolTable
  alias Monkex.Symbol
  alias Monkex.Container.ArrayList

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

  # constants is a list of objects
  # scopes is an arraylist of instructions
  @enforce_keys [:constants, :symbols, :scopes]
  defstruct [:constants, :symbols, :scopes]

  @doc "Create a new empty Compiler struct"
  @spec new() :: t()
  def new() do
    %Compiler{
      constants: [],
      symbols: SymbolTable.new(),
      scopes: ArrayList.new([Instructions.new()])
    }
  end

  @doc "Compile the AST starting at the provided node"
  @spec compile(t(), any()) :: {:ok, t()}
  def compile(compiler, node) do
    Node.compile(node, compiler)
  end

  @doc "Gets the instructions associated with the top scope in the compiler"
  @spec current_instructions(t()) :: Instructions.t()
  def current_instructions(%Compiler{scopes: scopes}) do
    {:ok, instructions} = ArrayList.last(scopes)
    instructions
  end

  @doc "Retrieve the bytecode from the current state of the Compiler"
  @spec bytecode(t()) :: Bytecode.t()
  def bytecode(%Compiler{constants: c} = compiler) do
    %Bytecode{
      instructions: current_instructions(compiler),
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
  def with_instruction(%Compiler{scopes: scopes} = compiler, instruction) do
    instructions = current_instructions(compiler)
    new_instructions = Instructions.concat(instruction, instructions)
    new_scopes = ArrayList.set_last(scopes, new_instructions)

    {%Compiler{
       compiler
       | scopes: new_scopes
     }, Instructions.length(instructions)}
  end

  @doc "Add a symbol into the compiler's symbol table and return the new compiler"
  @spec with_symbol_definition(t(), String.t()) :: t()
  def with_symbol_definition(%Compiler{symbols: symbols} = c, name) do
    %Compiler{
      c
      | symbols: symbols |> SymbolTable.with_definition(name)
    }
  end

  @spec get_symbol(t(), String.t()) :: {:ok, Symbol.t()} | :undefined
  def get_symbol(%Compiler{symbols: symbols}, name) do
    SymbolTable.resolve(symbols, name)
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
  def without_last_instruction(%Compiler{scopes: scopes} = c, opcode) do
    size = Opcode.Definition.oplength(opcode)
    new_scopes = ArrayList.set_last(scopes, c |> current_instructions |> Instructions.trim(size))
    %Compiler{c | scopes: new_scopes}
  end

  @doc "Check if the last emitted instruction is of the opcode type"
  @spec last_instruction_is?(t(), atom()) :: boolean()
  def last_instruction_is?(c, opcode) do
    size = Opcode.Definition.oplength(opcode)
    expected = Opcode.make(opcode, [])
    actual = c |> current_instructions |> Instructions.take_last(size)
    actual == expected
  end

  @doc "Return a compiler with instructions subsituted at the specified position"
  @spec with_replaced_instruction(t(), integer(), Instructions.t()) :: t()
  def with_replaced_instruction(%Compiler{scopes: scopes} = c, pos, sub) do
    instructions = current_instructions(c)
    new_scopes = ArrayList.set_last(scopes, Instructions.replace_at(instructions, pos, sub))

    %Compiler{c | scopes: new_scopes}
  end

  @doc "Remove the last pop instruction in the current scope and add a return instruction instead"
  @spec with_last_pop_as_return(t()) :: t()
  def with_last_pop_as_return(c) do
    if last_instruction_is?(c, :pop) do
      {c, _} = c |> without_last_instruction(:pop) |> emit(:return_value, [])
      c
    else
      c
    end
  end

  @doc """
  Track a new set of bytecode instructions on a stack of scopes
  Use `leave_scope` to return to the prior scope
  """
  @spec enter_scope(t()) :: t()
  def enter_scope(%Compiler{scopes: scopes, symbols: symbols} = c) do
    %Compiler{
      c
      | scopes: ArrayList.push(scopes, Instructions.new()),
        symbols: SymbolTable.enclose(symbols)
    }
  end

  @doc """
  End tracking of the current scope
  Return the bytecode instructions from the ended scope
  """
  @spec leave_scope(t()) :: {t(), Instructions.t()}
  def leave_scope(%Compiler{scopes: scopes, symbols: symbols} = c) do
    {new_scopes, instructions} = ArrayList.pop(scopes)

    {
      %Compiler{
        c
        | scopes: new_scopes,
          symbols: SymbolTable.unwrap(symbols)
      },
      instructions
    }
  end

  @doc "Retrieve the byte length of the instructions inside the compiler"
  @spec instructions_length(t()) :: integer()
  def instructions_length(c),
    do: c |> current_instructions |> Instructions.length()

  @doc "Return the number of symbols tracked by the most recently enclosed symbol table"
  @spec num_symbols(t()) :: integer()
  def num_symbols(%Compiler{symbols: symbols}), do: SymbolTable.size(symbols)
end
