defmodule Monkex.AST do
  defprotocol Statement do
    @spec token_literal(t) :: String.t()
    def token_literal(_)
  end

  defprotocol Expression do
    @spec token_literal(t) :: String.t()
    def token_literal(_)
  end

  defmodule Program do
    @enforce_keys [:statements]
    defstruct statements: []
    @type t :: %Program{statements: [Statement]}

    def token_literal(%Program{statements: statements}) do
      case hd(statements) do
        nil -> ""
        first -> Statement.token_literal(first)
      end
    end
  end

  defmodule LetStatement do
    @enforce_keys [:token, :name, :value]
    defstruct [:token, :name, :value]
  end

  defimpl Statement, for: LetStatement do
    def token_literal(%LetStatement{token: token}) do
      token.literal
    end
  end

  defmodule Identifier do
    @enforce_keys [:token, :symbol_name]
    defstruct [:token, :symbol_name]
  end

  defimpl Expression, for: Identifier do
    def token_literal(%Identifier{token: token}) do
      token.literal
    end
  end


end
