defmodule Monkex.Parser.Precedence do
  @precedence [:lowest, :equals, :lessgreater, :sum, :product, :prefix, :call]
  @token_to_precedence %{
    :eq => :equals,
    :not_eq => :equals,
    :lt => :lessgreater,
    :gt => :lessgreater,
    :plus => :sum,
    :minus => :sum,
    :slash => :product,
    :asterisk => :product,
    :lparen => :call
  }

  def of_token(tok) do
    Map.get(@token_to_precedence, tok, :lowest)
  end

  def compare(p1, p2) do 
    to_num = fn x -> Enum.find_index(@precedence, fn p -> p == x end) end
    to_num.(p1) - to_num.(p2)
  end
end
