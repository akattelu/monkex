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
    [
      {"len", %Builtin{param_count: 1, handler: &Builtin.len/1}},
      {"head", %Builtin{param_count: 1, handler: &Builtin.head/1}},
      {"tail", %Builtin{param_count: 1, handler: &Builtin.tail/1}},
      {"last", %Builtin{param_count: 1, handler: &Builtin.last/1}},
      {"puts", %Builtin{param_count: 1, handler: &Builtin.puts/1}},
      {"charAt", %Builtin{param_count: 2, handler: &Builtin.char_at/1}},
      {"cons", %Builtin{param_count: 2, handler: &Builtin.cons/1}},
      {"push", %Builtin{param_count: 2, handler: &Builtin.push/1}},
      {"read", %Builtin{param_count: 1, handler: &Builtin.read/1}}
    ]
    |> Enum.reduce(env, fn {name, builtin}, acc ->
      Environment.set(acc, name, builtin)
    end)
  end

  def merge(%Environment{store: base}, %Environment{store: other}) do
    Map.merge(base, other) |> from_store()
  end
end
