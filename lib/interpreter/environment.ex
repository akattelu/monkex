defmodule Monkex.Environment do
  @moduledoc """
  Environment and scope representation for the Monkex interpreter
  Stores identifiers (keys) and objects (values)
  """

  alias __MODULE__
  alias Monkex.Object.Builtin

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

  def with_builtins(env) do
    Builtin.all()
    |> Enum.reduce(env, fn {name, builtin}, acc ->
      Environment.set(acc, name, builtin)
    end)
  end

  def merge(%Environment{store: base}, %Environment{store: other}) do
    Map.merge(base, other) |> from_store()
  end
end
