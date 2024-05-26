defmodule Monkex.VM.Stack do
  alias __MODULE__

  @moduledoc """
  Custom implementation of the VMs stack
  Uses a backing map instead of a list for constant time operations
  Also does not delete keys of elements that are popped, instead uses a stack pointer to keep track of the top
  """

  @enforce_keys [:store, :sp]
  defstruct [:store, :sp]

  @type t() :: %Stack{}

  @spec new() :: t()
  # start at -1 so pushing points to a valid element
  def new(), do: %Stack{store: %{}, sp: -1}

  @spec top(t()) :: any()
  def top(%Stack{store: store, sp: sp}), do: Map.get(store, sp, nil)

  @spec push(t(), any()) :: t()
  def push(%Stack{store: store, sp: sp}, obj) do
    %Stack{
      store: Map.put(store, sp + 1, obj),
      sp: sp + 1
    }
  end

  @spec pop(t()) :: {t(), any()}
  def pop(%Stack{sp: -1} = s), do: {s, nil}

  def pop(%Stack{store: store, sp: sp}) do
    {
      %Stack{store: store, sp: sp - 1},
      Map.get(store, sp, nil)
    }
  end

  @spec last_popped(t()) :: any()
  def last_popped(%Stack{store: store, sp: sp}) do
    Map.get(store, sp + 1, nil)
  end

  @doc "Take n elements from the top of the stack in reverse-order"
  @spec take(Stack.t(), integer()) :: {t(), [any()]}
  def take(stack, 0), do: {stack, []}

  def take(stack, n) do
    Enum.reduce(1..n, {stack, []}, fn _, {acc_stack, acc_arr} ->
      {s, item} = Stack.pop(acc_stack)
      {s, [item | acc_arr]}
    end)
  end
end
