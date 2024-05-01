defmodule Monkex.AST.FunctionLiteral do
  @enforce_keys [:token, :params, :body]
  defstruct [:token, :params, :body]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.FunctionLiteral do
  def token_literal(%Monkex.AST.FunctionLiteral{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.FunctionLiteral do
  def to_string(%Monkex.AST.FunctionLiteral{
        token: token,
        params: params,
        body: body
      }) do
    "#{token.literal} (#{Enum.join(params,  ", ")}) #{body}"
  end
end
