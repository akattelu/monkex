defmodule Monkex.AST.CallExpression do
  @enforce_keys [:token, :function, :arguments]
  defstruct [:token, :function, :arguments]
end

defimpl Monkex.AST.Expression, for: Monkex.AST.CallExpression do
  def token_literal(%Monkex.AST.CallExpression{token: token}) do
    token.literal
  end
end

defimpl String.Chars, for: Monkex.AST.CallExpression do
  def to_string(%Monkex.AST.CallExpression{
        token: token,
        function: function,
        arguments: arguments
      }) do
        "#{function}#{token.literal}#{Enum.join(arguments, ", ")})}"
  end
end
