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
  alias Monkex.Object.Builtin

  @type t() :: %SymbolTable{}

  @enforce_keys [:store, :num_defs, :outer]
  defstruct store: %{}, num_defs: 0, outer: nil

  @doc "Create an empty symbol table"
  @spec new() :: t()
  def new() do
    %SymbolTable{store: %{}, num_defs: 0, outer: nil}
  end

  @doc "Return a new symbol table with the identifier name in the store"
  @spec with_definition(t(), String.t()) :: t()
  def with_definition(%SymbolTable{store: store, num_defs: num_defs, outer: outer} = table, name) do
    %SymbolTable{
      table
      | num_defs: num_defs + 1,
        store:
          Map.put(store, name, %Symbol{
            name: name,
            index: num_defs,
            scope:
              if outer == nil do
                :global
              else
                :local
              end
          })
    }
  end

  @doc "Return a symbol table with all the builtin functions"
  @spec with_builtins() :: t()
  def with_builtins() do
    symbols =
      Builtin.all()
      |> Stream.with_index()
      |> Enum.reduce(%{}, fn {{name, _}, idx}, acc ->
        Map.put(acc, name, %Symbol{
          index: idx,
          name: name,
          scope: :builtin
        })
      end)

    %SymbolTable{
      store: symbols,
      outer: nil,
      # keep a separate index of num_defs for globals
      num_defs: 0
    }
  end

  @doc "Return the symbol associated with the name from the symbol table"
  @spec resolve(t(), String.t()) :: {:ok, Symbol.t()} | :undefined
  def resolve(%SymbolTable{store: store, outer: outer}, name) do
    with :error <- Map.fetch(store, name),
         %SymbolTable{} <- outer,
         :undefined <- resolve(outer, name) do
      :undefined
    else
      {:ok, sym} -> {:ok, sym}
      nil -> :undefined
    end
  end

  @doc "Create a new symbol table enclosing over a base table"
  @spec enclose(t()) :: t()
  def enclose(base) do
    %SymbolTable{
      new()
      | outer: base
    }
  end

  @doc "Return a symbol table's outer table reference"
  @spec unwrap(t()) :: t() | nil
  def unwrap(%SymbolTable{outer: outer}), do: outer

  @doc "Returns the number of definitions in the symbol table"
  @spec size(t()) :: integer()
  def size(%SymbolTable{num_defs: n}), do: n
end
