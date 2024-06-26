defmodule Monkex.Container.ArrayList do
  alias __MODULE__

  @moduledoc """
  Struct for holding constants and globals in the VM
  Uses a backing map for fast integer-index-based random access
  """

  @enforce_keys [:store, :num_slots]
  defstruct [:store, :num_slots]

  @type t() :: %ArrayList{}

  @doc "Create a new ArrayList"
  @spec new() :: t()
  def new(), do: %ArrayList{store: %{}, num_slots: 0}

  @doc "Create a new ArrayList from another list"
  @spec new([any()]) :: t()
  def new(list) do
    Enum.reduce(list, new(), fn x, acc -> push(acc, x) end)
  end

  @doc "Return the element in the ArrayList at the specified integer index"
  @spec at(t(), integer()) :: {:ok, any()} | :undefined
  def at(%ArrayList{store: store}, idx) do
    case Map.fetch(store, idx) do
      :error -> :undefined
      item -> item
    end
  end

  @doc "Return the last element in the ArrayList"
  @spec last(t()) :: {:ok, any()} | :undefined
  def last(%ArrayList{num_slots: num_slots} = arr) do
    at(arr, num_slots - 1)
  end

  @doc "Return the number of slots in the ArrayList"
  @spec size(t()) :: integer()
  def size(%ArrayList{num_slots: num}), do: num

  @doc "Append an element to the last slot in the ArrayList and return the new ArrayList"
  @spec push(t(), any()) :: t()
  def push(%ArrayList{store: store, num_slots: num_slots}, item) do
    %ArrayList{
      store: Map.put(store, num_slots, item),
      num_slots: num_slots + 1
    }
  end

  @doc "Set the value of the ArrayList at the specified index and create a new slot if it does not exist"
  @spec set(t(), integer(), any()) :: t()
  def set(%ArrayList{store: store, num_slots: num_slots}, idx, value) do
    new_size = Enum.max([num_slots, idx])

    %ArrayList{
      store: Map.put(store, idx, value),
      num_slots: new_size
    }
  end

  @doc "Overwrite the last element of the list"
  @spec set_last(t(), any()) :: t()
  def set_last(%ArrayList{num_slots: num_slots} = arr, item) do
    set(arr, num_slots - 1, item)
  end

  @doc "Remove the last element of the ArrayList and return the modified ArrayList and the item"
  @spec pop(t()) :: {t(), any()}
  def pop(%ArrayList{store: store, num_slots: num_slots} = arr) do
    {:ok, item} = last(arr)

    {
      %ArrayList{
        store: Map.delete(store, num_slots - 1),
        num_slots: num_slots - 1
      },
      item
    }
  end
end
