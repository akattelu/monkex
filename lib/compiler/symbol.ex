defmodule Monkex.Symbol do
  @moduledoc """
  A reference to a symbol
  Holds idenitifer name, index referenced by opcodes, and scope
  """

  alias __MODULE__

  @enforce_keys [:name, :index, :scope]
  defstruct [:name, :index, :scope]

  @type t() :: %Symbol{}
end

defmodule Monkex.SymbolTable do
  @moduledoc "Struct for holding all symbols during a compilation"

  alias __MODULE__
  alias Monkex.Symbol

  @type t() :: %SymbolTable{}

  @enforce_keys [:store, :num_defs]
  defstruct store: %{}, num_defs: 0

  @doc "Create an empty symbol table"
  @spec new() :: t()
  def new() do
    %SymbolTable{store: %{}, num_defs: 0}
  end

  @doc "Return a new symbol table with the identifier name in the store"
  @spec with_definition(t(), String.t()) :: t()
  def with_definition(%SymbolTable{store: store, num_defs: num_defs}, name) do
    %SymbolTable{
      num_defs: num_defs + 1,
      store: Map.put(store, name, %Symbol{name: name, index: num_defs, scope: :global})
    }
  end

  @doc "Return the symbol associated with the name from the symbol table"
  @spec resolve(t(), String.t()) :: {:ok, Symbol.t()} | :undefined
  def resolve(%SymbolTable{store: store}, name) do
    case Map.fetch(store, name) do
      :error -> :undefined
      item -> item
    end
  end
end
