defmodule Monkex.Environment do
  alias __MODULE__

  defstruct store: %{}

  def new() do
    %Environment{}
  end

  def from_store(store) do
    %Environment{store: store}
  end

  def get(env, name) do
    case Map.fetch(env.store, name) do
      {:ok, obj} -> {:ok, obj}
      :error -> :undefined
    end
  end

  def set(env, key, value) do
    Map.put(env.store, key, value) |> from_store
  end
end
