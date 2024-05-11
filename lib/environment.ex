defmodule Monkex.Environment do
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
    env
    |> Environment.set("len", %Builtin{
      param_count: 1,
      handler: &Builtin.len/1
    })
    |> Environment.set("puts", %Builtin{
      param_count: 1,
      handler: &Builtin.puts/1
    })
    |> Environment.set("charAt", %Builtin{
      param_count: 2,
      handler: &Builtin.char_at/1
    })
  end

  def merge(%Environment{store: base}, %Environment{store: other}) do
    Map.merge(base, other) |> from_store()
  end
end
