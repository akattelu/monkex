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

  @enforce_keys [:store, :num_defs, :outer, :free_symbols]
  defstruct store: %{}, num_defs: 0, outer: nil, free_symbols: []

  @doc "Create an empty symbol table"
  @spec new() :: t()
  def new() do
    %SymbolTable{store: %{}, num_defs: 0, outer: nil, free_symbols: []}
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
      new()
      | store: symbols,
        # keep a separate index of num_defs for globals
        num_defs: 0
    }
  end

  @doc "Return the symbol associated with the name from the symbol table"
  @spec resolve(t(), String.t()) :: {:ok, t(), Symbol.t()} | :undefined
  def resolve(%SymbolTable{store: store, outer: outer} = table, name) do
    with :error <- Map.fetch(store, name),
         %SymbolTable{} <- outer,
         :undefined <- resolve(outer, name) do
      :undefined
    else
      {:ok, %Symbol{} = sym} ->
        {:ok, table, sym}

      {:ok, t, %Symbol{scope: :global} = sym} ->
        {:ok, %SymbolTable{table | outer: t}, sym}

      {:ok, t, %Symbol{scope: :builtin} = sym} ->
        {:ok, %SymbolTable{table | outer: t}, sym}

      {:ok, out, %Symbol{} = sym} ->
        {t, sym} = with_free_definition(table, sym)
        {:ok, %SymbolTable{t | outer: out}, sym}

      nil ->
        :undefined
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

  @doc "Returns the free symbols tracked by the symbol table"
  @spec get_free_symbols(t()) :: [Symbol.t()]
  def get_free_symbols(%SymbolTable{free_symbols: free_symbols}), do: free_symbols

  @doc "Return a new symbol table with the symbol added as a free variable"
  @spec with_free_definition(t(), Symbol.t()) :: {t(), Symbol.t()}
  def with_free_definition(
        %SymbolTable{store: store, free_symbols: free_symbols} = table,
        %Symbol{name: name} = original
      ) do
    sym = %Symbol{name: name, index: length(free_symbols), scope: :free}

    {
      %SymbolTable{
        table
        | free_symbols: free_symbols ++ [original],
          store: Map.put(store, name, sym)
      },
      sym
    }
  end
end
