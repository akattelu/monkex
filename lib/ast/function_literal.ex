defmodule Monkex.AST.FunctionLiteral do
  @enforce_keys [:token, :name, :params, :body]
  defstruct [:token, :name, :params, :body]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.FunctionLiteral do
  def token_literal(%Monkex.AST.FunctionLiteral{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.FunctionLiteral do
  def to_string(%Monkex.AST.FunctionLiteral{
        token: token,
        name: name,
        params: params,
        body: body
      }) do
    "#{token.literal} #{name}(#{Enum.join(params,  " ")}) #{body}"
  end
end
