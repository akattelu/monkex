defmodule Monkex.AST.Pair do
  alias __MODULE__

  @enforce_keys [:token, :key, :value]
  defstruct [:token, :key, :value]

  defimpl String.Chars, for: Pair do
    def to_string(%Pair{key: k, value: v}), do: "#{k}: #{v}"
  end
end

defmodule Monkex.AST.DictionaryLiteral do
  alias __MODULE__
  alias Monkex.Object.Node
  alias Monkex.AST.Expression
  alias Monkex.AST.Pair
  alias Monkex.Object.Dictionary

  @enforce_keys [:token, :pairs]
  defstruct [:token, :pairs]

  defimpl Expression, for: DictionaryLiteral do
    def token_literal(%DictionaryLiteral{token: token}), do: token.literal
  end

  defimpl String.Chars, for: DictionaryLiteral do
    def to_string(%DictionaryLiteral{pairs: []}), do: "{ }"

    def to_string(%DictionaryLiteral{pairs: pairs}) do
      "{ #{Enum.join(pairs, ",")} }"
    end
  end

  defimpl Node, for: DictionaryLiteral do
    alias Monkex.Object.Error
    alias Monkex.Object
    def compile(_node, compiler), do: compiler

    defp check_string(%Object.String{}), do: :ok
    defp check_string(other), do: {:error, "expected string as key, got #{Object.type(other)}"}

    defp error_check(%Error{message: msg}), do: {:error, msg}
    defp error_check(_), do: :ok

    def eval(%DictionaryLiteral{pairs: pairs}, env) do
      pair_reduce = fn %Pair{key: k, value: v}, acc ->
        with :ok <- error_check(acc),
             {key_val, _} <- Node.eval(k, env),
             :ok <- check_string(key_val),
             {val_obj, _} <- Node.eval(v, env),
             :ok <- error_check(val_obj) do
          Map.put(acc, key_val, val_obj)
        else
          {:error, msg} -> Error.with_message(msg)
        end
      end

      backing_map =
        pairs
        |> Enum.reduce(%{}, pair_reduce)

      case error_check(backing_map) do
        :ok ->
          {%Dictionary{
             map: backing_map
           }, env}

        {:error, msg} ->
          {Error.with_message(msg), env}
      end
    end
  end
end
