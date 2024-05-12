defmodule Monkex.AST do
  defprotocol Statement do
    @spec token_literal(t) :: String.t()
    def token_literal(_)
  end

  defprotocol Expression do
    @spec token_literal(t) :: String.t()
    def token_literal(_)
  end
end
