defmodule Monkex.VM.ArrayList do
  alias __MODULE__

  @moduledoc """
  Struct for holding constants and globals in the VM
  Uses a backing map for fast integer-index-based random access
  """

  @enforce_keys [:store, :num_items]
  defstruct [:store, :num_items]

  @type t() :: %ArrayList{}

  @spec new() :: t()
  def new(), do: %ArrayList{store: %{}, num_items: 0}

  @spec new([any()]) :: t()
  def new(list) do
    Enum.reduce(list, new(), fn x, acc -> push(acc, x) end)
  end

  @spec at(t(), integer()) :: {:ok, any()} | :undefined
  def at(%ArrayList{store: store}, idx) do
    case Map.fetch(store, idx) do
      :error -> :undefined
      item -> item
    end
  end

  @spec size(t()) :: integer()
  def size(%ArrayList{num_items: num}), do: num

  @spec push(t(), any()) :: t()
  def push(%ArrayList{store: store, num_items: num_items}, item) do
    %ArrayList{
      store: Map.put(store, num_items, item),
      num_items: num_items + 1
    }
  end
end
