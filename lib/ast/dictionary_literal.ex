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
  alias Monkex.AST.Expression

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
end
